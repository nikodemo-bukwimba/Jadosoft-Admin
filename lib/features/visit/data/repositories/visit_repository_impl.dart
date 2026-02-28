// visit_repository_impl.dart
// Strategy: remote only

import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/visit_repository.dart';
import '../datasources/visit_remote_datasource.dart';
import '../models/category_model.dart';

class VisitRepositoryImpl implements VisitRepository {
  final VisitRemoteDataSource _remoteDataSource;

  VisitRepositoryImpl({
    required VisitRemoteDataSource remoteDataSource,
  }) :
       _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<CategoryEntity>>> getAll({
    VisitFilterParams?     filters,
    VisitSortParams?       sort,
    VisitPaginationParams? pagination,
  }) async {
    try {
      final result = await _remoteDataSource.getAll(filters: filters);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }  }

  @override
  Future<Either<Failure, CategoryEntity>> getById(String id) async {
    try {
      final result = await _remoteDataSource.getById(id);
      return Right(result);    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CategoryEntity>> create(
      CategoryEntity entity) async {
    try {
      final model  = CategoryModel.fromEntity(entity);
      final result = await _remoteDataSource.create(model.toJson());
      return Right(result);    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CategoryEntity>> update(
      CategoryEntity entity) async {
    try {
      final model  = CategoryModel.fromEntity(entity);
      final result = await _remoteDataSource.update(entity.id, model.toJson());
      return Right(result);    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await _remoteDataSource.delete(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }
}
