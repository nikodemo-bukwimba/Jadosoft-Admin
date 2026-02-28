// create_isActive_usecase.dart
// The validation gate — ALL domain validation runs here.
// Never bypass this use case to call the repository directly.

import 'package:dartz/dartz.dart';
import 'package:fca/features/category/domain/repositories/category_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
 

class CreateCategoryParams {
  final String name;
  final bool isActive;

  const CreateCategoryParams({
    required this.name,
    required this.isActive,  });
}

class CreateCategoryUseCase
    implements UseCase<CategoryEntity, CreateCategoryParams> {

  final CategoryRepository repository;
  CreateCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, CategoryEntity>> call(
      CreateCategoryParams params) async {

    // ── Validation gate ──────────────────────────────────────
    if (params.name.trim().isEmpty) {
      return Left(ValidationFailure('Name is required'));
    }
    if (params.name.length < 2) {
      return Left(ValidationFailure('Name too short'));
    }

    // ── Build and persist ────────────────────────────────────
    return repository.create(
      CategoryEntity(
      id: '',
      name: params.name,
      isActive: params.isActive,      ),
    );
  }
}
