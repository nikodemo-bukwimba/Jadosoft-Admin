// lib/features/inventory/domain/usecases/create_warehouse_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/inventory_entity.dart';
import '../repositories/inventory_repository.dart';

class CreateWarehouseParams {
  final String orgId;
  final String name;
  final String type;
  const CreateWarehouseParams({
    required this.orgId,
    required this.name,
    required this.type,
  });
}

class CreateWarehouseUseCase
    implements UseCase<WarehouseEntity, CreateWarehouseParams> {
  final InventoryRepository repository;
  const CreateWarehouseUseCase(this.repository);

  @override
  Future<Either<Failure, WarehouseEntity>> call(CreateWarehouseParams p) {
    if (p.name.trim().isEmpty) {
      return Future.value(
          const Left(ValidationFailure('Warehouse name is required')));
    }
    return repository.createWarehouse(
        p.orgId, {'name': p.name.trim(), 'type': p.type});
  }
}