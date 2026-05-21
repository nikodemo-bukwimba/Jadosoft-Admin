// lib/features/report_export/domain/models/product_export_row.dart
//
// Immutable DTO built from ProductEntity.
// Both PDF and Excel generators consume this — no generator touches
// a raw ProductEntity or calls any UseCase.
// ─────────────────────────────────────────────────────────────────

class ProductExportRow {
  final int no;
  final String name;
  final String description;
  final String packSize;
  final double packPrice; // effectivePrice (promotion-aware)
  final int quantityAvailable;

  const ProductExportRow({
    required this.no,
    required this.name,
    required this.description,
    required this.packSize,
    required this.packPrice,
    required this.quantityAvailable,
  });
}