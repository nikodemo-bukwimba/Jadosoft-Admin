// lib/features/inventory/data/repositories/inventory_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/inventory_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;

  InventoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<WarehouseEntity>>> getWarehouses(
      String orgId) async {
    try {
      final result = await remoteDataSource.getWarehouses(orgId);
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
  Future<Either<Failure, WarehouseEntity>> createWarehouse(
      String orgId, Map<String, dynamic> data) async {
    try {
      final result = await remoteDataSource.createWarehouse(orgId, data);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InventoryBatchEntity>>> getBatches(
    String orgId, {
    String? warehouseId,
    String? productId,
    String? variantId,
    String? status,
  }) async {
    try {
      final result = await remoteDataSource.getBatches(
        orgId,
        warehouseId: warehouseId,
        productId: productId,
        variantId: variantId,
        status: status,
      );
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
  Future<Either<Failure, InventoryBatchEntity>> receiveStock(
      String warehouseId, Map<String, dynamic> data) async {
    try {
      final result = await remoteDataSource.receiveStock(warehouseId, data);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VariantStockEntity>> getVariantStock(
      String orgId, String variantId) async {
    try {
      final result =
          await remoteDataSource.getVariantStock(orgId, variantId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }
}