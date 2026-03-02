import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class CreateOrderParams {
  final String orderNumber;
  final String customerName;
  final double totalAmount;
  final String? notes;
  final bool isUrgent;

  const CreateOrderParams({
    required this.orderNumber,
    required this.customerName,
    required this.totalAmount,
    this.notes,
    required this.isUrgent,
  });
}

class CreateOrderUseCase implements UseCase<OrderEntity, CreateOrderParams> {
  final OrderRepository repository;
  CreateOrderUseCase(this.repository);

  @override
  Future<Either<Failure, OrderEntity>> call(CreateOrderParams p) async {
    // ── Validation gate ─────────────────────────────────
    if (p.orderNumber.trim().isEmpty) {
      return const Left(ValidationFailure('Order number is required'));
    }
    if (p.customerName.trim().isEmpty) {
      return const Left(ValidationFailure('Customer name is required'));
    }
    if (p.customerName.trim().length < 2) {
      return const Left(ValidationFailure('Customer name too short'));
    }
    if (p.totalAmount < 0.01) {
      return const Left(ValidationFailure('Total must be positive'));
    }

    return repository.create(
      OrderEntity(
        id: '',
        orderNumber: p.orderNumber.trim(),
        customerName: p.customerName.trim(),
        totalAmount: p.totalAmount,
        notes: p.notes?.trim(),
        isUrgent: p.isUrgent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}
