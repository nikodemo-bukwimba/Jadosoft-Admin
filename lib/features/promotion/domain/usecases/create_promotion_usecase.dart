import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/promotion_entity.dart';
import '../repositories/promotion_repository.dart';

class CreatePromotionParams {
  final String title;
  final String? description;
  final List<String> productIds;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> channels;

  const CreatePromotionParams({
    required this.title,
    this.description,
    required this.productIds,
    required this.startDate,
    required this.endDate,
    required this.channels,
  });
}

class CreatePromotionUseCase implements UseCase<PromotionEntity, CreatePromotionParams> {
  final PromotionRepository repository;
  CreatePromotionUseCase(this.repository);

  @override
  Future<Either<Failure, PromotionEntity>> call(CreatePromotionParams p) async {
    // -- Validation gate --
    if (p.title.trim().isEmpty) {
      return const Left(ValidationFailure('Promotion title is required'));
    }
    if (p.title.trim().length < 3) {
      return const Left(ValidationFailure('Title must be at least 3 characters'));
    }

    return repository.create(
      PromotionEntity(
        id: '',
        title: p.title.trim(),
        description: p.description?.trim(),
        productIds: p.productIds,
        startDate: p.startDate,
        endDate: p.endDate,
        channels: p.channels,
        status: '',
        createdAt: DateTime.now(),
      ),
    );
  }
}
