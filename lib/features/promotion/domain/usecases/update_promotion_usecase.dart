import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/promotion_entity.dart';
import '../repositories/promotion_repository.dart';

class UpdatePromotionParams {
  final PromotionEntity entity;
  const UpdatePromotionParams({required this.entity});
}

class UpdatePromotionUseCase implements UseCase<PromotionEntity, UpdatePromotionParams> {
  final PromotionRepository repository;
  UpdatePromotionUseCase(this.repository);

  @override
  Future<Either<Failure, PromotionEntity>> call(UpdatePromotionParams p) async {
    return repository.update(p.entity);
  }
}
