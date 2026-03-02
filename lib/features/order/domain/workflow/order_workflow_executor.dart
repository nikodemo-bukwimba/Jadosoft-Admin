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

    // Step: Validate Inventory
    result = await _validateInventory(current);
    if (result.isLeft()) {
      await _rollback(entity, completedSteps);
      return result;
    }
    current = result.getOrElse(() => current);
    completedSteps.add('validateInventory');
    // Step: Process Payment
    result = await _processPayment(current);
    if (result.isLeft()) {
      await _rollback(entity, completedSteps);
      return result;
    }
    current = result.getOrElse(() => current);
    completedSteps.add('processPayment');
    // Step: Send Confirmation Email
    result = await _sendConfirmation(current);
    if (result.isLeft()) {
      await _rollback(entity, completedSteps);
      return result;
    }
    current = result.getOrElse(() => current);
    completedSteps.add('sendConfirmation');

    return Right(current);
  }

  /// Step: Validate Inventory
  Future<Either<Failure, OrderEntity>> _validateInventory(OrderEntity entity) async {
    // ── HUMAN CUSTOMIZATION ZONE ──────────────────────────
    // Implement: Validate Inventory
    // Return Right(entity) on success, Left(Failure) on failure.
    // ── END CUSTOMIZATION ZONE ────────────────────────────
    return Right(entity);
  }
  /// Step: Process Payment
  Future<Either<Failure, OrderEntity>> _processPayment(OrderEntity entity) async {
    // ── HUMAN CUSTOMIZATION ZONE ──────────────────────────
    // Implement: Process Payment
    // Return Right(entity) on success, Left(Failure) on failure.
    // ── END CUSTOMIZATION ZONE ────────────────────────────
    return Right(entity);
  }
  /// Step: Send Confirmation Email
  Future<Either<Failure, OrderEntity>> _sendConfirmation(OrderEntity entity) async {
    // ── HUMAN CUSTOMIZATION ZONE ──────────────────────────
    // Implement: Send Confirmation Email
    // Return Right(entity) on success, Left(Failure) on failure.
    // ── END CUSTOMIZATION ZONE ────────────────────────────
    return Right(entity);
  }

  Future<void> _rollback(OrderEntity entity, List<String> completedSteps) async {
    for (final step in completedSteps.reversed) {
      switch (step) {
      case 'validateInventory': break; // TODO: rollback Validate Inventory
      case 'processPayment': break; // TODO: rollback Process Payment
      case 'sendConfirmation': break; // TODO: rollback Send Confirmation Email
      }
    }
  }

  void _emit(OrderDomainEvent event) => _emittedEvents.add(event);
}
