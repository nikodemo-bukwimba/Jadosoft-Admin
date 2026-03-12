import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class UpdateOrderParams {
  final OrderEntity entity;
  const UpdateOrderParams({required this.entity});
}

class UpdateOrderUseCase implements UseCase<OrderEntity, UpdateOrderParams> {
  final OrderRepository repository;
  UpdateOrderUseCase(this.repository);

  @override
  Future<Either<Failure, OrderEntity>> call(UpdateOrderParams p) async {
    return repository.update(p.entity);
  }
}
