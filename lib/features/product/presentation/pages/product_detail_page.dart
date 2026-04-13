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

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) buffer.write(',');
      buffer.write(formatted[i]);
    }
    return 'TZS $buffer';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
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
            return _buildDetail(context, state.item);
          }
          return Scaffold(appBar: AppBar());
        },
      ),
    );
  }

  Widget _buildDetail(BuildContext context, ProductEntity item) {
    final scheme = Theme.of(context).colorScheme;
    final statusEnum = ProductStatusX.fromString(item.status);

    return CustomScrollView(
      slivers: [
        // ── Collapsing Image AppBar ──
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
            background: Stack(
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
                // Tags on image
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
              ],
            ),
          ),
        ),

        // ── Body ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name + Price ──
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatPrice(item.price),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
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

                // ── State Machine Actions ──
                _buildActions(context, item, statusEnum),

                // ── Details Card ──
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Information',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Divider(height: 24),
                        FutureBuilder<String>(
                          future: _getCategoryName(item.categoryId),
                          builder: (_, snap) =>
                              _field(context, 'Category', snap.data ?? '...'),
                        ),
                        _field(
                          context,
                          'Available',
                          item.isAvailable ? 'Yes' : 'No',
                        ),
                        _field(
                          context,
                          'Featured',
                          item.isFeatured ? 'Yes' : 'No',
                        ),
                        _field(
                          context,
                          'New Product',
                          item.isNew ? 'Yes' : 'No',
                        ),
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
                ),

                // ── Inventory Card ──
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inventory',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Divider(height: 24),
                        _field(
                          context,
                          'Batch Number',
                          item.batchNumber ?? '—',
                        ),
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
                ),
                const SizedBox(height: 80), // FAB clearance
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(
    BuildContext context,
    ProductEntity item,
    ProductStatus statusEnum,
  ) {
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
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
