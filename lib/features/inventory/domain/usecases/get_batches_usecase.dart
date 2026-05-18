// lib/features/inventory/domain/usecases/get_batches_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/inventory_entity.dart';
import '../repositories/inventory_repository.dart';

class GetBatchesParams {
  final String orgId;
  final String? warehouseId;
  final String? productId;
  final String? variantId;
  final String? status;
  const GetBatchesParams({
    required this.orgId,
    this.warehouseId,
    this.productId,
    this.variantId,
    this.status,
  });
}

class GetBatchesUseCase
    implements UseCase<List<InventoryBatchEntity>, GetBatchesParams> {
  final InventoryRepository repository;
  const GetBatchesUseCase(this.repository);

  @override
  Future<Either<Failure, List<InventoryBatchEntity>>> call(
          GetBatchesParams p) =>
      repository.getBatches(
        p.orgId,
        warehouseId: p.warehouseId,
        productId: p.productId,
        variantId: p.variantId,
        status: p.status,
      );
}