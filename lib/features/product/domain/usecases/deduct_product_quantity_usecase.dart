import 'package:jadosoft_admin/features/product/domain/repositories/product_repository.dart';
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
  final ProductRepository repository;
  DeductProductQuantityUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeductProductQuantityParams p) async {
    // Fetch current product
    final result = await repository.getById(p.productId);
    return result.fold(
      (failure) => Left(failure),
      (product) async {
        final current = product.quantityAvailable ?? 0;
        final newQty = (current - p.quantity).clamp(0, current);
        final updated = product.copyWith(quantityAvailable: newQty);
        final updateResult = await repository.update(updated);
        return updateResult.fold(
          (failure) => Left(failure),
          (_) => const Right(null),
        );
      },
    );
  }
}