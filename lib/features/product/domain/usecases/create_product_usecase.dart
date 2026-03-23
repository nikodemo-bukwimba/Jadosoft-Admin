import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class CreateProductUsecase implements UseCase<ProductEntity, ProductEntity> {
  final ProductRepository repository;

  const CreateProductUsecase(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(ProductEntity product) {
    return repository.create(product);
  }
}
