import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/order/domain/entities/order_entity.dart';

/// Provider interface to access Order data from order feature.
abstract class OrderDataProvider {
  Future<Either<Failure, List<OrderEntity>>> getAll();
}
