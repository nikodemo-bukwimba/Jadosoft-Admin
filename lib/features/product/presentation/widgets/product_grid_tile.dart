// lib/features/product/presentation/widgets/product_grid_tile.dart
import 'package:flutter/material.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/value_objects/product_status.dart';
import 'product_image.dart';
import 'product_status_badge.dart';
import 'promotion_price_display.dart';

/// Grid view tile — compact thumbnail with name, price, status.
class ProductGridTile extends StatelessWidget {
  final ProductEntity item;
  final String Function(double) formatPrice;
  final VoidCallback onTap;

  const ProductGridTile({
    super.key,
    required this.item,
    required this.formatPrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusEnum = ProductStatusX.fromString(item.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ──
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(
                    imageUrl: item.imageUrl,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                  ),
                  if (!item.isAvailable)
                    Container(color: Colors.black.withValues(alpha: 0.4)),
                  // N / F mini badges — top right
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.isNew) _miniTag('N', Colors.blue),
                        if (item.isFeatured)
                          _miniTag('F', Colors.amber.shade800),
                      ],
                    ),
                  ),
                  // Promotion corner tag — top left (NEW)
                  if (item.isOnPromotion)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: PromotionCornerTag(
                        percentage: item.discountPercentage!,
                      ),
                    ),
                ],
              ),
            ),
            // ── Info ──
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          // Promotion-aware price (NEW — replaces plain Text)
                          child: PromotionPriceDisplay(
                            product: item,
                            formatPrice: formatPrice,
                          ),
                        ),
                        ProductStatusBadge(status: statusEnum, compact: true),
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

  Widget _miniTag(String letter, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 3),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
