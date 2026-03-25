import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<OrderEntity>>> getAll();
  Future<Either<Failure, OrderEntity>>       getById(String id);
  Future<Either<Failure, OrderEntity>>       create(OrderEntity entity);
  Future<Either<Failure, OrderEntity>>       update(OrderEntity entity);
  Future<Either<Failure, void>>              delete(String id);
  Future<Either<Failure, OrderEntity>>       confirm(String id);
  Future<Either<Failure, OrderEntity>>       ship(String id);
  Future<Either<Failure, OrderEntity>>       deliver(String id);
  Future<Either<Failure, OrderEntity>>       cancel(String id);
}