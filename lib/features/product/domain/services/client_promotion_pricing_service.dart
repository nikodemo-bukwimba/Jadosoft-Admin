// lib/features/product/domain/services/client_promotion_pricing_service.dart
//
// Pure-Dart mirror of the backend PromotionPricingService.
//
// PURPOSE
// ─────────────────────────────────────────────────────────────
// Primary path: the Nexora API already returns effective_price,
// discount_percentage, has_promotion, and promotion_id on each
// product variant when PromotionPricingService is active server-side.
// ProductApiDataSource._fromNexora() now reads these fields, so no
// client computation is needed for real API responses.
//
// This service handles TWO scenarios only:
//   1. Mock / offline mode — ProductMockDataSource returns products
//      with no promotion data; this service applies promotions locally.
//   2. Partial API responses — a product returned without effective_price
//      (e.g. an older endpoint version) gets a client-computed price.
//
// RULES (mirrors backend exactly)
// ─────────────────────────────────────────────────────────────
//   • A promotion is "active" when:
//       status == 'active'  (local, maps to Nexora sending|sent)
//       AND today >= startDate
//       AND today <= endDate
//       AND discountPercentage != null  (null = new-product campaign, no price change)
//   • Highest discount wins when multiple promotions cover the same product.
//   • base_price (ProductEntity.price) is NEVER mutated.
//   • effectivePrice = price × (1 – discountPercentage / 100), rounded to 2dp.
// ─────────────────────────────────────────────────────────────

import '../../domain/entities/product_entity.dart';
import '../../../promotion/domain/entities/promotion_entity.dart';

class ClientPromotionPricingService {
  const ClientPromotionPricingService();

  // ── Public API ─────────────────────────────────────────────

  /// Decorate a list of products with promotion pricing.
  ///
  /// Products that already carry server-supplied promotion data
  /// (`hasPromotion == true` OR `effectivePrice != price`) are skipped —
  /// server data is always trusted over client computation.
  ///
  /// Returns a new list; originals are never mutated.
  List<ProductEntity> decorateProducts(
    List<ProductEntity> products,
    List<PromotionEntity> allPromotions,
  ) {
    if (products.isEmpty) return products;

    final active = _activeDiscountPromotions(allPromotions);
    if (active.isEmpty) return products;

    // Build product-id → best discount index for O(n) lookup
    final bestDiscounts = _buildBestDiscountIndex(active);

    return products.map((product) {
      // Skip if server already decorated this product
      if (_isServerDecorated(product)) return product;

      final best = bestDiscounts[product.id];
      if (best == null) return product;

      final effectivePrice = _applyDiscount(
        product.price,
        best.discountPercentage!,
      );

      return product.copyWith(
        effectivePrice: effectivePrice,
        discountPercentage: best.discountPercentage,
        promotionId: best.id,
        hasPromotion: true,
      );
    }).toList();
  }

  /// Decorate a single product with the best active promotion.
  ///
  /// Returns the same object if server data is present or no promotion applies.
  ProductEntity decorateProduct(
    ProductEntity product,
    List<PromotionEntity> allPromotions,
  ) {
    if (_isServerDecorated(product)) return product;

    final active = _activeDiscountPromotions(allPromotions);
    if (active.isEmpty) return product;

    PromotionEntity? best;

    for (final promo in active) {
      if (!promo.productIds.contains(product.id)) continue;

      if (best == null ||
          (promo.discountPercentage! > best.discountPercentage!)) {
        best = promo;
      }
    }

    if (best == null) return product;

    return product.copyWith(
      effectivePrice: _applyDiscount(product.price, best.discountPercentage!),
      discountPercentage: best.discountPercentage,
      promotionId: best.id,
      hasPromotion: true,
    );
  }

  // ── Private helpers ────────────────────────────────────────

  /// Returns promotions that are within their active window and have a discount.
  List<PromotionEntity> _activeDiscountPromotions(List<PromotionEntity> all) {
    final today = DateTime.now();
    return all.where((p) {
      if (p.status != 'active') return false;
      if (p.discountPercentage == null) return false;
      if (today.isBefore(_dayStart(p.startDate))) return false;
      if (today.isAfter(_dayEnd(p.endDate))) return false;
      return true;
    }).toList();
  }

  /// Builds { productId → best promotion } map for batch decoration.
  Map<String, PromotionEntity> _buildBestDiscountIndex(
    List<PromotionEntity> active,
  ) {
    final index = <String, PromotionEntity>{};

    for (final promo in active) {
      for (final productId in promo.productIds) {
        final existing = index[productId];
        if (existing == null ||
            promo.discountPercentage! > existing.discountPercentage!) {
          index[productId] = promo;
        }
      }
    }

    return index;
  }

  /// True when the server has already computed promotion pricing.
  /// We trust the server: skip client computation entirely.
  bool _isServerDecorated(ProductEntity product) {
    return product.hasPromotion || product.effectivePrice < product.price;
  }

  double _applyDiscount(double basePrice, double percentage) {
    final discounted = basePrice * (1 - percentage / 100);
    return double.parse(discounted.toStringAsFixed(2));
  }

  /// Start of a calendar day for inclusive date comparison.
  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  /// End of a calendar day (23:59:59.999) for inclusive date comparison.
  DateTime _dayEnd(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
}
