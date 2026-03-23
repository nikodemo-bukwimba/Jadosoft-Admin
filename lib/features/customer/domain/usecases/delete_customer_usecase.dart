import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/customer_repository.dart';

class DeleteCustomerParams { final String id; const DeleteCustomerParams({required this.id}); }
class DeleteCustomerUseCase implements UseCase<void, DeleteCustomerParams> {
  final CustomerRepository repository;
  DeleteCustomerUseCase(this.repository);
  @override Future<Either<Failure, void>> call(DeleteCustomerParams p) => repository.delete(p.id);
}
