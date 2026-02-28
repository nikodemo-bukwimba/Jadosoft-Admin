// visit_repository.dart
// Abstract repository interface.
// Domain depends on this contract. Never on the implementation.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category_entity.dart';

abstract class VisitRepository {

  // ── Core CRUD ───────────────────────────────────────────────
  Future<Either<Failure, List<CategoryEntity>>> getAll({
    VisitFilterParams?     filters,
    VisitSortParams?       sort,
    VisitPaginationParams? pagination,
  });

  Future<Either<Failure, CategoryEntity>> getById(String id);

  Future<Either<Failure, CategoryEntity>> create(
      CategoryEntity entity);

  Future<Either<Failure, CategoryEntity>> update(
      CategoryEntity entity);

  Future<Either<Failure, void>> delete(String id);


  // TODO: Add domain-specific repository methods below
}

// ══════════════════════════════════════════════════════════════
//  DOMAIN QUERY PARAMETER OBJECTS
// ══════════════════════════════════════════════════════════════

class VisitFilterParams {
  // TODO: Add one typed field per entry declared in entities.api.filterable
  const VisitFilterParams();

  Map<String, dynamic> toQueryMap() {
    return const {};
  }
}

class VisitSortParams {

  final String field;
  final bool   descending;

  const VisitSortParams({
    required this.field,
    this.descending = false,
  });

  String get queryValue => descending ? '-$field' : field;
}

class VisitPaginationParams {
  final int page;
  final int perPage;

  const VisitPaginationParams({
    this.page    = 1,
    this.perPage = 20,
  });
}


