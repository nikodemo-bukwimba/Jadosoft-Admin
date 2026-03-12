import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<CustomerEntity>>> getAll();
  Future<Either<Failure, CustomerEntity>>       getById(String id);
  Future<Either<Failure, CustomerEntity>>       create(CustomerEntity entity);
  Future<Either<Failure, CustomerEntity>>       update(CustomerEntity entity);
  Future<Either<Failure, void>>                 delete(String id);
}
