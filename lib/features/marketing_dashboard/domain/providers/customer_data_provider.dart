import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/customer/domain/entities/customer_entity.dart';

/// Provider interface to access Customer data from customer feature.
abstract class CustomerDataProvider {
  Future<Either<Failure, List<CustomerEntity>>> getAll();
}
