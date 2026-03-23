import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

/// Repository implementation that delegates to [ProductRemoteDatasource].
///
/// The [orgId] is injected at construction time from the authenticated
/// user's OrgContext (organization actor_id). It is used for list and
/// create endpoints that are scoped to an org.
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDatasource remoteDatasource;
  final String orgId;

  const ProductRepositoryImpl({
    required this.remoteDatasource,
    required this.orgId,
  });

  @override
  Future<Either<Failure, List<ProductEntity>>> getAll({
    int page = 1,
    int perPage = 25,
    String? status,
    String? type,
    String? search,
  }) async {
    try {
      final products = await remoteDatasource.getAll(
        orgId: orgId,
        page: page,
        perPage: perPage,
        status: status,
        type: type,
        search: search,
      );
      return Right(products);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getById(String id) async {
    try {
      final product = await remoteDatasource.getById(id);
      return Right(product);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> create(ProductEntity product) async {
    try {
      final model = ProductModel.fromEntity(product);
      final created = await remoteDatasource.create(
        orgId: orgId,
        product: model,
      );
      return Right(created);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> update(ProductEntity product) async {
    try {
      final model = ProductModel.fromEntity(product);
      final updated = await remoteDatasource.update(model);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await remoteDatasource.delete(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> publish(String id) async {
    try {
      final product = await remoteDatasource.publish(id);
      return Right(product);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> archive(String id) async {
    try {
      final product = await remoteDatasource.archive(id);
      return Right(product);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
