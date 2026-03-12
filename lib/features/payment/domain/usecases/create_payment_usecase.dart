import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

class CreatePaymentParams {
  final String orderId;
  final String customerId;
  final double amount;
  final String currency;
  final String provider;
  final String? transactionRef;

  const CreatePaymentParams({
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.currency,
    required this.provider,
    this.transactionRef,
  });
}

class CreatePaymentUseCase
    implements UseCase<PaymentEntity, CreatePaymentParams> {
  final PaymentRepository repository;
  CreatePaymentUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentEntity>> call(CreatePaymentParams p) async {
    // -- Validation gate --
    // No validation rules configured

    return repository.create(
      PaymentEntity(
        id: '',
        orderId: p.orderId.trim(),
        customerId: p.customerId.trim(),
        amount: p.amount,
        currency: p.currency.trim(),
        provider: p.provider.trim(),
        transactionRef: p.transactionRef?.trim(),
        status: '',
        initiatedAt: DateTime.now(),
        confirmedAt: DateTime.now(),
        failureReason: '',
      ),
    );
  }
}
