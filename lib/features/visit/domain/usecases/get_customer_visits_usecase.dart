import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/visit_entity.dart';
import '../repositories/visit_repository.dart';

class GetCustomerVisitsParams {
  final String customerId;
  const GetCustomerVisitsParams({required this.customerId});
}

class GetCustomerVisitsUseCase
    implements UseCase<List<VisitEntity>, GetCustomerVisitsParams> {
  final VisitRepository repository;
  GetCustomerVisitsUseCase(this.repository);

  @override
  Future<Either<Failure, List<VisitEntity>>> call(
          GetCustomerVisitsParams p) =>
      repository.getByCustomer(p.customerId);
}