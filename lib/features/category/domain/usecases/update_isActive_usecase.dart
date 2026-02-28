// update_isActive_usecase.dart
// Validates the entity before updating.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class UpdateCategoryParams {
  final CategoryEntity entity;
  const UpdateCategoryParams({required this.entity});
}

class UpdateCategoryUseCase
    implements UseCase<CategoryEntity, UpdateCategoryParams> {
  final CategoryRepository repository;
  UpdateCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, CategoryEntity>> call(
    UpdateCategoryParams params,
  ) async {
    if (params.entity.id.isEmpty) {
      return const Left(
        ValidationFailure('Cannot update: entity ID is missing'),
      );
    }

    // TODO: Add domain-specific update validation here

    return repository.update(params.entity);
  }
}
