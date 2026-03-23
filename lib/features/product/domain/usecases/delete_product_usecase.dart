import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/product_repository.dart';

class DeleteProductUsecase implements UseCase<void, String> {
  final ProductRepository repository;

  const DeleteProductUsecase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.delete(id);
  }
}
