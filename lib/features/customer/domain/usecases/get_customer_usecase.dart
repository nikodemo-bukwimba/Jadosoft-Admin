import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class GetCustomerParams { final String id; const GetCustomerParams({required this.id}); }
class GetCustomerUseCase implements UseCase<CustomerEntity, GetCustomerParams> {
  final CustomerRepository repository;
  GetCustomerUseCase(this.repository);
  @override Future<Either<Failure, CustomerEntity>> call(GetCustomerParams p) => repository.getById(p.id);
}
