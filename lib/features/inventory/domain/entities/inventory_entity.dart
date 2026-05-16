// lib/features/inventory/domain/entities/inventory_entity.dart

import 'package:equatable/equatable.dart';

class WarehouseEntity extends Equatable {
  final String id;
  final String orgId;
  final String name;
  final String type; // standard|cold|bonded|virtual
  final bool isActive;
  final String? address;

  const WarehouseEntity({
    required this.id,
    required this.orgId,
    required this.name,
    required this.type,
    required this.isActive,
    this.address,
  });

  @override
  List<Object?> get props => [id, orgId, name, type, isActive, address];
}

class InventoryBatchEntity extends Equatable {
  final String id;
  final String warehouseId;
  final String warehouseName;
  final String productId;
  final String? variantId;
  final String orgId;
  final String? batchNumber;
  final String? sku;
  final int quantityReceived;
  final int quantityAvailable;
  final int quantityReserved;
  final int quantityDamaged;
  final double? unitCost;
  final String currency;
  final String status;
  final DateTime? receivedAt;
  final DateTime? expiresAt;
  final DateTime? bestBeforeAt;

  const InventoryBatchEntity({
    required this.id,
    required this.warehouseId,
    required this.warehouseName,
    required this.productId,
    this.variantId,
    required this.orgId,
    this.batchNumber,
    this.sku,
    required this.quantityReceived,
    required this.quantityAvailable,
    required this.quantityReserved,
    required this.quantityDamaged,
    this.unitCost,
    required this.currency,
    required this.status,
    this.receivedAt,
    this.expiresAt,
    this.bestBeforeAt,
  });

  int get availableQuantity => quantityAvailable - quantityReserved;
  bool get isDepleted => quantityAvailable <= 0;
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isNearExpiry =>
      expiresAt != null &&
      !isExpired &&
      expiresAt!.isBefore(DateTime.now().add(const Duration(days: 30)));
  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [id, warehouseId, productId, variantId, orgId,
        batchNumber, sku, quantityAvailable, status, expiresAt];
}

class VariantStockEntity extends Equatable {
  final String variantId;
  final String productId;
  final String variantName;
  final int totalStock;
  final List<InventoryBatchEntity> batches;

  const VariantStockEntity({
    required this.variantId,
    required this.productId,
    required this.variantName,
    required this.totalStock,
    required this.batches,
  });

  @override
  List<Object?> get props => [variantId, productId, totalStock];
}