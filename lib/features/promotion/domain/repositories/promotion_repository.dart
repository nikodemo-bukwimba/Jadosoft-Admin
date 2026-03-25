import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/promotion_entity.dart';

abstract class PromotionRepository {
  Future<Either<Failure, List<PromotionEntity>>> getAll();
  Future<Either<Failure, PromotionEntity>>       getById(String id);
  Future<Either<Failure, PromotionEntity>>       create(PromotionEntity entity);
  Future<Either<Failure, PromotionEntity>>       update(PromotionEntity entity);
  Future<Either<Failure, void>>                  delete(String id);
  Future<Either<Failure, PromotionEntity>>       publish(String id);
}
