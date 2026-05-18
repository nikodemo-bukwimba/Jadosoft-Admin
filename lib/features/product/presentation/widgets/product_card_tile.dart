// lib/features/product/presentation/widgets/product_card_tile.dart
import 'package:flutter/material.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/value_objects/product_status.dart';
import 'product_image.dart';
import 'product_status_badge.dart';
import 'promotion_price_display.dart';

/// Cards view tile — full-width image banner with overlays.
class ProductCardTile extends StatelessWidget {
  final ProductEntity item;
  final String Function(double) formatPrice;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProductCardTile({
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image Banner ──
            Stack(
              children: [
                ProductImage(
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  height: 160,
                  borderRadius: 0,
                ),
                // Status badge — top left
                Positioned(
                  top: 10,
                  left: 10,
                  child: ProductStatusBadge(status: statusEnum),
                ),
                // NEW / FEATURED tags — top right
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: [
                      if (item.isNew) _tag('NEW', Colors.blue),
                      if (item.isFeatured) ...[
                        if (item.isNew) const SizedBox(width: 6),
                        _tag('FEATURED', Colors.amber.shade800),
                      ],
                    ],
                  ),
                ),
                // Promotion corner tag — bottom left (NEW)
                if (item.isOnPromotion)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: PromotionCornerTag(
                      percentage: item.discountPercentage!,
                    ),
                  ),
                // Unavailable overlay
                if (!item.isAvailable)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'UNAVAILABLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // ── Content ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (item.description != null &&
                            item.description!.isNotEmpty)
                          Text(
                            item.description!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 6),
                        // Promotion-aware price (NEW — replaces plain Text)
                        PromotionPriceDisplay(
                          product: item,
                          formatPrice: formatPrice,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: scheme.error,
                      size: 20,
                    ),
                    tooltip: 'Delete',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
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
