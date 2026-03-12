import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/order/domain/entities/order_entity.dart';
import '../../../../features/order/domain/repositories/order_repository.dart';
import '../../domain/providers/order_data_provider.dart';

class OrderDataProviderImpl implements OrderDataProvider {
  final OrderRepository _repository;

  OrderDataProviderImpl({required OrderRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, List<OrderEntity>>> getAll() =>
      _repository.getAll();
}
