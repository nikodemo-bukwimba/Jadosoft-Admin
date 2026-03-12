import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/promotion_repository.dart';

class DeletePromotionParams {
  final String id;
  const DeletePromotionParams({required this.id});
}

class DeletePromotionUseCase implements UseCase<void, DeletePromotionParams> {
  final PromotionRepository repository;
  DeletePromotionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeletePromotionParams p) =>
      repository.delete(p.id);
}
