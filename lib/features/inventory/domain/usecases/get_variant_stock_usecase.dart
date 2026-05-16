// lib/features/inventory/domain/usecases/get_variant_stock_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/inventory_entity.dart';
import '../repositories/inventory_repository.dart';

class GetVariantStockParams {
  final String orgId;
  final String variantId;
  const GetVariantStockParams({required this.orgId, required this.variantId});
}

class GetVariantStockUseCase
    implements UseCase<VariantStockEntity, GetVariantStockParams> {
  final InventoryRepository repository;
  const GetVariantStockUseCase(this.repository);

  @override
  Future<Either<Failure, VariantStockEntity>> call(
          GetVariantStockParams p) =>
      repository.getVariantStock(p.orgId, p.variantId);
}