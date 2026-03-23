import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/paginated_response.dart';
import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Future<Either<Failure, PaginatedResponse<CategoryEntity>>> getAll({String? search, int? perPage, int? page});
  Future<Either<Failure, CategoryEntity>> getById(String id);
  Future<Either<Failure, CategoryEntity>> create(CategoryEntity entity);
  Future<Either<Failure, CategoryEntity>> update(CategoryEntity entity);
  Future<Either<Failure, void>> delete(String id);
}
