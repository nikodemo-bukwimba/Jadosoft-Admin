// lib/features/inventory/domain/repositories/inventory_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/inventory_entity.dart';

abstract class InventoryRepository {
  Future<Either<Failure, List<WarehouseEntity>>> getWarehouses(String orgId);
  Future<Either<Failure, WarehouseEntity>> createWarehouse(
      String orgId, Map<String, dynamic> data);
  Future<Either<Failure, List<InventoryBatchEntity>>> getBatches(
    String orgId, {
    String? warehouseId,
    String? productId,
    String? variantId,
    String? status,
  });
  Future<Either<Failure, InventoryBatchEntity>> receiveStock(
      String warehouseId, Map<String, dynamic> data);
  Future<Either<Failure, VariantStockEntity>> getVariantStock(
      String orgId, String variantId);
}