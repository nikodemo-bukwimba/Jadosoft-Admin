import 'package:flutter/material.dart';

enum ProductStatus {
  draft,
  active,
  featured,
  archived,
}

extension ProductStatusX on ProductStatus {
  static const Map<ProductStatus, Set<ProductStatus>> _transitions = {
    ProductStatus.draft:    {ProductStatus.active},
    ProductStatus.active:   {ProductStatus.featured, ProductStatus.archived},
    ProductStatus.featured: {ProductStatus.active, ProductStatus.archived},
    ProductStatus.archived: {},
  };

  static const ProductStatus initial = ProductStatus.draft;

  bool canTransitionTo(ProductStatus target) =>
      _transitions[this]?.contains(target) ?? false;

  String get displayName => switch (this) {
    ProductStatus.draft    => 'Draft',
    ProductStatus.active   => 'Active',
    ProductStatus.featured => 'Featured',
    ProductStatus.archived => 'Archived',
  };

  Color get color => switch (this) {
    ProductStatus.draft    => Colors.grey,
    ProductStatus.active   => Colors.green,
    ProductStatus.featured => Colors.amber,
    ProductStatus.archived => Colors.blueGrey,
  };

  static ProductStatus fromString(String? value) =>
      ProductStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ProductStatus.draft,
      );
}