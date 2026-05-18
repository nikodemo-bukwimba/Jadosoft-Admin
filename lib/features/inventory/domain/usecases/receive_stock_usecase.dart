// lib/features/inventory/domain/usecases/receive_stock_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/inventory_entity.dart';
import '../repositories/inventory_repository.dart';

class ReceiveStockParams {
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

  const ReceiveStockParams({
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

class ReceiveStockUseCase
    implements UseCase<InventoryBatchEntity, ReceiveStockParams> {
  final InventoryRepository repository;
  const ReceiveStockUseCase(this.repository);

  @override
  Future<Either<Failure, InventoryBatchEntity>> call(
      ReceiveStockParams p) {
    if (p.quantity < 1) {
      return Future.value(
          const Left(ValidationFailure('Quantity must be at least 1')));
    }
    return repository.receiveStock(p.warehouseId, {
      'product_id': p.productId,
      'variant_id': p.variantId,
      'org_id': p.orgId,
      'quantity': p.quantity,
      if (p.unitCost != null) 'unit_cost': p.unitCost,
      'currency': p.currency,
      if (p.batchNumber != null) 'batch_number': p.batchNumber,
      if (p.sku != null) 'sku': p.sku,
      if (p.expiresAt != null) 'expires_at': p.expiresAt!.toIso8601String(),
      if (p.bestBeforeAt != null)
        'best_before_at': p.bestBeforeAt!.toIso8601String(),
    });
  }
}