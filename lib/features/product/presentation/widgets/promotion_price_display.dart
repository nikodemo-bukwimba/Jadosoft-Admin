// lib/features/product/presentation/widgets/promotion_price_display.dart
//
// Promotion-aware price widget used in product cards, list rows, and
// the detail page.
//
// USAGE
// ─────────────────────────────────────────────────────────────
//   PromotionPriceDisplay(
//     product: item,
//     formatPrice: (v) => 'TZS ${v.toStringAsFixed(0)}',
//   )
//
// BEHAVIOR
// ─────────────────────────────────────────────────────────────
//   • No promotion  → shows price normally (same as before).
//   • Active promo  → shows effectivePrice prominently, original
//                     price struck through, discount badge.
//   • base_price is NEVER mutated — always reads from entity.price.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../domain/entities/product_entity.dart';

class PromotionPriceDisplay extends StatelessWidget {
  final ProductEntity product;
  final String Function(double) formatPrice;

  /// Compact: single-line layout — price + struck-through original.
  /// Non-compact: stacked layout for cards/detail.
  final bool compact;

  const PromotionPriceDisplay({
    super.key,
    required this.product,
    required this.formatPrice,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!product.isOnPromotion) {
      // ── No promotion — render exactly as before ──────────────
      return Text(
        formatPrice(product.price),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return compact
        ? _CompactPriceDisplay(product: product, formatPrice: formatPrice)
        : _FullPriceDisplay(product: product, formatPrice: formatPrice);
  }
}

// ─── Compact: used in list rows and table rows ─────────────────────────────

class _CompactPriceDisplay extends StatelessWidget {
  final ProductEntity product;
  final String Function(double) formatPrice;

  const _CompactPriceDisplay({
    required this.product,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          formatPrice(product.displayPrice),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.deepOrange,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          formatPrice(product.price),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            decoration: TextDecoration.lineThrough,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ─── Full: used in cards and detail page ──────────────────────────────────

class _FullPriceDisplay extends StatelessWidget {
  final ProductEntity product;
  final String Function(double) formatPrice;

  const _FullPriceDisplay({required this.product, required this.formatPrice});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Effective price — prominently displayed
        Text(
          formatPrice(product.displayPrice),
          style: textTheme.titleSmall?.copyWith(
            color: Colors.deepOrange,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Original price struck-through
            Text(
              formatPrice(product.price),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 6),
            // Discount badge
            if (product.discountPercentage != null)
              PromotionDiscountBadge(percentage: product.discountPercentage!),
          ],
        ),
      ],
    );
  }
}

// ─── Standalone Discount Badge ─────────────────────────────────────────────

/// Orange discount badge: "20% OFF".
/// Can be used independently in any product widget.
class PromotionDiscountBadge extends StatelessWidget {
  final double percentage;
  final bool large;

  const PromotionDiscountBadge({
    super.key,
    required this.percentage,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = _formatLabel(percentage);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 8 : 5,
        vertical: large ? 3 : 1,
      ),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(large ? 6 : 4),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$label OFF',
        style: TextStyle(
          fontSize: large ? 12 : 9,
          color: Colors.deepOrange,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _formatLabel(double v) {
    // Show "20%" for whole numbers, "20.5%" for decimals
    return v % 1 == 0 ? '${v.toInt()}%' : '${v.toStringAsFixed(1)}%';
  }
}

// ─── Promotion Corner Tag ──────────────────────────────────────────────────
//
// Overlay tag for product image corners in cards/grid views.
// Usage:
//   Stack(
//     children: [
//       ProductImage(...),
//       if (item.isOnPromotion)
//         Positioned(
//           top: 6, left: 6,
//           child: PromotionCornerTag(
//             percentage: item.discountPercentage!,
//           ),
//         ),
//     ],
//   )

class PromotionCornerTag extends StatelessWidget {
  final double percentage;

  const PromotionCornerTag({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    final label = percentage % 1 == 0
        ? '${percentage.toInt()}%'
        : '${percentage.toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.deepOrange,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '-$label',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
