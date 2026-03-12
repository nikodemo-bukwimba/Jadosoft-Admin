import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl({
    required ProductRemoteDataSource remoteDataSource,
  })  :         _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<ProductEntity>>> getAll() async {
    try {
      final result = await _remoteDataSource.getAll();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getById(String id) async {
    try {
      final result = await _remoteDataSource.getById(id);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> create(ProductEntity entity) async {
    try {
      final model = ProductModel.fromEntity(entity);
      final result = await _remoteDataSource.create(model.toJson());
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> update(ProductEntity entity) async {
    try {
      final model = ProductModel.fromEntity(entity);
      final result = await _remoteDataSource.update(entity.id, model.toJson());
      return Right(result);
    } on ServerException catch (e) {
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
