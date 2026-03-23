import 'package:flutter/material.dart';

import '../../domain/entities/product_entity.dart';
import 'product_image.dart';
import 'product_status_badge.dart';

/// Reusable product card widget.
///
/// Standard card display used as the default representation and by
/// other features that reference products (e.g. promotions, orders).
class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showImage;
  final bool compact;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onLongPress,
    this.showImage = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 14),
          child: Row(
            children: [
              if (showImage) ...[
                ProductImage(
                  product: product,
                  width: compact ? 48 : 56,
                  height: compact ? 48 : 56,
                  borderRadius: BorderRadius.circular(8),
                  showOverlayTags: false,
                ),
                SizedBox(width: compact ? 10 : 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: (compact
                                    ? textTheme.bodyMedium
                                    : textTheme.titleSmall)
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ProductStatusBadge(
                          status: product.status,
                          fontSize: compact ? 9 : 11,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          product.formattedPrice,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                        if (product.categoryName != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· ${product.categoryName}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Overlay tags as inline chips
                    if (product.overlayTags.isNotEmpty && !compact) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: product.overlayTags.map((tag) {
                          return _InlineTag(tag: tag);
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineTag extends StatelessWidget {
  final String tag;

  const _InlineTag({required this.tag});

  Color get _color {
    switch (tag) {
      case 'NEW':
        return Colors.green;
      case 'FEATURED':
        return Colors.amber.shade700;
      case 'UNAVAILABLE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: _color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
