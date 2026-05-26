// lib/features/product/data/models/branch_variant_price_model.dart
//admin app

import '../../domain/entities/branch_variant_price_entity.dart';

class BranchVariantPriceModel extends BranchVariantPriceEntity {
  const BranchVariantPriceModel({
    required super.id,
    required super.orgId,
    required super.variantId,
    required super.price,
    required super.currency,
    super.variantBasePrice,
    super.variantName,
    super.productName,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BranchVariantPriceModel.fromJson(Map<String, dynamic> json) {
    // The override object may embed the variant object when loaded with relations.
    final variant = json['variant'] as Map<String, dynamic>?;
    final product = variant?['product'] as Map<String, dynamic>?;

    final rawPrice =
        json['price'] ?? json['base_price'] ?? json['override_price'] ?? 0;
    final price = double.tryParse(rawPrice.toString()) ?? 0.0;

    final rawBase = variant?['base_price'];
    final basePrice =
        rawBase != null ? double.tryParse(rawBase.toString()) : null;

    return BranchVariantPriceModel(
      id: json['id']?.toString() ?? '',
      orgId: json['org_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString() ?? '',
      price: price,
      currency: json['currency']?.toString() ?? 'TZS',
      variantBasePrice: basePrice,
      variantName: variant?['name']?.toString() ?? variant?['sku']?.toString(),
      productName: product?['name']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'org_id': orgId,
        'variant_id': variantId,
        'price': price,
        'currency': currency,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}