// lib/features/inventory/presentation/bloc/inventory_event.dart

abstract class InventoryEvent {}

class InventoryWarehousesLoadRequested extends InventoryEvent {
  final String orgId;
  InventoryWarehousesLoadRequested(this.orgId);
}

class InventoryWarehouseCreateRequested extends InventoryEvent {
  final String orgId;
  final String name;
  final String type;
  InventoryWarehouseCreateRequested(this.orgId, this.name, this.type);
}

class InventoryBatchesLoadRequested extends InventoryEvent {
  final String orgId;
  final String? warehouseId;
  final String? productId;
  final String? variantId;
  final String? status;
  InventoryBatchesLoadRequested(
    this.orgId, {
    this.warehouseId,
    this.productId,
    this.variantId,
    this.status,
  });
}

class InventoryReceiveStockRequested extends InventoryEvent {
  final String warehouseId;
  final String productId;
  final String variantId;
  final String orgId;
  final int quantity;
  final double? unitCost;
  final String currency;
  final String? batchNumber;
  final String? sku;
  final DateTime? expiresAt;
  final DateTime? bestBeforeAt;

  InventoryReceiveStockRequested({
    required this.warehouseId,
    required this.productId,
    required this.variantId,
    required this.orgId,
    required this.quantity,
    this.unitCost,
    this.currency = 'TZS',
    this.batchNumber,
    this.sku,
    this.expiresAt,
    this.bestBeforeAt,
  });
}

class InventoryVariantStockLoadRequested extends InventoryEvent {
  final String orgId;
  final String variantId;
  InventoryVariantStockLoadRequested(this.orgId, this.variantId);
}

class InventoryFormReset extends InventoryEvent {}