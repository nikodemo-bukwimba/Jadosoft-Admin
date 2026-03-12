import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetAllProductUseCase implements UseCase<List<ProductEntity>, NoParams> {
  final ProductRepository repository;
  GetAllProductUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(NoParams _) =>
      repository.getAll();
}
