import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../widgets/view_mode_toggle.dart';
import '../widgets/product_card_tile.dart';
import '../widgets/product_grid_tile.dart';
import '../widgets/product_list_row.dart';
import '../widgets/product_table_row.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  ProductViewMode _viewMode = ProductViewMode.cards;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(ProductLoadAllRequested());
  }

  void _navigateToDetail(String id) =>
      context.push(AppRouter.productDetailPath(id));

  void _deleteProduct(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Remove "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ProductBloc>().add(ProductDeleteRequested(id));
    }
  }

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) buffer.write(',');
      buffer.write(formatted[i]);
    }
    return 'TZS $buffer';
  }

  /// Responsive grid column count based on screen width.
  int _gridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 5;
    if (width >= 1024) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          ViewModeToggle(
            current: _viewMode,
            onChanged: (mode) => setState(() => _viewMode = mode),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRouter.productCreate),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            context.read<ProductBloc>().add(ProductLoadAllRequested());
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
          if (state is ProductEmpty) {
            return _buildEmpty(context, scheme);
          }
          if (state is ProductFailure) {
            return _buildError(context, scheme, state.message);
          }
          if (state is ProductListLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<ProductBloc>().add(ProductLoadAllRequested()),
              child: _buildView(state.items),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ─── View Router ───────────────────────────────────────────

  Widget _buildView(List<ProductEntity> items) {
    return switch (_viewMode) {
      ProductViewMode.cards => _buildCardsView(items),
      ProductViewMode.grid => _buildGridView(items),
      ProductViewMode.list => _buildListView(items),
      ProductViewMode.details => _buildDetailsView(items),
    };
  }

  // ── 1. Cards ───────────────────────────────────────────────

  Widget _buildCardsView(List<ProductEntity> items) {
    final width = MediaQuery.of(context).size.width;

    // On wide screens, show cards in a grid instead of single column
    if (width >= 1024) {
      final columns = width >= 1200 ? 3 : 2;
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: 280,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => ProductCardTile(
          item: items[i],
          formatPrice: _formatPrice,
          onTap: () => _navigateToDetail(items[i].id),
          onDelete: () => _deleteProduct(items[i].id, items[i].name),
        ),
      );
    }

    // Mobile/tablet: single column list
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => ProductCardTile(
        item: items[i],
        formatPrice: _formatPrice,
        onTap: () => _navigateToDetail(items[i].id),
        onDelete: () => _deleteProduct(items[i].id, items[i].name),
      ),
    );
  }

  // ── 2. Grid ────────────────────────────────────────────────

  Widget _buildGridView(List<ProductEntity> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 280,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => ProductGridTile(
        item: items[i],
        formatPrice: _formatPrice,
        onTap: () => _navigateToDetail(items[i].id),
      ),
    );
  }

  // ── 3. List ────────────────────────────────────────────────

  Widget _buildListView(List<ProductEntity> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) => ProductListRow(
        item: items[i],
        formatPrice: _formatPrice,
        onTap: () => _navigateToDetail(items[i].id),
        onDelete: () => _deleteProduct(items[i].id, items[i].name),
      ),
    );
  }

  // ── 4. Details ─────────────────────────────────────────────

  Widget _buildDetailsView(List<ProductEntity> items) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Table header
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
                Expanded(flex: 2, child: Text('Price', style: _headerStyle)),
                Expanded(flex: 2, child: Text('Status', style: _headerStyle)),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Table rows
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return ProductTableRow(
              item: item,
              formatPrice: _formatPrice,
              isLast: i == items.length - 1,
              onTap: () => _navigateToDetail(item.id),
              onDelete: () => _deleteProduct(item.id, item.name),
            );
          }),
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

  // ─── Empty / Error ─────────────────────────────────────────

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
            onPressed: () =>
                context.read<ProductBloc>().add(ProductLoadAllRequested()),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
