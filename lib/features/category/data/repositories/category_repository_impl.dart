import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/paginated_response.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';
import '../datasources/category_remote_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _remote;
  CategoryRepositoryImpl({required CategoryRemoteDataSource remoteDataSource}) : _remote = remoteDataSource;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try { return Right(await call());
    } on AuthException catch (e) { return Left(AuthFailure(e.message));
    } on ServerException catch (e) { return Left(ServerFailure(e.message));
    } on NetworkException catch (e) { return Left(NetworkFailure(e.message));
    } catch (e) { return Left(GenericFailure(e.toString())); }
  }

  @override Future<Either<Failure, PaginatedResponse<CategoryEntity>>> getAll({String? search, int? perPage, int? page}) =>
    _guard(() => _remote.getAll(search: search, perPage: perPage, page: page));
  @override Future<Either<Failure, CategoryEntity>> getById(String id) => _guard(() => _remote.getById(id));
  @override Future<Either<Failure, CategoryEntity>> create(CategoryEntity entity) =>
    _guard(() => _remote.create(CategoryModel.fromEntity(entity).toJson()));
  @override Future<Either<Failure, CategoryEntity>> update(CategoryEntity entity) =>
    _guard(() => _remote.update(entity.id, CategoryModel.fromEntity(entity).toJson()));
  @override Future<Either<Failure, void>> delete(String id) => _guard(() => _remote.delete(id));
}
