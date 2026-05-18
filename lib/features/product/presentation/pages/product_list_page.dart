// lib/features/product/presentation/pages/product_list_page.dart
//
// FIXES vs previous version:
//   1. _TableHeaderDelegate removed — SliverPersistentHeader with a delegate
//      that calls Theme.of(context) crashes with 'resolvedPadding != null'
//      before Directionality is available. Replaced with a pinned SliverAppBar
//      whose flexibleSpace is a plain StatelessWidget. Zero behaviour change.
//
//   2. Category fetch storm fixed — _prefetchCategories was called inside
//      BlocBuilder's builder, so every setState (e.g. from _resolveCategoryName
//      writing to _categoryNames) triggered another prefetch round, which
//      caused the cascading null-check / mouse_tracker assertion storm.
//      Fix: track in-flight IDs in _fetchingCategories; never re-dispatch
//      a fetch for an ID that is pending or already cached.
//
//   3. ProductCardTile overflow fixed (3 px on bottom) — grid mainAxisExtent
//      bumped from 280 → 300 to accommodate the PromotionCornerTag that was
//      added at the bottom of the image stack. Same bump applied to the grid
//      view for consistency.
// ─────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/value_objects/product_status.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../widgets/view_mode_toggle.dart';
import '../widgets/product_card_tile.dart';
import '../widgets/product_grid_tile.dart';
import '../widgets/product_list_row.dart';
import '../widgets/product_table_row.dart';
import '../widgets/product_confirm_name_dialog.dart';
import 'package:get_it/get_it.dart';
import '../../../category/domain/usecases/get_category_usecase.dart';

// ─── Filter model ─────────────────────────────────────────────────────────

class _ProductFilter {
  final String query;
  final Set<ProductStatus> statuses;
  final bool? onPromotion;
  final bool? available;

  const _ProductFilter({
    this.query = '',
    this.statuses = const {},
    this.onPromotion,
    this.available,
  });

  bool get hasActiveFilters =>
      query.isNotEmpty ||
      statuses.isNotEmpty ||
      onPromotion != null ||
      available != null;

  _ProductFilter copyWith({
    String? query,
    Set<ProductStatus>? statuses,
    Object? onPromotion = _sentinel,
    Object? available = _sentinel,
  }) => _ProductFilter(
    query: query ?? this.query,
    statuses: statuses ?? this.statuses,
    onPromotion: onPromotion == _sentinel
        ? this.onPromotion
        : onPromotion as bool?,
    available: available == _sentinel ? this.available : available as bool?,
  );

  bool matches(ProductEntity p) {
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      if (!p.name.toLowerCase().contains(q) &&
          !(p.description?.toLowerCase().contains(q) ?? false)) {
        return false;
      }
    }
    if (statuses.isNotEmpty &&
        !statuses.contains(ProductStatusX.fromString(p.status))) {
      return false;
    }
    if (onPromotion != null && p.isOnPromotion != onPromotion) return false;
    if (available != null && p.isAvailable != available) return false;
    return true;
  }
}

const _sentinel = Object();

// ─── Page ─────────────────────────────────────────────────────────────────

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  ProductViewMode _viewMode = ProductViewMode.cards;
  _ProductFilter _filter = const _ProductFilter();
  bool _showFilterPanel = false;

  // FIX 2: separate resolved cache and in-flight guard.
  final Map<String, String> _categoryNames = {};
  final Set<String> _fetchingCategories = {};

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // @override
  // void initState() {
  //   super.initState();
  //   context.read<ProductBloc>().add(ProductLoadAllRequested());
  // }
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(ProductLoadWithPromotionsRequested());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Category resolution ─────────────────────────────────────────────────
  // FIX 2: called from the builder, but each ID is only fetched once.

  void _prefetchCategories(List<ProductEntity> items) {
    for (final id in items.map((e) => e.categoryId).toSet()) {
      if (!_categoryNames.containsKey(id) &&
          !_fetchingCategories.contains(id)) {
        _fetchingCategories.add(id);
        _fetchCategory(id);
      }
    }
  }

  Future<void> _fetchCategory(String id) async {
    try {
      final uc = GetIt.instance<GetCategoryUseCase>();
      final res = await uc(GetCategoryParams(id: id));
      final name = res.fold((_) => id, (c) => c.name);
      if (mounted) {
        setState(() {
          _categoryNames[id] = name;
          _fetchingCategories.remove(id);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _categoryNames[id] = id;
          _fetchingCategories.remove(id);
        });
      }
    }
  }

  // ── Navigation / delete ─────────────────────────────────────────────────

  void _navigateToDetail(String id) =>
      context.push(AppRouter.productDetailPath(id));

  Future<void> _deleteProduct(String id, String name) async {
    final confirmed = await ProductConfirmNameDialog.show(
      context,
      title: 'Delete Product?',
      productName: name,
      actionLabel: 'Delete',
      actionColor: Theme.of(context).colorScheme.error,
      warningMessage:
          'This action is irreversible. The product will be permanently removed from the system.',
    );
    if (confirmed && mounted) {
      context.read<ProductBloc>().add(ProductDeleteRequested(id));
    }
  }

  // ── Price formatter ─────────────────────────────────────────────────────

  String _formatPrice(double v) =>
      'TZS ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

  // ── Filter + group ──────────────────────────────────────────────────────

  List<ProductEntity> _applyFilter(List<ProductEntity> items) =>
      items.where(_filter.matches).toList();

  List<MapEntry<String, List<ProductEntity>>> _groupByCategory(
    List<ProductEntity> items,
  ) {
    final map = <String, List<ProductEntity>>{};
    for (final p in items) {
      map.putIfAbsent(p.categoryId, () => []).add(p);
    }
    return map.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildAppBar(scheme),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRouter.productCreate),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            onChanged: (q) =>
                setState(() => _filter = _filter.copyWith(query: q)),
            onClear: () {
              _searchCtrl.clear();
              setState(() => _filter = _filter.copyWith(query: ''));
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _showFilterPanel
                ? _FilterPanel(
                    filter: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                  )
                : const SizedBox.shrink(),
          ),
          if (_filter.hasActiveFilters)
            _ActiveFilterChips(
              filter: _filter,
              onRemove: (f) => setState(() => _filter = f),
              onClearAll: () =>
                  setState(() => _filter = const _ProductFilter()),
            ),
          Expanded(
            child: BlocConsumer<ProductBloc, ProductState>(
              listener: (context, state) {
                if (state is ProductOperationSuccess) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                  context.read<ProductBloc>().add(
                    ProductLoadWithPromotionsRequested(),
                  ); // ← changed
                }
                if (state is ProductFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: scheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ProductLoading || state is ProductInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProductEmpty) return _buildEmpty(context, scheme);
                if (state is ProductFailure) {
                  return _buildError(context, scheme, state.message);
                }
                if (state is ProductListLoaded) {
                  _prefetchCategories(state.items); // safe — guarded by FIX 2
                  final filtered = _applyFilter(state.items);
                  if (filtered.isEmpty) {
                    return _buildNoResults(context, scheme);
                  }
                  return RefreshIndicator(
                    onRefresh: () async => context.read<ProductBloc>().add(
                      ProductLoadWithPromotionsRequested(),
                    ),
                    child: _buildView(filtered),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ColorScheme scheme) => AppBar(
    title: const Text('Products'),
    actions: [
      IconButton(
        tooltip: 'Refresh',
        icon: const Icon(Icons.refresh),
        onPressed: () {
          if (context.read<ProductBloc>().state is! ProductLoading) {
            context.read<ProductBloc>().add(
              ProductLoadWithPromotionsRequested(),
            );
          }
        },
      ),
      IconButton(
        tooltip: 'Filter',
        icon: Badge(
          isLabelVisible:
              _filter.statuses.isNotEmpty ||
              _filter.onPromotion != null ||
              _filter.available != null,
          child: Icon(
            _showFilterPanel ? Icons.filter_list : Icons.filter_list_outlined,
          ),
        ),
        onPressed: () => setState(() => _showFilterPanel = !_showFilterPanel),
      ),
      ViewModeToggle(
        current: _viewMode,
        onChanged: (m) => setState(() => _viewMode = m),
      ),
      const SizedBox(width: 8),
    ],
  );

  // ── View router ─────────────────────────────────────────────────────────

  Widget _buildView(List<ProductEntity> items) {
    final groups = _groupByCategory(items);
    return switch (_viewMode) {
      ProductViewMode.cards => _buildCardsView(groups),
      ProductViewMode.grid => _buildGridView(groups),
      ProductViewMode.list => _buildListView(groups),
      ProductViewMode.details => _buildDetailsView(groups),
    };
  }

  // ── 1. Cards ─────────────────────────────────────────────────────────────

  Widget _buildCardsView(List<MapEntry<String, List<ProductEntity>>> groups) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1024;
    final columns = width >= 1200 ? 3 : 2;

    return CustomScrollView(
      slivers: [
        for (final entry in groups) ...[
          _categorySliverHeader(entry.key),
          if (isWide)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ProductCardTile(
                    item: entry.value[i],
                    formatPrice: _formatPrice,
                    onTap: () => _navigateToDetail(entry.value[i].id),
                    onDelete: () =>
                        _deleteProduct(entry.value[i].id, entry.value[i].name),
                  ),
                  childCount: entry.value.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: 300, // FIX 3: was 280
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ProductCardTile(
                    item: entry.value[i],
                    formatPrice: _formatPrice,
                    onTap: () => _navigateToDetail(entry.value[i].id),
                    onDelete: () =>
                        _deleteProduct(entry.value[i].id, entry.value[i].name),
                  ),
                  childCount: entry.value.length,
                ),
              ),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // ── 2. Grid ──────────────────────────────────────────────────────────────

  Widget _buildGridView(List<MapEntry<String, List<ProductEntity>>> groups) {
    return CustomScrollView(
      slivers: [
        for (final entry in groups) ...[
          _categorySliverHeader(entry.key),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => ProductGridTile(
                  item: entry.value[i],
                  formatPrice: _formatPrice,
                  onTap: () => _navigateToDetail(entry.value[i].id),
                ),
                childCount: entry.value.length,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 420,
                mainAxisExtent: 300, // FIX 3: was 280
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // ── 3. List ──────────────────────────────────────────────────────────────

  Widget _buildListView(List<MapEntry<String, List<ProductEntity>>> groups) {
    return CustomScrollView(
      slivers: [
        for (final entry in groups) ...[
          _categorySliverHeader(entry.key),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => ProductListRow(
                  item: entry.value[i],
                  formatPrice: _formatPrice,
                  onTap: () => _navigateToDetail(entry.value[i].id),
                  onDelete: () =>
                      _deleteProduct(entry.value[i].id, entry.value[i].name),
                ),
                childCount: entry.value.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // ── 4. Details ───────────────────────────────────────────────────────────
  // FIX 1: SliverPersistentHeader removed. A pinned SliverAppBar whose
  // flexibleSpace is a plain widget is safe because SliverAppBar builds
  // inside a proper BuildContext that already has Directionality resolved.

  Widget _buildDetailsView(List<MapEntry<String, List<ProductEntity>>> groups) {
    final scheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          toolbarHeight: 40,
          elevation: 0,
          backgroundColor: scheme.surface,
          flexibleSpace: _TableHeader(scheme: scheme),
        ),
        for (final entry in groups) ...[
          _categorySliverHeader(entry.key, dense: true),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => ProductTableRow(
                  item: entry.value[i],
                  formatPrice: _formatPrice,
                  isLast: i == entry.value.length - 1,
                  onTap: () => _navigateToDetail(entry.value[i].id),
                  onDelete: () =>
                      _deleteProduct(entry.value[i].id, entry.value[i].name),
                ),
                childCount: entry.value.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  SliverToBoxAdapter _categorySliverHeader(
    String categoryId, {
    bool dense = false,
  }) {
    final name = _categoryNames[categoryId] ?? categoryId;
    return SliverToBoxAdapter(
      child: _CategoryHeader(name: name, dense: dense),
    );
  }

  // ── Empty / Error / No results ───────────────────────────────────────────

  Widget _buildNoResults(BuildContext context, ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: scheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No products match your search.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _filter = const _ProductFilter());
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: scheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No products yet.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add your first product.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, ColorScheme scheme, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: scheme.error),
          const SizedBox(height: 16),
          Text(msg, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.read<ProductBloc>().add(
              ProductLoadWithPromotionsRequested(),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search products…',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: scheme.primary.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Filter Panel ─────────────────────────────────────────────────────────

class _FilterPanel extends StatelessWidget {
  final _ProductFilter filter;
  final ValueChanged<_ProductFilter> onChanged;
  const _FilterPanel({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, scheme, 'Status'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: ProductStatus.values.map((s) {
              final sel = filter.statuses.contains(s);
              return FilterChip(
                label: Text(s.displayName),
                selected: sel,
                selectedColor: s.color.withValues(alpha: 0.15),
                checkmarkColor: s.color,
                side: BorderSide(
                  color: sel
                      ? s.color.withValues(alpha: 0.6)
                      : scheme.outlineVariant,
                ),
                labelStyle: TextStyle(
                  color: sel ? s.color : scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                ),
                onSelected: (on) {
                  final next = Set<ProductStatus>.from(filter.statuses);
                  on ? next.add(s) : next.remove(s);
                  onChanged(filter.copyWith(statuses: next));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _sectionLabel(context, scheme, 'Promotion'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _boolChip(
                context,
                'On Promotion',
                Icons.local_offer_outlined,
                filter.onPromotion == true,
                Colors.deepOrange,
                () {
                  onChanged(
                    filter.copyWith(
                      onPromotion: filter.onPromotion == true
                          ? _sentinel
                          : true,
                    ),
                  );
                },
              ),
              _boolChip(
                context,
                'No Promotion',
                Icons.sell_outlined,
                filter.onPromotion == false,
                scheme.primary,
                () {
                  onChanged(
                    filter.copyWith(
                      onPromotion: filter.onPromotion == false
                          ? _sentinel
                          : false,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionLabel(context, scheme, 'Availability'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _boolChip(
                context,
                'Available',
                Icons.check_circle_outline,
                filter.available == true,
                Colors.green,
                () {
                  onChanged(
                    filter.copyWith(
                      available: filter.available == true ? _sentinel : true,
                    ),
                  );
                },
              ),
              _boolChip(
                context,
                'Unavailable',
                Icons.cancel_outlined,
                filter.available == false,
                scheme.error,
                () {
                  onChanged(
                    filter.copyWith(
                      available: filter.available == false ? _sentinel : false,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, ColorScheme scheme, String text) =>
      Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _boolChip(
    BuildContext context,
    String label,
    IconData icon,
    bool active,
    Color activeColor,
    VoidCallback onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? activeColor.withValues(alpha: 0.5)
                : scheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? activeColor : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? activeColor : scheme.onSurfaceVariant,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Active Filter Chips Row ──────────────────────────────────────────────

class _ActiveFilterChips extends StatelessWidget {
  final _ProductFilter filter;
  final ValueChanged<_ProductFilter> onRemove;
  final VoidCallback onClearAll;
  const _ActiveFilterChips({
    required this.filter,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chips = <Widget>[];

    for (final s in filter.statuses) {
      chips.add(
        _chip(s.displayName, s.color, () {
          onRemove(
            filter.copyWith(statuses: Set.from(filter.statuses)..remove(s)),
          );
        }),
      );
    }
    if (filter.onPromotion == true) {
      chips.add(
        _chip(
          'On Promotion',
          Colors.deepOrange,
          () => onRemove(filter.copyWith(onPromotion: _sentinel)),
        ),
      );
    }
    if (filter.onPromotion == false) {
      chips.add(
        _chip(
          'No Promotion',
          scheme.primary,
          () => onRemove(filter.copyWith(onPromotion: _sentinel)),
        ),
      );
    }
    if (filter.available == true) {
      chips.add(
        _chip(
          'Available',
          Colors.green,
          () => onRemove(filter.copyWith(available: _sentinel)),
        ),
      );
    }
    if (filter.available == false) {
      chips.add(
        _chip(
          'Unavailable',
          scheme.error,
          () => onRemove(filter.copyWith(available: _sentinel)),
        ),
      );
    }
    if (filter.query.isNotEmpty) {
      chips.add(
        _chip(
          '"${filter.query}"',
          scheme.secondary,
          () => onRemove(filter.copyWith(query: '')),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: chips),
            ),
          ),
          TextButton(
            onPressed: onClearAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Clear all', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 12, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Category Header ──────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  final String name;
  final bool dense;
  const _CategoryHeader({required this.name, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, dense ? 10 : 16, 16, 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: dense ? 14 : 18,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────
// FIX 1: plain StatelessWidget rendered inside a pinned SliverAppBar's
// flexibleSpace. This avoids the SliverPersistentHeaderDelegate lifecycle
// which tries to use padding before Directionality is inherited.

class _TableHeader extends StatelessWidget {
  final ColorScheme scheme;
  const _TableHeader({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: scheme.onSurfaceVariant,
    );
    return Container(
      color: scheme.surface,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          const SizedBox(width: 44 + 12),
          Expanded(flex: 3, child: Text('Name', style: style)),
          Expanded(flex: 2, child: Text('Price', style: style)),
          Expanded(flex: 2, child: Text('Status', style: style)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
