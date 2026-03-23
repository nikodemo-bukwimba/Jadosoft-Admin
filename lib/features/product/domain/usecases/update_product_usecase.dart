import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class UpdateProductUsecase implements UseCase<ProductEntity, ProductEntity> {
  final ProductRepository repository;

  const UpdateProductUsecase(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(ProductEntity product) {
    return repository.update(product);
  }
}
