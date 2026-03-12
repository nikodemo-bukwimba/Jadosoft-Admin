import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/customer/domain/entities/customer_entity.dart';
import '../../../../features/customer/domain/repositories/customer_repository.dart';
import '../../domain/providers/customer_data_provider.dart';

class CustomerDataProviderImpl implements CustomerDataProvider {
  final CustomerRepository _repository;

  CustomerDataProviderImpl({required CustomerRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, List<CustomerEntity>>> getAll() =>
      _repository.getAll();
}
