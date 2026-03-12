import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetProductParams {
  final String id;
  const GetProductParams({required this.id});
}

class GetProductUseCase implements UseCase<ProductEntity, GetProductParams> {
  final ProductRepository repository;
  GetProductUseCase(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(GetProductParams p) =>
      repository.getById(p.id);
}
