import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';
import '../guards/product_transition_guard.dart';
import '../repositories/product_repository.dart';

/// Domain service that wraps guard logic around product transitions.
class ProductDomainService {
  final ProductRepository _repository;
  final ProductTransitionGuard _guard;

  const ProductDomainService({
    required ProductRepository repository,
    ProductTransitionGuard guard = const ProductTransitionGuard(),
  })  : _repository = repository,
        _guard = guard;

  /// Attempts to publish a draft product.
  /// Returns [Failure] if the transition is not allowed.
  Future<Either<Failure, ProductEntity>> publish(ProductEntity product) async {
    if (!_guard.canTransition(product, 'publish')) {
      return Left(ValidationFailure(
        'Cannot publish: product must be in draft status.',
      ));
    }
    return _repository.publish(product.id);
  }

  /// Attempts to archive an active product.
  /// Returns [Failure] if the transition is not allowed.
  Future<Either<Failure, ProductEntity>> archive(ProductEntity product) async {
    if (!_guard.canTransition(product, 'archive')) {
      return Left(ValidationFailure(
        'Cannot archive: product must be in active status.',
      ));
    }
    return _repository.archive(product.id);
  }
}
