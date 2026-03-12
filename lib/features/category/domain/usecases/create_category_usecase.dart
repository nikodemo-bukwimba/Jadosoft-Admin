import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class CreateCategoryParams {
  final String name;
  final String? description;
  final bool isActive;

  const CreateCategoryParams({
    required this.name,
    this.description,
    required this.isActive,
  });
}

class CreateCategoryUseCase implements UseCase<CategoryEntity, CreateCategoryParams> {
  final CategoryRepository repository;
  CreateCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, CategoryEntity>> call(CreateCategoryParams p) async {
    // -- Validation gate --
    if (p.name.trim().isEmpty) {
      return Left(ValidationFailure('Category name is required'));
    }
    if (p.name.length < 2) {
      return Left(ValidationFailure('Name must be at least 2 characters'));
    }

    return repository.create(
      CategoryEntity(
        id: '',
        name: p.name.trim(),
        description: p.description?.trim(),
        isActive: p.isActive,
      ),
    );
  }
}
