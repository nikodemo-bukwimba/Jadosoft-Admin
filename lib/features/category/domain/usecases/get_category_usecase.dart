// get_category_usecase.dart
// Fetches a single record by ID.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class GetCategoryParams {
  final String id;
  const GetCategoryParams({required this.id});
}

class GetCategoryUseCase
    implements UseCase<CategoryEntity, GetCategoryParams> {

  final CategoryRepository repository;
  GetCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, CategoryEntity>> call(
      GetCategoryParams params) {
    if (params.id.isEmpty) {
      return Future.value(const Left(ValidationFailure('ID is required')));
    }
    return repository.getById(params.id);
  }
}
