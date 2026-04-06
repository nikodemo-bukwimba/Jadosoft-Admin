import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class MarkOrderPaidParams {
  final String orderId;
  final String actorId; // who performed the action
  final String actorName;
  final String? paymentRef; // optional reference entered by admin

  const MarkOrderPaidParams({
    required this.orderId,
    required this.actorId,
    required this.actorName,
    this.paymentRef,
  });
}

class MarkOrderPaidUseCase
    implements UseCase<OrderEntity, MarkOrderPaidParams> {
  final OrderRepository repository;
  MarkOrderPaidUseCase(this.repository);

  @override
  Future<Either<Failure, OrderEntity>> call(MarkOrderPaidParams p) async {
    final result = await repository.getById(p.orderId);
    return result.fold((failure) => Left(failure), (order) async {
      final updated = order.copyWith(
        paymentStatus: 'paid',
        paymentVerifiedBy: p.actorId,
        paymentVerifiedAt: DateTime.now(),
        paymentRef: p.paymentRef ?? order.paymentRef,
      );
      return repository.update(updated);
    });
  }
}
