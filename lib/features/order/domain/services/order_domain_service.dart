import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';
import '../guards/order_transition_guard.dart';
import '../repositories/order_repository.dart';
import '../value_objects/order_status.dart';

class OrderDomainService {
  final OrderRepository repository;
  final OrderTransitionGuard guard;

  OrderDomainService({required this.repository, required this.guard});

  Future<Either<Failure, OrderEntity>> transition({
    required String id,
    required OrderStatus targetStatus,
  }) async {
    switch (targetStatus) {
      case OrderStatus.confirmed:
        return repository.confirm(id);
      case OrderStatus.shipped:
        return repository.ship(id);
      case OrderStatus.delivered:
        return repository.deliver(id);
      case OrderStatus.cancelled:
        return repository.cancel(id);
      default:
        return const Left(ValidationFailure('Transition not supported'));
    }
  }
}