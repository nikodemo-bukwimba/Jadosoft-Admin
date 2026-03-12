import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/product/domain/entities/product_entity.dart';

/// Provider interface to access Product data from product feature.
abstract class ProductDataProvider {
  Future<Either<Failure, List<ProductEntity>>> getAll();
}
