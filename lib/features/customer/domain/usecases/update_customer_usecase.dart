import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class UpdateCustomerParams {
  final CustomerEntity entity;
  const UpdateCustomerParams({required this.entity});
}

class UpdateCustomerUseCase implements UseCase<CustomerEntity, UpdateCustomerParams> {
  final CustomerRepository repository;
  UpdateCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, CustomerEntity>> call(UpdateCustomerParams p) async {
    return repository.update(p.entity);
  }
}
