// order_repository.dart — Admin App
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';

abstract class OrderRepository {
  /// [createdById] — when non-null, filters orders placed by that actor.
  Future<Either<Failure, List<OrderEntity>>> getAll({String? createdById});
  Future<Either<Failure, OrderEntity>> getById(String id);
  Future<Either<Failure, OrderEntity>> create(OrderEntity entity);
  Future<Either<Failure, OrderEntity>> update(OrderEntity entity);
  Future<Either<Failure, void>> delete(String id);
  Future<Either<Failure, OrderEntity>> confirm(String id);
  Future<Either<Failure, OrderEntity>> ship(String id);
  Future<Either<Failure, OrderEntity>> deliver(String id);
  Future<Either<Failure, OrderEntity>> cancel(String id);
  Future<Either<Failure, OrderEntity>> markPaid(
    String id,
    String actorId,
    String? paymentRef,
  );

  Future<Either<Failure, OrderEntity>> transition({
    required String id,
    required String toStatus,
  });
}
