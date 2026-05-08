// lib/features/product/presentation/widgets/product_list_row.dart
import 'package:flutter/material.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/value_objects/product_status.dart';
import 'product_image.dart';
import 'product_status_badge.dart';
import 'promotion_price_display.dart';

/// List view row — dense, small thumbnail on the left.
class ProductListRow extends StatelessWidget {
  final ProductEntity item;
  final String Function(double) formatPrice;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProductListRow({
    super.key,
    required this.item,
    required this.formatPrice,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusEnum = ProductStatusX.fromString(item.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                // Thumbnail
                ProductImage(
                  imageUrl: item.imageUrl,
                  width: 44,
                  height: 44,
                  borderRadius: 8,
                ),
                const SizedBox(width: 12),
                // Name + price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isNew) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                          // Promotion discount badge inline with name (NEW)
                          if (item.isOnPromotion &&
                              item.discountPercentage != null) ...[
                            const SizedBox(width: 6),
                            PromotionDiscountBadge(
                              percentage: item.discountPercentage!,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Compact promotion-aware price (NEW)
                      PromotionPriceDisplay(
                        product: item,
                        formatPrice: formatPrice,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                // Status
                ProductStatusBadge(status: statusEnum, compact: true),
                const SizedBox(width: 4),
                // Delete
                SizedBox(
                  width: 36,
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: scheme.error,
                      size: 18,
                    ),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
