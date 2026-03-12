import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/promotion_entity.dart';
import '../repositories/promotion_repository.dart';

class GetAllPromotionUseCase implements UseCase<List<PromotionEntity>, NoParams> {
  final PromotionRepository repository;
  GetAllPromotionUseCase(this.repository);

  @override
  Future<Either<Failure, List<PromotionEntity>>> call(NoParams _) =>
      repository.getAll();
}
