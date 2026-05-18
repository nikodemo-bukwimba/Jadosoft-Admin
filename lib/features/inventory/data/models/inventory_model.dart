// lib/features/inventory/data/models/inventory_model.dart

import '../../domain/entities/inventory_entity.dart';

class WarehouseModel extends WarehouseEntity {
  const WarehouseModel({
    required super.id,
    required super.orgId,
    required super.name,
    required super.type,
    required super.isActive,
    super.address,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> j) => WarehouseModel(
        id: j['id']?.toString() ?? '',
        orgId: j['org_id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        type: j['type']?.toString() ?? 'standard',
        isActive: j['is_active'] as bool? ?? j['status'] == 'active',
        address: j['address']?.toString(),
      );
}

class InventoryBatchModel extends InventoryBatchEntity {
  const InventoryBatchModel({
    required super.id,
    required super.warehouseId,
    required super.warehouseName,
    required super.productId,
    super.variantId,
    required super.orgId,
    super.batchNumber,
    super.sku,
    required super.quantityReceived,
    required super.quantityAvailable,
    required super.quantityReserved,
    required super.quantityDamaged,
    super.unitCost,
    required super.currency,
    required super.status,
    super.receivedAt,
    super.expiresAt,
    super.bestBeforeAt,
  });

  factory InventoryBatchModel.fromJson(Map<String, dynamic> j) {
    final warehouse = j['warehouse'] as Map<String, dynamic>?;
    return InventoryBatchModel(
      id: j['id']?.toString() ?? '',
      warehouseId: j['warehouse_id']?.toString() ?? '',
      warehouseName: warehouse?['name']?.toString() ?? '',
      productId: j['product_id']?.toString() ?? '',
      variantId: j['variant_id']?.toString(),
      orgId: j['org_id']?.toString() ?? '',
      batchNumber: j['batch_number']?.toString(),
      sku: j['sku']?.toString(),
      quantityReceived: _parseInt(j['quantity_received']),
      quantityAvailable: _parseInt(j['quantity_available']),
      quantityReserved: _parseInt(j['quantity_reserved']),
      quantityDamaged: _parseInt(j['quantity_damaged']),
      unitCost: j['unit_cost'] != null
          ? double.tryParse(j['unit_cost'].toString())
          : null,
      currency: j['currency']?.toString() ?? 'TZS',
      status: j['status']?.toString() ?? 'active',
      receivedAt: _parseDate(j['received_at']),
      expiresAt: _parseDate(j['expires_at']),
      bestBeforeAt: _parseDate(j['best_before_at']),
    );
  }

  static int _parseInt(dynamic v) =>
      v == null ? 0 : int.tryParse(v.toString()) ?? 0;

  static DateTime? _parseDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}

class VariantStockModel extends VariantStockEntity {
  const VariantStockModel({
    required super.variantId,
    required super.productId,
    required super.variantName,
    required super.totalStock,
    required super.batches,
  });

  factory VariantStockModel.fromJson(Map<String, dynamic> j) =>
      VariantStockModel(
        variantId: j['variant_id']?.toString() ?? '',
        productId: j['product_id']?.toString() ?? '',
        variantName: j['variant_name']?.toString() ?? '',
        totalStock: int.tryParse(j['total_stock']?.toString() ?? '0') ?? 0,
        batches: (j['batches'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(InventoryBatchModel.fromJson)
            .toList(),
      );
}