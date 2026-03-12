import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/payment/domain/entities/payment_entity.dart';
import '../../../../features/payment/domain/repositories/payment_repository.dart';
import '../../domain/providers/payment_data_provider.dart';

class PaymentDataProviderImpl implements PaymentDataProvider {
  final PaymentRepository _repository;

  PaymentDataProviderImpl({required PaymentRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, List<PaymentEntity>>> getAll() =>
      _repository.getAll();
}
