// order_repository_impl.dart — Admin App
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  OrderRepositoryImpl({required OrderRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<OrderEntity>>> getAll({
    String? createdById,
  }) async {
    try {
      final result = await _remoteDataSource.getAll(createdById: createdById);
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
  Future<Either<Failure, OrderEntity>> getById(String id) async {
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
  Future<Either<Failure, OrderEntity>> create(OrderEntity entity) async {
    try {
      // final model = OrderModel.fromEntity(entity);
      final data = <String, dynamic>{
        'customer_id': entity.customerId,
        'items': entity.items,
        if (entity.paymentRef != null) 'payment_ref': entity.paymentRef,
        if (entity.createdByName != null)
          'created_by_name': entity.createdByName,
        if (entity.createdById != null) 'created_by_id': entity.createdById,
        'client_total': entity.total, // promotion-adjusted total
      };
      final result = await _remoteDataSource.create(data);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> update(OrderEntity entity) async {
    try {
      final result = await _remoteDataSource.update(entity.id, {});
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

  @override
  Future<Either<Failure, OrderEntity>> confirm(String id) async {
    try {
      final result = await _remoteDataSource.confirm(id);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> ship(String id) async {
    try {
      final result = await _remoteDataSource.ship(id);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> deliver(String id) async {
    try {
      final result = await _remoteDataSource.deliver(id);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> cancel(String id) async {
    try {
      final result = await _remoteDataSource.cancel(id);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> markPaid(
    String id,
    String actorId,
    String? paymentRef,
  ) async {
    try {
      final result = await _remoteDataSource.markPaid(id, actorId, paymentRef);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> transition({
    required String id,
    required String toStatus,
  }) async {
    return switch (toStatus) {
      'confirmed' => confirm(id),
      'shipped' => ship(id),
      'delivered' => deliver(id),
      'cancelled' => cancel(id),
      _ => Left(ValidationFailure('Unknown transition: $toStatus')),
    };
  }
}
