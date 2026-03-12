import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

class UpdatePaymentParams {
  final PaymentEntity entity;
  const UpdatePaymentParams({required this.entity});
}

class UpdatePaymentUseCase implements UseCase<PaymentEntity, UpdatePaymentParams> {
  final PaymentRepository repository;
  UpdatePaymentUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentEntity>> call(UpdatePaymentParams p) async {
    return repository.update(p.entity);
  }
}
