import 'package:flutter/material.dart';

/// Product lifecycle statuses matching the Nexora Commerce API.
///
/// Status machine: draft → active → archived
/// Note: "featured" is a client-side boolean flag, NOT a status.
enum ProductStatus {
  draft,
  active,
  archived;

  String get label {
    switch (this) {
      case ProductStatus.draft:
        return 'Draft';
      case ProductStatus.active:
        return 'Active';
      case ProductStatus.archived:
        return 'Archived';
    }
  }

  Color get color {
    switch (this) {
      case ProductStatus.draft:
        return Colors.grey;
      case ProductStatus.active:
        return Colors.blue;
      case ProductStatus.archived:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ProductStatus.draft:
        return Icons.edit_outlined;
      case ProductStatus.active:
        return Icons.check_circle_outline;
      case ProductStatus.archived:
        return Icons.archive_outlined;
    }
  }

  static ProductStatus fromString(String value) {
    return ProductStatus.values.firstWhere(
      (s) => s.name == value.toLowerCase(),
      orElse: () => ProductStatus.draft,
    );
  }
}
