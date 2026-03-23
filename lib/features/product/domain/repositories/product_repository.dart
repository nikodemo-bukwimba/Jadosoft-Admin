import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';

/// Abstract repository for product operations.
///
/// Implementations handle data source selection (remote/mock).
abstract class ProductRepository {
  /// Fetches paginated product list for the current org.
  Future<Either<Failure, List<ProductEntity>>> getAll({
    int page = 1,
    int perPage = 25,
    String? status,
    String? type,
    String? search,
  });

  /// Fetches a single product by [id] with all variants loaded.
  Future<Either<Failure, ProductEntity>> getById(String id);

  /// Creates a new product. The datasource wraps [product.price] into
  /// a default variant before sending to the API.
  Future<Either<Failure, ProductEntity>> create(ProductEntity product);

  /// Updates product-level fields. Does not affect variants.
  Future<Either<Failure, ProductEntity>> update(ProductEntity product);

  /// Deletes a product by [id].
  Future<Either<Failure, void>> delete(String id);

  /// Publishes a draft product → active.
  /// API: POST /api/v1/commerce/products/{id}/publish
  Future<Either<Failure, ProductEntity>> publish(String id);

  /// Archives an active product → archived.
  /// API: POST /api/v1/commerce/products/{id}/archive
  Future<Either<Failure, ProductEntity>> archive(String id);
}
