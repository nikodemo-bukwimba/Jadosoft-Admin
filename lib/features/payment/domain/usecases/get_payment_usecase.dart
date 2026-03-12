import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

class GetPaymentParams {
  final String id;
  const GetPaymentParams({required this.id});
}

class GetPaymentUseCase implements UseCase<PaymentEntity, GetPaymentParams> {
  final PaymentRepository repository;
  GetPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentEntity>> call(GetPaymentParams p) =>
      repository.getById(p.id);
}
