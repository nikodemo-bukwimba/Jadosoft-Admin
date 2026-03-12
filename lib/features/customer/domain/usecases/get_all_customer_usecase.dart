import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class GetAllCustomerUseCase implements UseCase<List<CustomerEntity>, NoParams> {
  final CustomerRepository repository;
  GetAllCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, List<CustomerEntity>>> call(NoParams _) =>
      repository.getAll();
}
