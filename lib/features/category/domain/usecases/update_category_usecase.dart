import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class UpdateCategoryParams {
  final CategoryEntity entity;
  const UpdateCategoryParams({required this.entity});
}

class UpdateCategoryUseCase implements UseCase<CategoryEntity, UpdateCategoryParams> {
  final CategoryRepository repository;
  UpdateCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, CategoryEntity>> call(UpdateCategoryParams p) async {
    return repository.update(p.entity);
  }
}
