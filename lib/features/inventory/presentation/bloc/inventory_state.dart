// lib/features/inventory/presentation/bloc/inventory_state.dart

import '../../domain/entities/inventory_entity.dart';

abstract class InventoryState {}

class InventoryLoaded extends InventoryState {
  final bool loading;

  final List<WarehouseEntity> warehouses;
  final List<InventoryBatchEntity> batches;

  final VariantStockEntity? variantStock;

  final WarehouseEntity? createdWarehouse;
  final InventoryBatchEntity? receivedBatch;

  final String? successMessage;
  final String? errorMessage;

  InventoryLoaded({
    this.loading = false,
    this.warehouses = const [],
    this.batches = const [],
    this.variantStock,
    this.createdWarehouse,
    this.receivedBatch,
    this.successMessage,
    this.errorMessage,
  });

  InventoryLoaded copyWith({
    bool? loading,
    List<WarehouseEntity>? warehouses,
    List<InventoryBatchEntity>? batches,
    VariantStockEntity? variantStock,
    WarehouseEntity? createdWarehouse,
    InventoryBatchEntity? receivedBatch,
    String? successMessage,
    String? errorMessage,
  }) {
    return InventoryLoaded(
      loading: loading ?? this.loading,
      warehouses: warehouses ?? this.warehouses,
      batches: batches ?? this.batches,
      variantStock: variantStock ?? this.variantStock,
      createdWarehouse: createdWarehouse ?? this.createdWarehouse,
      receivedBatch: receivedBatch ?? this.receivedBatch,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}