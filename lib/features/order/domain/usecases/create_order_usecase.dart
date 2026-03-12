import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class CreateOrderParams {
  final String customerId;
  final List<Map<String, dynamic>> items;
  final double total;
  final String? paymentRef;

  const CreateOrderParams({
    required this.customerId,
    required this.items,
    required this.total,
    this.paymentRef,
  });
}

class CreateOrderUseCase implements UseCase<OrderEntity, CreateOrderParams> {
  final OrderRepository repository;
  CreateOrderUseCase(this.repository);

  @override
  Future<Either<Failure, OrderEntity>> call(CreateOrderParams p) async {
    // -- Validation gate --
    if (p.customerId.trim().isEmpty) {
      return const Left(ValidationFailure('Customer is required'));
    }
    if (p.total < 0.01) {
      return const Left(ValidationFailure('Total must be positive'));
    }

    return repository.create(
      OrderEntity(
        id: '',
        customerId: p.customerId.trim(),
        items: p.items,
        total: p.total,
        paymentRef: p.paymentRef?.trim(),
        status: '',
        createdAt: DateTime.now(),
      ),
    );
  }
}
