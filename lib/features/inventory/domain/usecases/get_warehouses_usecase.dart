// lib/features/inventory/domain/usecases/get_warehouses_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/inventory_entity.dart';
import '../repositories/inventory_repository.dart';

class GetWarehousesParams {
  final String orgId;
  const GetWarehousesParams({required this.orgId});
}

class GetWarehousesUseCase
    implements UseCase<List<WarehouseEntity>, GetWarehousesParams> {
  final InventoryRepository repository;
  const GetWarehousesUseCase(this.repository);

  @override
  Future<Either<Failure, List<WarehouseEntity>>> call(
          GetWarehousesParams p) =>
      repository.getWarehouses(p.orgId);
}