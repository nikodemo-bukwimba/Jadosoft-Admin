import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class GetAllOrderUseCase implements UseCase<List<OrderEntity>, NoParams> {
  final OrderRepository repository;
  GetAllOrderUseCase(this.repository);

  @override
  Future<Either<Failure, List<OrderEntity>>> call(NoParams _) =>
      repository.getAll();
}
