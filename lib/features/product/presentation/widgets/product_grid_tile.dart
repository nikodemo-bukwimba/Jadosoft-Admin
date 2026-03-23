import 'package:flutter/material.dart';

import '../../domain/entities/product_entity.dart';
import 'product_image.dart';
import 'product_status_badge.dart';

/// Compact grid tile used in [ProductViewMode.grid].
///
/// Shows product image with overlay tags, name, price, and status badge.
class ProductGridTile extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onTap;

  const ProductGridTile({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: ProductImage(
                product: product,
                borderRadius: BorderRadius.zero,
                showOverlayTags: true,
              ),
            ),

            // Info section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.formattedPrice,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        ProductStatusBadge(
                          status: product.status,
                          fontSize: 10,
                        ),
                        if (product.categoryName != null) ...[
                          const Spacer(),
                          Flexible(
                            child: Text(
                              product.categoryName!,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
