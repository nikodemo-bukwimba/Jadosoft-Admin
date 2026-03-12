import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';
import '../guards/order_transition_guard.dart';
import '../repositories/order_repository.dart';
import '../value_objects/order_status.dart';

class OrderDomainService {
  final OrderRepository repository;
  final OrderTransitionGuard guard;

  OrderDomainService({
    required this.repository,
    required this.guard,
  });

  /// Performs a status transition: load, guard, apply, persist.
  Future<Either<Failure, OrderEntity>> transition({
    required String id,
    required OrderStatus targetStatus,
  }) async {
    // 1. Load
    final loadResult = await repository.getById(id);
    if (loadResult.isLeft()) return loadResult;
    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    // 2. Guard
final guardResult = guard.validate(
  current: OrderStatusX.fromString(entity.status),
  target:  targetStatus,
);
    if (guardResult.isLeft()) {
      return guardResult.fold((f) => Left(f), (_) => throw StateError('unreachable'));
    }
    final validTarget = guardResult.getOrElse(() => throw StateError('unreachable'));

    // 3. Apply + Persist
    final updated = entity.copyWith(status: validTarget.name);
    return repository.update(updated);
  }
}
