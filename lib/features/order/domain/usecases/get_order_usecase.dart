import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class GetOrderParams {
  final String id;
  const GetOrderParams({required this.id});
}

class GetOrderUseCase implements UseCase<OrderEntity, GetOrderParams> {
  final OrderRepository repository;
  GetOrderUseCase(this.repository);

  @override
  Future<Either<Failure, OrderEntity>> call(GetOrderParams p) =>
      repository.getById(p.id);
}
