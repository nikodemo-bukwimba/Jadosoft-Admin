// customer_list_page.dart
// Changes:
//   1. Refresh button in AppBar.
//   2. Search bar — searches name, phone, code.
//   3. Filter chips: Region, District, Customer Type, Status.
//      These use the same TanzaniaLocations data.
//   4. Filters are applied client-side on the loaded list so no
//      additional API round-trips are needed per filter change.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../core/data/tanzania_locations.dart';
import '../../domain/entities/customer_entity.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../widgets/customer_card_tile.dart';
import '../widgets/customer_list_row.dart';
import '../widgets/customer_table_row.dart';

enum _ViewMode { cards, list, details }

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});
  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  _ViewMode _viewMode = _ViewMode.cards;

  // Search & filter state
  final _searchCtl = TextEditingController();
  String? _filterRegion;
  String? _filterDistrict;
  String? _filterType; // b2b | b2c
  String? _filterStatus; // active | inactive | blacklisted

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(CustomerLoadAllRequested());
    _searchCtl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  void _refresh() =>
      context.read<CustomerBloc>().add(CustomerLoadAllRequested());

  void _navigateToDetail(String id) =>
      context.push(AppRouter.customerDetailPath(id));

  void _deleteCustomer(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text('Remove "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dc, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<CustomerBloc>().add(CustomerDeleteRequested(id));
    }
  }

  // ── Client-side filter ────────────────────────────────────

  List<CustomerEntity> _applyFilters(List<CustomerEntity> items) {
    var result = items;
    final q = _searchCtl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (e) =>
                e.name.toLowerCase().contains(q) ||
                (e.phone ?? '').contains(q) ||
                (e.code ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    if (_filterRegion != null) {
      result = result
          .where(
            (e) =>
                (e.county ?? '').toLowerCase() == _filterRegion!.toLowerCase(),
          )
          .toList();
    }
    if (_filterDistrict != null) {
      result = result
          .where(
            (e) =>
                (e.city ?? '').toLowerCase() == _filterDistrict!.toLowerCase(),
          )
          .toList();
    }
    if (_filterType != null) {
      result = result.where((e) => e.customerType == _filterType).toList();
    }
    if (_filterStatus != null) {
      result = result.where((e) => e.status == _filterStatus).toList();
    }
    return result;
  }

  bool get _hasActiveFilters =>
      _filterRegion != null ||
      _filterDistrict != null ||
      _filterType != null ||
      _filterStatus != null ||
      _searchCtl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
          _buildViewToggle(scheme),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRouter.customerCreate),
        child: const Icon(Icons.store_outlined),
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            _refresh();
          }
          if (state is CustomerFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CustomerLoading || state is CustomerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CustomerEmpty) return _buildEmpty(context, scheme);
          if (state is CustomerFailure) {
            return _buildError(context, scheme, state.message);
          }
          if (state is CustomerListLoaded) {
            final filtered = _applyFilters(state.items);
            return Column(
              children: [
                _buildSearchBar(scheme),
                _buildFilterRow(scheme),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildNoResults(context, scheme)
                      : RefreshIndicator(
                          onRefresh: () async => _refresh(),
                          child: _buildView(filtered),
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────

  Widget _buildSearchBar(ColorScheme scheme) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: TextField(
      controller: _searchCtl,
      decoration: InputDecoration(
        hintText: 'Search by name, phone or code…',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchCtl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => _searchCtl.clear(),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    ),
  );

  // ── Filter chips row ──────────────────────────────────────

  Widget _buildFilterRow(ColorScheme scheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // Region filter
          _FilterChipButton(
            label: _filterRegion ?? 'Region',
            isActive: _filterRegion != null,
            onTap: () => _showRegionFilter(),
            onClear: _filterRegion != null
                ? () => setState(() {
                    _filterRegion = null;
                    _filterDistrict = null;
                  })
                : null,
          ),
          const SizedBox(width: 8),

          // District filter (only when region selected)
          if (_filterRegion != null) ...[
            _FilterChipButton(
              label: _filterDistrict ?? 'District',
              isActive: _filterDistrict != null,
              onTap: () => _showDistrictFilter(),
              onClear: _filterDistrict != null
                  ? () => setState(() => _filterDistrict = null)
                  : null,
            ),
            const SizedBox(width: 8),
          ],

          // Type filter
          _FilterChipButton(
            label: _filterType == 'b2b'
                ? 'B2B'
                : _filterType == 'b2c'
                ? 'B2C'
                : 'Type',
            isActive: _filterType != null,
            onTap: () => _showTypeFilter(),
            onClear: _filterType != null
                ? () => setState(() => _filterType = null)
                : null,
          ),
          const SizedBox(width: 8),

          // Status filter
          _FilterChipButton(
            label: _filterStatus != null
                ? _filterStatus![0].toUpperCase() + _filterStatus!.substring(1)
                : 'Status',
            isActive: _filterStatus != null,
            onTap: () => _showStatusFilter(),
            onClear: _filterStatus != null
                ? () => setState(() => _filterStatus = null)
                : null,
          ),

          // Clear all
          if (_hasActiveFilters) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => setState(() {
                _filterRegion = null;
                _filterDistrict = null;
                _filterType = null;
                _filterStatus = null;
                _searchCtl.clear();
              }),
              child: const Text('Clear all'),
            ),
          ],
        ],
      ),
    );
  }

  // ── Filter bottom sheets ──────────────────────────────────

  Future<void> _showRegionFilter() async {
    final picked = await _showPickerSheet(
      title: 'Filter by Region',
      items: TanzaniaLocations.regions,
      selected: _filterRegion,
    );
    if (picked != null && mounted) {
      setState(() {
        _filterRegion = picked;
        _filterDistrict = null;
      });
    }
  }

  Future<void> _showDistrictFilter() async {
    if (_filterRegion == null) return;
    final districts = TanzaniaLocations.getDistricts(_filterRegion!);
    if (districts.isEmpty) return;
    final picked = await _showPickerSheet(
      title: 'Filter by District',
      items: districts,
      selected: _filterDistrict,
    );
    if (picked != null && mounted) setState(() => _filterDistrict = picked);
  }

  Future<void> _showTypeFilter() async {
    final picked = await _showPickerSheet(
      title: 'Customer Type',
      items: const ['b2b', 'b2c'],
      selected: _filterType,
      displayMap: {'b2b': 'B2B (Business)', 'b2c': 'B2C (Individual)'},
    );
    if (picked != null && mounted) setState(() => _filterType = picked);
  }

  Future<void> _showStatusFilter() async {
    final picked = await _showPickerSheet(
      title: 'Filter by Status',
      items: const ['active', 'inactive', 'blacklisted'],
      selected: _filterStatus,
      displayMap: {
        'active': 'Active',
        'inactive': 'Inactive',
        'blacklisted': 'Blacklisted',
      },
    );
    if (picked != null && mounted) setState(() => _filterStatus = picked);
  }

  Future<String?> _showPickerSheet({
    required String title,
    required List<String> items,
    String? selected,
    Map<String, String>? displayMap,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final val = items[i];
                  final label =
                      displayMap?[val] ??
                      (val[0].toUpperCase() + val.substring(1));
                  return RadioListTile<String>(
                    title: Text(label),
                    value: val,
                    groupValue: selected,
                    onChanged: (v) => Navigator.pop(ctx, v),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── View toggle & rendering ───────────────────────────────

  Widget _buildViewToggle(ColorScheme scheme) {
    const modes = [
      (_ViewMode.cards, Icons.dashboard_outlined, 'Cards'),
      (_ViewMode.list, Icons.view_list_outlined, 'List'),
      (_ViewMode.details, Icons.table_rows_outlined, 'Details'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((m) {
          final sel = m.$1 == _viewMode;
          return Tooltip(
            message: m.$3,
            child: GestureDetector(
              onTap: () => setState(() => _viewMode = m.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: sel ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  m.$2,
                  size: 18,
                  color: sel ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildView(List<CustomerEntity> items) => switch (_viewMode) {
    _ViewMode.cards => _buildCardsView(items),
    _ViewMode.list => _buildListView(items),
    _ViewMode.details => _buildDetailsView(items),
  };

  Widget _buildCardsView(List<CustomerEntity> items) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1024) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: w >= 1200 ? 3 : 2,
          mainAxisExtent: 180,
          crossAxisSpacing: 12,
          mainAxisSpacing: 8,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => CustomerCardTile(
          item: items[i],
          onTap: () => _navigateToDetail(items[i].id),
          onDelete: () => _deleteCustomer(items[i].id, items[i].name),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => CustomerCardTile(
        item: items[i],
        onTap: () => _navigateToDetail(items[i].id),
        onDelete: () => _deleteCustomer(items[i].id, items[i].name),
      ),
    );
  }

  Widget _buildListView(List<CustomerEntity> items) => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    itemCount: items.length,
    itemBuilder: (_, i) => CustomerListRow(
      item: items[i],
      onTap: () => _navigateToDetail(items[i].id),
      onDelete: () => _deleteCustomer(items[i].id, items[i].name),
    ),
  );

  Widget _buildDetailsView(List<CustomerEntity> items) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 44),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: Text('Name', style: _headerStyle)),
                Expanded(flex: 2, child: Text('Type', style: _headerStyle)),
                Expanded(flex: 2, child: Text('Phone', style: _headerStyle)),
                const SizedBox(width: 40),
              ],
            ),
          ),
          ...items.asMap().entries.map(
            (e) => CustomerTableRow(
              item: e.value,
              isLast: e.key == items.length - 1,
              onTap: () => _navigateToDetail(e.value.id),
              onDelete: () => _deleteCustomer(e.value.id, e.value.name),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  Widget _buildEmpty(BuildContext context, ColorScheme scheme) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.store_outlined, size: 64, color: scheme.outlineVariant),
        const SizedBox(height: 16),
        Text(
          'No customers yet.',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap + to add your first customer.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    ),
  );

  Widget _buildNoResults(BuildContext context, ColorScheme scheme) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 48, color: scheme.outlineVariant),
        const SizedBox(height: 12),
        Text(
          'No customers match the current filters.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _filterRegion = null;
            _filterDistrict = null;
            _filterType = null;
            _filterStatus = null;
            _searchCtl.clear();
          }),
          child: const Text('Clear filters'),
        ),
      ],
    ),
  );

  Widget _buildError(BuildContext context, ColorScheme scheme, String msg) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
}

// ── Reusable filter chip button ───────────────────────────────

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _FilterChipButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? scheme.primary.withValues(alpha: 0.5)
                : scheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 14, color: scheme.primary),
              ),
            ] else ...[
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: isActive ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
