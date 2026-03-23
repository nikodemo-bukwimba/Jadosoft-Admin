import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_mode.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/value_objects/product_status.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../widgets/product_image.dart';
import '../widgets/product_status_badge.dart';
import 'product_form_page.dart';

/// Product detail page with collapsing image app bar.
///
/// Features:
///   - SliverAppBar with product image that collapses on scroll
///   - Status transition buttons (Publish / Archive) based on guard
///   - Featured toggle (client-side boolean)
///   - NEW / FEATURED / UNAVAILABLE overlay tags
///   - Edit and delete actions
class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(ProductLoadOneRequested(widget.productId));
  }

  void _navigateToEdit(ProductEntity product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProductBloc>(),
          child: ProductFormPage(
            mode: FormMode.edit,
            product: product,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(ProductEntity product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<ProductBloc>()
                  .add(ProductDeleteRequested(product.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmTransition(
    ProductEntity product,
    String action,
    String description,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} Product'),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (action == 'publish') {
                context
                    .read<ProductBloc>()
                    .add(ProductPublishRequested(product));
              } else if (action == 'archive') {
                context
                    .read<ProductBloc>()
                    .add(ProductArchiveRequested(product));
              }
            },
            child: Text(action[0].toUpperCase() + action.substring(1)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          if (state.product != null) {
            // Reload detail with updated product
            context
                .read<ProductBloc>()
                .add(ProductLoadOneRequested(widget.productId));
          } else {
            // Deleted — go back
            Navigator.of(context).pop();
          }
        }
        if (state is ProductError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ProductDetailLoading ||
            state is ProductOperationInProgress) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is ProductDetailLoaded) {
          return _buildDetail(context, state.product);
        }
        if (state is ProductError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(state.message)),
          );
        }
        return Scaffold(appBar: AppBar());
      },
    );
  }

  Widget _buildDetail(BuildContext context, ProductEntity product) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Collapsing Image App Bar ──────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(
                    product: product,
                    borderRadius: BorderRadius.zero,
                    showOverlayTags: true,
                  ),
                  // Gradient overlay for readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                product.name,
                style: const TextStyle(fontSize: 16),
              ),
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => _navigateToEdit(product),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') _confirmDelete(product);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Content ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + Price row
                  Row(
                    children: [
                      ProductStatusBadge(status: product.status),
                      const SizedBox(width: 12),
                      Text(
                        product.formattedPrice,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      // Featured toggle
                      _FeaturedToggle(
                        isFeatured: product.isFeatured,
                        onToggle: () {
                          context.read<ProductBloc>().add(
                                ProductToggleFeaturedRequested(product),
                              );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info sections
                  _InfoSection(
                    children: [
                      _InfoRow('Type', product.type.label),
                      if (product.categoryName != null)
                        _InfoRow('Category', product.categoryName!),
                      if (product.sku != null)
                        _InfoRow('SKU', product.sku!),
                      _InfoRow('Currency', product.currency),
                      _InfoRow(
                        'Track Inventory',
                        product.trackInventory ? 'Yes' : 'No',
                      ),
                      _InfoRow(
                        'Requires Confirmation',
                        product.requiresConfirmation ? 'Yes' : 'No',
                      ),
                      _InfoRow(
                        'Available',
                        product.isAvailable ? 'Yes' : 'No',
                      ),
                    ],
                  ),

                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.description!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],

                  // Timestamps
                  if (product.createdAt != null ||
                      product.updatedAt != null) ...[
                    const SizedBox(height: 16),
                    _InfoSection(
                      children: [
                        if (product.createdAt != null)
                          _InfoRow(
                            'Created',
                            _formatDate(product.createdAt!),
                          ),
                        if (product.updatedAt != null)
                          _InfoRow(
                            'Updated',
                            _formatDate(product.updatedAt!),
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Status Transition Buttons ────────────────────
                  _TransitionButtons(
                    product: product,
                    onPublish: () => _confirmTransition(
                      product,
                      'publish',
                      'This will make the product visible to buyers. '
                          'At least one active variant is required.',
                    ),
                    onArchive: () => _confirmTransition(
                      product,
                      'archive',
                      'This will hide the product from buyers. '
                          'It can still be viewed in the admin panel.',
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Status Transition Buttons ──────────────────────────────────────────

class _TransitionButtons extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onPublish;
  final VoidCallback onArchive;

  const _TransitionButtons({
    required this.product,
    required this.onPublish,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttons = <Widget>[];

    if (product.canPublish) {
      buttons.add(
        FilledButton.icon(
          onPressed: onPublish,
          icon: const Icon(Icons.publish, size: 18),
          label: const Text('Publish'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(140, 44),
          ),
        ),
      );
    }

    if (product.canArchive) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: onArchive,
          icon: Icon(Icons.archive_outlined,
              size: 18, color: colorScheme.error),
          label: Text('Archive',
              style: TextStyle(color: colorScheme.error)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colorScheme.error),
            minimumSize: const Size(140, 44),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(
      children: buttons
          .expand((b) => [b, const SizedBox(width: 12)])
          .toList()
        ..removeLast(),
    );
  }
}

// ── Featured Toggle ────────────────────────────────────────────────────

class _FeaturedToggle extends StatelessWidget {
  final bool isFeatured;
  final VoidCallback onToggle;

  const _FeaturedToggle({
    required this.isFeatured,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFeatured ? Icons.star : Icons.star_border,
              size: 22,
              color: isFeatured ? Colors.amber.shade700 : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              isFeatured ? 'Featured' : 'Feature',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isFeatured ? Colors.amber.shade700 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Helpers ──────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final List<Widget> children;

  const _InfoSection({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children
            .expand((c) => [
                  c,
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
