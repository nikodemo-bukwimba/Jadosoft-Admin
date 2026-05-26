// lib/features/product/domain/entities/branch_variant_price_entity.dart

import 'package:equatable/equatable.dart';

/// Represents a branch-level price override for a single product variant.
///
/// When a branch sets an override, [branchPrice] is used as the base
/// before any promotion discount is applied — instead of the root
/// [variantBasePrice].
class BranchVariantPriceEntity extends Equatable {
  final String id;
  final String orgId;
  final String variantId;

  /// The branch-specific base price (≥ variantBasePrice).
  final double price;
  final String currency;

  /// Root-level base price — for display comparison only.
  final double? variantBasePrice;

  /// Snapshot of the product/variant name for list display.
  final String? variantName;
  final String? productName;

  final DateTime createdAt;
  final DateTime updatedAt;

  const BranchVariantPriceEntity({
    required this.id,
    required this.orgId,
    required this.variantId,
    required this.price,
    required this.currency,
    this.variantBasePrice,
    this.variantName,
    this.productName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The mark-up above root base price, as a percentage.
  double? get markupPercentage {
    if (variantBasePrice == null || variantBasePrice == 0) return null;
    return ((price - variantBasePrice!) / variantBasePrice!) * 100;
  }

  /// True when the branch price exceeds the root base price.
  bool get hasMarkup =>
      variantBasePrice != null && price > variantBasePrice!;

  @override
  List<Object?> get props => [
        id,
        orgId,
        variantId,
        price,
        currency,
        variantBasePrice,
        variantName,
        productName,
        createdAt,
        updatedAt,
      ];
}