// category_repository.dart
// Abstract repository interface.
// Domain depends on this contract. Never on the implementation.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category_entity.dart';

abstract class CategoryRepository {

  // ── Core CRUD ───────────────────────────────────────────────
  Future<Either<Failure, List<CategoryEntity>>> getAll({
    CategoryFilterParams?     filters,
    CategorySortParams?       sort,
    CategoryPaginationParams? pagination,
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

class CategoryFilterParams {
  // TODO: Add one typed field per entry declared in entities.api.filterable
  const CategoryFilterParams();

  Map<String, dynamic> toQueryMap() {
    return const {};
  }
}

class CategorySortParams {

  final String field;
  final bool   descending;

  const CategorySortParams({
    required this.field,
    this.descending = false,
  });

  String get queryValue => descending ? '-$field' : field;
}

class CategoryPaginationParams {
  final int page;
  final int perPage;

  const CategoryPaginationParams({
    this.page    = 1,
    this.perPage = 20,
  });
}


