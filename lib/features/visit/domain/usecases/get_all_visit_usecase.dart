// get_all_visit_usecase.dart
// Fetches a list of records with optional filtering, sorting, pagination.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/visit_repository.dart';

class GetAllVisitParams {
  final VisitFilterParams?     filters;
  final VisitSortParams?       sort;
  final VisitPaginationParams? pagination;

  const GetAllVisitParams({
    this.filters,
    this.sort,
    this.pagination,
  });
}

class GetAllVisitUseCase
    implements UseCase<List<CategoryEntity>, GetAllVisitParams> {

  final VisitRepository repository;
  GetAllVisitUseCase(this.repository);

  @override
  Future<Either<Failure, List<CategoryEntity>>> call(
      GetAllVisitParams params) =>
      repository.getAll(
        filters:    params.filters,
        sort:       params.sort,
        pagination: params.pagination,
      );
}
