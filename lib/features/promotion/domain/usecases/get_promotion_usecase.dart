import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/promotion_entity.dart';
import '../repositories/promotion_repository.dart';

class GetPromotionParams {
  final String id;
  const GetPromotionParams({required this.id});
}

class GetPromotionUseCase implements UseCase<PromotionEntity, GetPromotionParams> {
  final PromotionRepository repository;
  GetPromotionUseCase(this.repository);

  @override
  Future<Either<Failure, PromotionEntity>> call(GetPromotionParams p) =>
      repository.getById(p.id);
}
