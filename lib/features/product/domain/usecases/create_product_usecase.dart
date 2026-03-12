import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class CreateProductParams {
  final String name;
  final String? description;
  final double price;
  final String categoryId;
  final bool isAvailable;
  final bool isFeatured;
  final bool isNew;

  const CreateProductParams({
    required this.name,
    this.description,
    required this.price,
    required this.categoryId,
    required this.isAvailable,
    required this.isFeatured,
    required this.isNew,
  });
}

class CreateProductUseCase implements UseCase<ProductEntity, CreateProductParams> {
  final ProductRepository repository;
  CreateProductUseCase(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(CreateProductParams p) async {
    // -- Validation gate --
    if (p.name.trim().isEmpty) {
      return const Left(ValidationFailure('Product name is required'));
    }
    if (p.name.trim().length < 2) {
      return const Left(ValidationFailure('Name must be at least 2 characters'));
    }
    if (p.price < 0.01) {
      return const Left(ValidationFailure('Price must be positive'));
    }
    if (p.categoryId.trim().isEmpty) {
      return const Left(ValidationFailure('Category is required'));
    }

    return repository.create(
      ProductEntity(
        id: '',
        name: p.name.trim(),
        description: p.description?.trim(),
        price: p.price,
        categoryId: p.categoryId.trim(),
        isAvailable: p.isAvailable,
        isFeatured: p.isFeatured,
        isNew: p.isNew,
        status: '',
        createdAt: DateTime.now(),
      ),
    );
  }
}
