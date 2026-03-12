import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/payment_repository.dart';

class DeletePaymentParams {
  final String id;
  const DeletePaymentParams({required this.id});
}

class DeletePaymentUseCase implements UseCase<void, DeletePaymentParams> {
  final PaymentRepository repository;
  DeletePaymentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeletePaymentParams p) =>
      repository.delete(p.id);
}
