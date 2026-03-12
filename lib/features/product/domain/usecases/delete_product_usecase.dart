import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/product_repository.dart';

class DeleteProductParams {
  final String id;
  const DeleteProductParams({required this.id});
}

class DeleteProductUseCase implements UseCase<void, DeleteProductParams> {
  final ProductRepository repository;
  DeleteProductUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteProductParams p) =>
      repository.delete(p.id);
}
