import 'package:flutter/material.dart';

import '../../domain/entities/product_entity.dart';
import 'product_image.dart';
import 'product_status_badge.dart';

/// Wide card layout for [ProductViewMode.card].
///
/// Horizontal layout: image on the left, product info on the right.
/// Shows name, description, price, category, status badge, overlay tags.
class ProductCardTile extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onTap;

  const ProductCardTile({
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              // Image
              SizedBox(
                width: 120,
                child: ProductImage(
                  product: product,
                  borderRadius: BorderRadius.zero,
                  showOverlayTags: true,
                ),
              ),

              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ProductStatusBadge(status: product.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (product.description != null &&
                          product.description!.isNotEmpty)
                        Text(
                          product.description!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            product.formattedPrice,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                          if (product.categoryName != null) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.categoryName!,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                          if (product.sku != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              product.sku!,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.6),
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
      ),
    );
  }
}
