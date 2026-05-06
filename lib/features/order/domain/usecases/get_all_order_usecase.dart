// lib/features/order/domain/usecases/get_all_order_usecase.dart
// Sole definition of GetAllOrderUseCase (with optional createdById filter).
// create_order_usecase.dart no longer re-declares this class.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class GetAllOrderParams {
  /// When non-null, only returns orders placed by this actor.
  final String? createdById;
  const GetAllOrderParams({this.createdById});
}

class GetAllOrderUseCase
    implements UseCase<List<OrderEntity>, GetAllOrderParams> {
  final OrderRepository repository;
  GetAllOrderUseCase(this.repository);

  @override
  Future<Either<Failure, List<OrderEntity>>> call(GetAllOrderParams p) =>
      repository.getAll(createdById: p.createdById);
}
