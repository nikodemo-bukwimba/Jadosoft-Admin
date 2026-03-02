import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/order_repository.dart';

class DeleteOrderParams {
  final String id;
  const DeleteOrderParams({required this.id});
}

class DeleteOrderUseCase implements UseCase<void, DeleteOrderParams> {
  final OrderRepository repository;
  DeleteOrderUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteOrderParams p) =>
      repository.delete(p.id);
}
