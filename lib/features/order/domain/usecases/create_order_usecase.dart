import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';
import '../../../product/domain/usecases/deduct_product_quantity_usecase.dart';

// ── Params ────────────────────────────────────────────────────
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

// ── Use Case ──────────────────────────────────────────────────
class CreateOrderUseCase implements UseCase<OrderEntity, CreateOrderParams> {
  final OrderRepository repository;
  final DeductProductQuantityUseCase deductQuantity;

  CreateOrderUseCase({required this.repository, required this.deductQuantity});

  @override
  Future<Either<Failure, OrderEntity>> call(CreateOrderParams p) async {
    if (p.customerId.trim().isEmpty) {
      return const Left(ValidationFailure('Customer is required'));
    }
    if (p.total < 0.01) {
      return const Left(ValidationFailure('Total must be positive'));
    }

    final result = await repository.create(
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

    result.fold((_) => null, (_) async {
      for (final item in p.items) {
        final productId = item['productId']?.toString();
        final qty = (item['qty'] as num?)?.toInt();
        if (productId != null && qty != null && qty > 0) {
          await deductQuantity(
            DeductProductQuantityParams(productId: productId, quantity: qty),
          );
        }
      }
    });

    return result;
  }
}
