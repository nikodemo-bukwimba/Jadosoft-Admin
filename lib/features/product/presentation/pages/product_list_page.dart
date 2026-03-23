import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product_entity.dart';
import '../../domain/value_objects/product_status.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../widgets/product_card_tile.dart';
import '../widgets/product_grid_tile.dart';
import '../widgets/product_list_row.dart';
import '../widgets/product_table_row.dart';
import '../widgets/view_mode_toggle.dart';
import 'product_detail_page.dart';
import 'product_form_page.dart';

/// Main product list page with 4 view modes, search, and status filter.
class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  ProductViewMode _viewMode = ProductViewMode.card;
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    context.read<ProductBloc>().add(ProductLoadAllRequested(
          search: _searchController.text.isEmpty
              ? null
              : _searchController.text,
          status: _statusFilter,
        ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDetail(ProductEntity product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProductBloc>(),
          child: ProductDetailPage(productId: product.id),
        ),
      ),
    );
  }

  void _navigateToCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProductBloc>(),
          child: const ProductFormPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          ViewModeToggle(
            currentMode: _viewMode,
            onModeChanged: (mode) => setState(() => _viewMode = mode),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search + filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _loadProducts();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _loadProducts(),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusFilterChip(
                  selectedStatus: _statusFilter,
                  onChanged: (status) {
                    setState(() => _statusFilter = status);
                    _loadProducts();
                  },
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: BlocConsumer<ProductBloc, ProductState>(
              listener: (context, state) {
                if (state is ProductOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                  _loadProducts();
                }
              },
              builder: (context, state) {
                if (state is ProductListLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProductError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48,
                            color: colorScheme.error),
                        const SizedBox(height: 12),
                        Text(state.message,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: _loadProducts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is ProductListLoaded) {
                  if (state.products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64,
                              color: colorScheme.onSurfaceVariant
                                  .withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'No products found',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _loadProducts(),
                    child: _buildListView(state.products),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListView(List<ProductEntity> products) {
    switch (_viewMode) {
      case ProductViewMode.grid:
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => ProductGridTile(
            product: products[i],
            onTap: () => _navigateToDetail(products[i]),
          ),
        );

      case ProductViewMode.card:
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: products.length,
          itemBuilder: (_, i) => ProductCardTile(
            product: products[i],
            onTap: () => _navigateToDetail(products[i]),
          ),
        );

      case ProductViewMode.list:
        return ListView.separated(
          padding: const EdgeInsets.only(top: 4, bottom: 80),
          itemCount: products.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 64,
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withOpacity(0.3),
          ),
          itemBuilder: (_, i) => ProductListRow(
            product: products[i],
            onTap: () => _navigateToDetail(products[i]),
          ),
        );

      case ProductViewMode.table:
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              headingRowHeight: 44,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 56,
              columns: ProductTableRow.columns(context),
              rows: products
                  .map((p) => ProductTableRow.row(
                        context: context,
                        product: p,
                        onTap: () => _navigateToDetail(p),
                      ))
                  .toList(),
            ),
          ),
        );
    }
  }
}

// ── Status filter dropdown ────────────────────────────────────────────

class _StatusFilterChip extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onChanged;

  const _StatusFilterChip({
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String?>(
      tooltip: 'Filter by status',
      onSelected: onChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedStatus != null
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(10),
          color: selectedStatus != null
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 18,
              color: selectedStatus != null
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            if (selectedStatus != null) ...[
              const SizedBox(width: 4),
              Text(
                ProductStatus.fromString(selectedStatus!).label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem<String?>(
          value: null,
          child: Text('All Statuses'),
        ),
        ...ProductStatus.values.map((s) => PopupMenuItem<String?>(
              value: s.name,
              child: Row(
                children: [
                  Icon(s.icon, size: 16, color: s.color),
                  const SizedBox(width: 8),
                  Text(s.label),
                ],
              ),
            )),
      ],
    );
  }
}
