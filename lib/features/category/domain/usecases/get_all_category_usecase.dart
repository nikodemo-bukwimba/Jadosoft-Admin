// get_all_category_usecase.dart
// Fetches a list of records with optional filtering, sorting, pagination.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class GetAllCategoryParams {
  final CategoryFilterParams?     filters;
  final CategorySortParams?       sort;
  final CategoryPaginationParams? pagination;

  const GetAllCategoryParams({
    this.filters,
    this.sort,
    this.pagination,
  });
}

class GetAllCategoryUseCase
    implements UseCase<List<CategoryEntity>, GetAllCategoryParams> {

  final CategoryRepository repository;
  GetAllCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<CategoryEntity>>> call(
      GetAllCategoryParams params) =>
      repository.getAll(
        filters:    params.filters,
        sort:       params.sort,
        pagination: params.pagination,
      );
}
