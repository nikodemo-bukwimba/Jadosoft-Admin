import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/payment/domain/entities/payment_entity.dart';

/// Provider interface to access Payment data from payment feature.
abstract class PaymentDataProvider {
  Future<Either<Failure, List<PaymentEntity>>> getAll();
}
