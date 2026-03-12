import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<Either<Failure, List<PaymentEntity>>> getAll();
  Future<Either<Failure, PaymentEntity>>       getById(String id);
  Future<Either<Failure, PaymentEntity>>       create(PaymentEntity entity);
  Future<Either<Failure, PaymentEntity>>       update(PaymentEntity entity);
  Future<Either<Failure, void>>                 delete(String id);
}
