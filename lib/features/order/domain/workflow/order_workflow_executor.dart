import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';
import '../events/order_domain_events.dart';

class OrderWorkflowExecutor {
  final List<OrderDomainEvent> _emittedEvents = [];

  List<OrderDomainEvent> get emittedEvents => List.unmodifiable(_emittedEvents);

  void clearEvents() => _emittedEvents.clear();

  /// Executes the full workflow for the given entity.
  /// Steps run in order; on failure, completed steps are rolled back.
  Future<Either<Failure, OrderEntity>> execute(OrderEntity entity) async {
    _emittedEvents.clear();
    final completedSteps = <String>[];
    var current = entity;
    Either<Failure, OrderEntity> result;

    // Step: Verify Payment via Mobile Money
    result = await _verifyPayment(current);
    if (result.isLeft()) {
      await _rollback(entity, completedSteps);
      return result;
    }
    current = result.getOrElse(() => current);
    completedSteps.add('verifyPayment');
    // Step: Notify Customer â€” Order Shipped
    result = await _notifyCustomerShipped(current);
    if (result.isLeft()) {
      await _rollback(entity, completedSteps);
      return result;
    }
    current = result.getOrElse(() => current);
    completedSteps.add('notifyCustomerShipped');
    // Step: Notify Customer â€” Order Delivered
    result = await _notifyCustomerDelivered(current);
    if (result.isLeft()) {
      await _rollback(entity, completedSteps);
      return result;
    }
    current = result.getOrElse(() => current);
    completedSteps.add('notifyCustomerDelivered');

    return Right(current);
  }

  /// Step: Verify Payment via Mobile Money
  Future<Either<Failure, OrderEntity>> _verifyPayment(OrderEntity entity) async {
    // -- HUMAN CUSTOMIZATION ZONE --
    // Implement: Verify Payment via Mobile Money
    // Return Right(entity) on success, Left(Failure) on failure.
    // -- END CUSTOMIZATION ZONE --
    return Right(entity);
  }
  /// Step: Notify Customer â€” Order Shipped
  Future<Either<Failure, OrderEntity>> _notifyCustomerShipped(OrderEntity entity) async {
    // -- HUMAN CUSTOMIZATION ZONE --
    // Implement: Notify Customer â€” Order Shipped
    // Return Right(entity) on success, Left(Failure) on failure.
    // -- END CUSTOMIZATION ZONE --
    return Right(entity);
  }
  /// Step: Notify Customer â€” Order Delivered
  Future<Either<Failure, OrderEntity>> _notifyCustomerDelivered(OrderEntity entity) async {
    // -- HUMAN CUSTOMIZATION ZONE --
    // Implement: Notify Customer â€” Order Delivered
    // Return Right(entity) on success, Left(Failure) on failure.
    // -- END CUSTOMIZATION ZONE --
    return Right(entity);
  }

  Future<void> _rollback(OrderEntity entity, List<String> completedSteps) async {
    for (final step in completedSteps.reversed) {
      switch (step) {
      case 'verifyPayment': break; // TODO: rollback Verify Payment via Mobile Money
      case 'notifyCustomerShipped': break; // TODO: rollback Notify Customer â€” Order Shipped
      case 'notifyCustomerDelivered': break; // TODO: rollback Notify Customer â€” Order Delivered
      }
    }
  }

  void _emit(OrderDomainEvent event) => _emittedEvents.add(event);
}
