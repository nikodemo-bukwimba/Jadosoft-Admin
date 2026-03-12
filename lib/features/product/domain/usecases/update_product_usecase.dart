import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class UpdateProductParams {
  final ProductEntity entity;
  const UpdateProductParams({required this.entity});
}

class UpdateProductUseCase implements UseCase<ProductEntity, UpdateProductParams> {
  final ProductRepository repository;
  UpdateProductUseCase(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(UpdateProductParams p) async {
    return repository.update(p.entity);
  }
}
