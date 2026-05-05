// lib/features/order/domain/usecases/deduct_product_quantity_usecase.dart
//
// Stub use-case that create_order_usecase.dart depends on.
// Wire a real ProductRepository here when inventory management is ready.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';

class DeductProductQuantityParams {
  final String productId;
  final int quantity;
  const DeductProductQuantityParams({
    required this.productId,
    required this.quantity,
  });
}

class DeductProductQuantityUseCase
    implements UseCase<void, DeductProductQuantityParams> {
  // Inject a ProductRepository (or inventory service) here when ready.
  // For now this is a no-op stub so orders can be created without errors.
  const DeductProductQuantityUseCase();

  @override
  Future<Either<Failure, void>> call(DeductProductQuantityParams p) async {
    // TODO: deduct p.quantity units of p.productId from inventory.
    return const Right(null);
  }
}