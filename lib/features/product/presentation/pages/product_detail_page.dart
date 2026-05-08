// lib/features/product/presentation/pages/product_detail_page.dart
//
// MERGED: Retains all original implementations (collapsing AppBar, full
// inventory card, expiry badge, delete action, featured/unfeatured/archive/
// publish state-machine, confirm-name dialog) while adding:
//   • _PromotionPricingSection  – shown between price and info when on promo
//   • _ImageSection             – now also renders a PromotionCornerTag
//   • Refactored sub-widgets    – _DetailView, _InfoCard, _ActionsSection
//   • Cleaner _formatPrice      – regex-based thousands separator
// ─────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/value_objects/product_status.dart';
import '../widgets/product_image.dart';
import '../widgets/product_status_badge.dart';
import '../widgets/product_confirm_name_dialog.dart';
import '../widgets/promotion_price_display.dart';
import 'package:get_it/get_it.dart';
import '../../../category/domain/usecases/get_category_usecase.dart';

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

  // Cleaner regex-based formatter (from new file)
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
            // Keep original behaviour: pop when no updated item is returned
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

// ─── Detail View ────────────────────────────────────────────────────────────
// Stateful so category can be loaded once and cached (from new file).

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

    // Retain original collapsing-image AppBar layout
    return CustomScrollView(
      slivers: [
        // ── Collapsing Image AppBar ──────────────────────────────────────
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

        // ── Body ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name ──
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),

                // ── Base price (always shown) ──
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

                // ── Description ──
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

                // ── Promotion Pricing (NEW) ──────────────────────────
                if (item.isOnPromotion) ...[
                  _PromotionPricingSection(
                    item: item,
                    formatPrice: widget.formatPrice,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── State Machine Actions ────────────────────────────
                _ActionsSection(item: item, statusEnum: statusEnum),

                // ── Details Card ─────────────────────────────────────
                const SizedBox(height: 16),
                _InfoCard(
                  item: item,
                  categoryName: _categoryName,
                  formatPrice: widget.formatPrice,
                  scheme: scheme,
                  theme: Theme.of(context),
                ),

                // ── Inventory Card ───────────────────────────────────
                const SizedBox(height: 12),
                _InventoryCard(item: item, scheme: scheme),

                const SizedBox(height: 80), // FAB clearance
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

// ─── Image Section ────────────────────────────────────────────────────────
// Retains original gradient scrim + overlay tags; adds PromotionCornerTag.

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
        // Gradient scrim for readability
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
        ),
        // Status / feature tags at bottom-left (original)
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
        // Promotion corner tag (NEW)
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

// ─── Promotion Pricing Section (NEW) ──────────────────────────────────────

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

// ─── Info Card ────────────────────────────────────────────────────────────
// Original "Product Information" card, extended with sale price row.

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
            // Sale price row — only when on promotion (NEW)
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

// ─── Inventory Card ───────────────────────────────────────────────────────
// Unchanged from the original; extracted into its own widget for clarity.

class _InventoryCard extends StatelessWidget {
  final ProductEntity item;
  final ColorScheme scheme;

  const _InventoryCard({required this.item, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(height: 24),
            _field(context, 'Batch Number', item.batchNumber ?? '—'),
            _field(context, 'Pack Size', item.packSize ?? '—'),
            _field(
              context,
              'Available Qty',
              item.quantityAvailable != null
                  ? item.quantityAvailable.toString()
                  : '—',
            ),
            _field(
              context,
              'Expiry Date',
              item.expiryDate != null
                  ? '${item.expiryDate!.year}-'
                        '${item.expiryDate!.month.toString().padLeft(2, '0')}-'
                        '${item.expiryDate!.day.toString().padLeft(2, '0')}'
                  : '—',
            ),
            if (item.expiryDate != null) ...[
              const SizedBox(height: 4),
              Builder(
                builder: (context) {
                  final daysLeft = item.expiryDate!
                      .difference(DateTime.now())
                      .inDays;
                  final isExpiringSoon = daysLeft <= 180;
                  final isExpired = daysLeft < 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
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
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext context, String label, String value) {
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
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ─── Actions Section ──────────────────────────────────────────────────────
// Identical logic to original; extracted into its own widget.

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
