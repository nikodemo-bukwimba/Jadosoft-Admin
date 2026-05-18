// lib/features/product/presentation/pages/product_detail_page.dart
//
// CHANGE: _InventoryCard is now stateful and loads LIVE inventory data.
//
// Previously: showed ProductEntity.quantityAvailable (manually typed metadata
//   in product form) — completely disconnected from the inventory system.
//
// Now:
//   • On mount, calls GetVariantStockUseCase(orgId, variantId) to fetch real
//     stock from the inventory module.
//   • Displays VariantStockEntity.totalStock as the live available quantity.
//   • Lists every InventoryBatchEntity (active / near-expiry / expired /
//     depleted) so staff can see exactly which batches are on hand.
//   • "Receive Stock" button navigates to the inventory receive-stock form
//     pre-selecting this product (passes productId as query parameter).
//   • Refreshes automatically when returning from the receive-stock form.
//   • Falls back to metadata values when variantId is null (product not yet
//     received into inventory).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/routes/app_router.dart';
import '../../../../core/context/org_context.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/value_objects/product_status.dart';
import '../widgets/product_image.dart';
import '../widgets/product_status_badge.dart';
import '../widgets/product_confirm_name_dialog.dart';
import '../widgets/promotion_price_display.dart';
import '../../../category/domain/usecases/get_category_usecase.dart';
import '../../../inventory/domain/entities/inventory_entity.dart';
import '../../../inventory/domain/usecases/get_variant_stock_usecase.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key});

  Future<String> _getCategoryName(String categoryId) async {
    try {
      final useCase = GetIt.instance<GetCategoryUseCase>();
      final result = await useCase(GetCategoryParams(id: categoryId));
      return result.fold((_) => categoryId, (cat) => cat.name);
    } catch (_) {
      return categoryId;
    }
  }

  String _formatPrice(double v) =>
      'TZS ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          if (state.updatedItem != null) {
            context.read<ProductBloc>().add(
              ProductLoadOneRequested(state.updatedItem!.id),
            );
          } else {
            context.pop();
          }
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
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is ProductFailure) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: scheme.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is ProductDetailLoaded) {
          return _DetailView(
            item: state.item,
            getCategoryName: _getCategoryName,
            formatPrice: _formatPrice,
          );
        }
        return Scaffold(appBar: AppBar());
      },
    );
  }
}

// ─── Detail View ─────────────────────────────────────────────────────────────

class _DetailView extends StatefulWidget {
  final ProductEntity item;
  final Future<String> Function(String) getCategoryName;
  final String Function(double) formatPrice;

  const _DetailView({
    required this.item,
    required this.getCategoryName,
    required this.formatPrice,
  });

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    _loadCategory();
  }

  Future<void> _loadCategory() async {
    final name = await widget.getCategoryName(widget.item.categoryId);
    if (mounted) setState(() => _categoryName = name);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final statusEnum = ProductStatusX.fromString(item.status);
    final scheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => context.push(AppRouter.productEditPath(item.id)),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: scheme.error),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, item.id, item.name),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _ImageSection(item: item),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.formatPrice(item.price),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: item.isOnPromotion
                        ? scheme.onSurfaceVariant
                        : scheme.primary,
                    fontWeight: FontWeight.w700,
                    decoration: item.isOnPromotion
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  Text(
                    item.description!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (item.isOnPromotion) ...[
                  _PromotionPricingSection(
                    item: item,
                    formatPrice: widget.formatPrice,
                  ),
                  const SizedBox(height: 16),
                ],
                _ActionsSection(item: item, statusEnum: statusEnum),
                const SizedBox(height: 16),
                _InfoCard(
                  item: item,
                  categoryName: _categoryName,
                  formatPrice: widget.formatPrice,
                  scheme: scheme,
                  theme: Theme.of(context),
                ),

                // ── Live inventory card ──────────────────────────────
                const SizedBox(height: 12),
                _LiveInventoryCard(item: item, scheme: scheme),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String id,
    String name,
  ) async {
    final confirmed = await ProductConfirmNameDialog.show(
      context,
      title: 'Delete Product?',
      productName: name,
      actionLabel: 'Delete',
      actionColor: Theme.of(context).colorScheme.error,
      warningMessage:
          'This action is irreversible. The product will be permanently removed from the system.',
    );
    if (confirmed && context.mounted) {
      context.read<ProductBloc>().add(ProductDeleteRequested(id));
    }
  }
}

// ─── Image Section ────────────────────────────────────────────────────────────

class _ImageSection extends StatelessWidget {
  final ProductEntity item;
  const _ImageSection({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusEnum = ProductStatusX.fromString(item.status);

    return Stack(
      fit: StackFit.expand,
      children: [
        ProductImage(
          imageUrl: item.imageUrl,
          borderRadius: 0,
          fit: BoxFit.cover,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              ProductStatusBadge(status: statusEnum),
              const SizedBox(width: 8),
              if (item.isNew) _overlayTag('NEW', Colors.blue),
              if (item.isFeatured) ...[
                const SizedBox(width: 6),
                _overlayTag('FEATURED', Colors.amber.shade800),
              ],
              if (!item.isAvailable) ...[
                const SizedBox(width: 6),
                _overlayTag('UNAVAILABLE', Colors.red),
              ],
            ],
          ),
        ),
        if (item.isOnPromotion)
          Positioned(
            top: 10,
            left: 10,
            child: PromotionCornerTag(percentage: item.discountPercentage!),
          ),
      ],
    );
  }

  Widget _overlayTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Promotion Pricing Section ────────────────────────────────────────────────

class _PromotionPricingSection extends StatelessWidget {
  final ProductEntity item;
  final String Function(double) formatPrice;

  const _PromotionPricingSection({
    required this.item,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    final discount = item.discountPercentage!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_offer_outlined,
            size: 20,
            color: Colors.deepOrange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Promotion',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                PromotionPriceDisplay(product: item, formatPrice: formatPrice),
              ],
            ),
          ),
          PromotionDiscountBadge(percentage: discount, large: true),
        ],
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final ProductEntity item;
  final String? categoryName;
  final String Function(double) formatPrice;
  final ColorScheme scheme;
  final ThemeData theme;

  const _InfoCard({
    required this.item,
    required this.categoryName,
    required this.formatPrice,
    required this.scheme,
    required this.theme,
  });

  String _discountLabel(double v) =>
      v % 1 == 0 ? '${v.toInt()}%' : '${v.toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final statusEnum = ProductStatusX.fromString(item.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Information',
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(height: 24),
            _field(context, 'Category', categoryName ?? '...'),
            _field(context, 'Base Price', formatPrice(item.price)),
            if (item.isOnPromotion)
              _field(
                context,
                'Sale Price',
                '${formatPrice(item.displayPrice)} '
                    '(${_discountLabel(item.discountPercentage!)} OFF)',
                valueColor: Colors.deepOrange,
              ),
            _field(context, 'Available', item.isAvailable ? 'Yes' : 'No'),
            _field(context, 'Featured', item.isFeatured ? 'Yes' : 'No'),
            _field(context, 'New Product', item.isNew ? 'Yes' : 'No'),
            _field(context, 'Status', statusEnum.displayName),
            _field(
              context,
              'Created',
              item.createdAt.toIso8601String().split('T').first,
            ),
            _field(context, 'ID', item.id),
          ],
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Live Inventory Card ──────────────────────────────────────────────────────
//
// Replaces the old static _InventoryCard.
//
// Loads VariantStockEntity from GetVariantStockUseCase on mount and after
// returning from the receive-stock form. Shows:
//   • Total live stock (from inventory batches, not metadata)
//   • Per-batch breakdown grouped by status (active / near-expiry / expired)
//   • "Receive Stock" shortcut button pre-selecting this product
//   • Falls back to metadata (batchNumber / packSize / expiryDate from
//     ProductEntity) when variantId is null (product not yet received)

class _LiveInventoryCard extends StatefulWidget {
  final ProductEntity item;
  final ColorScheme scheme;

  const _LiveInventoryCard({required this.item, required this.scheme});

  @override
  State<_LiveInventoryCard> createState() => _LiveInventoryCardState();
}

class _LiveInventoryCardState extends State<_LiveInventoryCard> {
  VariantStockEntity? _stock;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final variantId = widget.item.variantId;
    if (variantId == null) return;

    setState(() { _loading = true; _error = null; });

    try {
      final orgId   = GetIt.instance<OrgContext>().requireRootOrgId();
      final useCase = GetIt.instance<GetVariantStockUseCase>();
      final result  = await useCase(
        GetVariantStockParams(orgId: orgId, variantId: variantId),
      );
      result.fold(
        (f) {
          if (mounted) setState(() { _loading = false; _error = f.message; });
        },
        (stock) {
          if (mounted) setState(() { _loading = false; _stock = stock; });
        },
      );
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  // Navigate to receive stock, pre-selecting this product, then refresh
  Future<void> _navigateToReceiveStock(BuildContext context) async {
    await context.push(
      AppRouter.inventoryReceiveStock,
      extra: {'productId': widget.item.id},
    );
    // Refresh inventory data when returning
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final item   = widget.item;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Inventory',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                // Refresh button
                if (item.variantId != null)
                  IconButton(
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    tooltip: 'Refresh stock',
                    onPressed: _loading ? null : _load,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const Divider(height: 24),

            // ── No variantId — product not received yet ─────────────
            if (item.variantId == null) ...[
              _staticFallback(context, item, scheme),
            ]

            // ── Loading ────────────────────────────────────────────
            else if (_loading && _stock == null) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              ),
            ]

            // ── Error ──────────────────────────────────────────────
            else if (_error != null && _stock == null) ...[
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Could not load stock: $_error',
                      style: TextStyle(fontSize: 13, color: scheme.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _staticFallback(context, item, scheme),
            ]

            // ── Live data ──────────────────────────────────────────
            else if (_stock != null) ...[
              _liveStock(context, _stock!, scheme),
            ],

            // ── Receive Stock button ────────────────────────────────
            if (item.variantId != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _navigateToReceiveStock(context),
                icon: const Icon(Icons.add_box_outlined, size: 18),
                label: const Text('Receive Stock'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Static fallback — shows metadata fields when variantId is unavailable
  Widget _staticFallback(
    BuildContext context,
    ProductEntity item,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(context, 'Batch Number', item.batchNumber ?? '—', scheme),
        _field(context, 'Pack Size', item.packSize ?? '—', scheme),
        _field(
          context,
          'Available Qty',
          item.quantityAvailable?.toString() ?? '—',
          scheme,
        ),
        _expiryRow(context, item.expiryDate, scheme),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live stock tracking starts once stock is received into a warehouse.',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Live inventory — shows totalStock + per-batch breakdown
  Widget _liveStock(
    BuildContext context,
    VariantStockEntity stock,
    ColorScheme scheme,
  ) {
    final batches     = stock.batches;
    final active      = batches.where((b) => b.isActive && !b.isExpired && !b.isNearExpiry && !b.isDepleted).toList();
    final nearExpiry  = batches.where((b) => b.isNearExpiry && !b.isExpired).toList();
    final expired     = batches.where((b) => b.isExpired).toList();
    final depleted    = batches.where((b) => b.isDepleted && !b.isExpired).toList();

    // Total stock colour
    final isLow      = stock.totalStock > 0 && stock.totalStock <= 10;
    final isDepleted = stock.totalStock <= 0;
    final stockColor = isDepleted
        ? scheme.error
        : isLow
            ? Colors.orange.shade700
            : Colors.green.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Total stock summary ─────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: stockColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: stockColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                isDepleted
                    ? Icons.remove_shopping_cart_outlined
                    : Icons.inventory_2_outlined,
                color: stockColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Available Stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: stockColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${stock.totalStock} units',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDepleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'OUT OF STOCK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                )
              else if (isLow)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LOW STOCK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (batches.isEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'No stock batches received yet.',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ] else ...[
          const SizedBox(height: 16),

          // ── Batch groups ──────────────────────────────────────
          if (expired.isNotEmpty) ...[
            _batchGroupHeader('Expired (${expired.length})',
                Colors.red.shade700),
            ...expired.map((b) => _batchRow(context, b, scheme)),
            const SizedBox(height: 10),
          ],
          if (nearExpiry.isNotEmpty) ...[
            _batchGroupHeader('Near Expiry (${nearExpiry.length})',
                Colors.orange.shade700),
            ...nearExpiry.map((b) => _batchRow(context, b, scheme)),
            const SizedBox(height: 10),
          ],
          if (active.isNotEmpty) ...[
            _batchGroupHeader('Active (${active.length})',
                Colors.green.shade700),
            ...active.map((b) => _batchRow(context, b, scheme)),
            const SizedBox(height: 10),
          ],
          if (depleted.isNotEmpty) ...[
            _batchGroupHeader('Depleted (${depleted.length})',
                Colors.grey.shade600),
            ...depleted.map((b) => _batchRow(context, b, scheme)),
          ],
        ],
      ],
    );
  }

  Widget _batchGroupHeader(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _batchRow(
    BuildContext context,
    InventoryBatchEntity batch,
    ColorScheme scheme,
  ) {
    final statusColor = batch.isExpired
        ? Colors.red.shade700
        : batch.isNearExpiry
            ? Colors.orange.shade700
            : batch.isDepleted
                ? Colors.grey.shade600
                : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  batch.batchNumber != null
                      ? 'Batch: ${batch.batchNumber}'
                      : 'Batch: ${batch.id.substring(0, 8)}…',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${batch.quantityAvailable} units',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (batch.warehouseName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.warehouse_outlined,
                    size: 13, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  batch.warehouseName,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          if (batch.expiresAt != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.event_outlined,
                    size: 13, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Expires: ${_fmtDate(batch.expiresAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: batch.isExpired
                        ? Colors.red.shade700
                        : batch.isNearExpiry
                            ? Colors.orange.shade700
                            : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Widget _expiryRow(
    BuildContext context,
    DateTime? expiryDate,
    ColorScheme scheme,
  ) {
    final label = expiryDate != null
        ? '${expiryDate.year}-'
            '${expiryDate.month.toString().padLeft(2, '0')}-'
            '${expiryDate.day.toString().padLeft(2, '0')}'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(context, 'Expiry Date', label, scheme),
        if (expiryDate != null) ...[
          const SizedBox(height: 4),
          Builder(builder: (context) {
            final daysLeft = expiryDate.difference(DateTime.now()).inDays;
            final isExpiringSoon = daysLeft <= 180;
            final isExpired = daysLeft < 0;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isExpired
                    ? scheme.errorContainer
                    : isExpiringSoon
                        ? Colors.orange.withValues(alpha: 0.15)
                        : Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isExpired
                    ? 'Expired ${daysLeft.abs()} days ago'
                    : isExpiringSoon
                        ? 'Expires in $daysLeft days — check stock'
                        : 'Expires in $daysLeft days',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isExpired
                      ? scheme.onErrorContainer
                      : isExpiringSoon
                          ? Colors.orange.shade800
                          : Colors.green.shade800,
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _field(
    BuildContext context,
    String label,
    String value,
    ColorScheme scheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Actions Section ──────────────────────────────────────────────────────────

class _ActionsSection extends StatelessWidget {
  final ProductEntity item;
  final ProductStatus statusEnum;

  const _ActionsSection({required this.item, required this.statusEnum});

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    if (statusEnum == ProductStatus.draft) {
      actions.add(
        _actionButton(
          context,
          icon: Icons.publish,
          label: 'Publish',
          color: Colors.green,
          onPressed: () =>
              context.read<ProductBloc>().add(ProductPublishRequested(item.id)),
        ),
      );
    }
    if (statusEnum == ProductStatus.active) {
      actions.add(
        _actionButton(
          context,
          icon: Icons.star_outline,
          label: 'Mark Featured',
          color: Colors.amber.shade800,
          onPressed: () =>
              context.read<ProductBloc>().add(ProductFeatureRequested(item.id)),
        ),
      );
    }
    if (statusEnum == ProductStatus.featured) {
      actions.add(
        _actionButton(
          context,
          icon: Icons.star_border,
          label: 'Remove Featured',
          color: Colors.grey,
          onPressed: () => context.read<ProductBloc>().add(
            ProductUnfeatureRequested(item.id),
          ),
        ),
      );
    }
    if (statusEnum == ProductStatus.active ||
        statusEnum == ProductStatus.featured) {
      actions.add(
        _actionButton(
          context,
          icon: Icons.archive_outlined,
          label: 'Archive',
          color: Colors.blueGrey,
          onPressed: () async {
            final confirmed = await ProductConfirmNameDialog.show(
              context,
              title: 'Archive Product?',
              productName: item.name,
              actionLabel: 'Archive',
              actionColor: Colors.blueGrey,
              warningMessage:
                  'Archiving will hide this product from all listings. This action cannot be undone.',
            );
            if (confirmed && context.mounted) {
              context.read<ProductBloc>().add(ProductArchiveRequested(item.id));
            }
          },
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: actions),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}