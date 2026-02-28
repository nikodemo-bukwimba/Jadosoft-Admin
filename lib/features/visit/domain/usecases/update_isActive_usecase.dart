// update_isActive_usecase.dart
// Validates the entity before updating.

import 'package:dartz/dartz.dart';
import 'package:fca/features/visit/domain/repositories/visit_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';

class UpdateVisitParams {
  final CategoryEntity entity;
  const UpdateVisitParams({required this.entity});
}

class UpdateVisitUseCase
    implements UseCase<CategoryEntity, UpdateVisitParams> {

  final VisitRepository repository;
  UpdateVisitUseCase(this.repository);

  @override
  Future<Either<Failure, CategoryEntity>> call(
      UpdateVisitParams params) async {

    if (params.entity.id.isEmpty) {
      return const Left(ValidationFailure('Cannot update: entity ID is missing'));
    }

    // TODO: Add domain-specific update validation here

    return repository.update(params.entity);
  }
}
