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
  final double? discountPercentage;

  const CreatePromotionParams({
    required this.title,
    this.description,
    required this.productIds,
    required this.startDate,
    required this.endDate,
    required this.channels,
    this.discountPercentage,
  });
}

class CreatePromotionUseCase
    implements UseCase<PromotionEntity, CreatePromotionParams> {
  final PromotionRepository repository;
  CreatePromotionUseCase(this.repository);

  @override
  Future<Either<Failure, PromotionEntity>> call(CreatePromotionParams p) async {
    if (p.title.trim().isEmpty) {
      return const Left(ValidationFailure('Promotion title is required'));
    }
    if (p.title.trim().length < 3) {
      return const Left(
        ValidationFailure('Title must be at least 3 characters'),
      );
    }
    if (p.discountPercentage != null &&
        (p.discountPercentage! < 0 || p.discountPercentage! > 100)) {
      return const Left(
        ValidationFailure('Discount percentage must be between 0 and 100'),
      );
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
        discountPercentage: p.discountPercentage,
      ),
    );
  }
}
