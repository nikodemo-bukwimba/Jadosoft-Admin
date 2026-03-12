import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<ProductEntity>>> getAll();
  Future<Either<Failure, ProductEntity>>       getById(String id);
  Future<Either<Failure, ProductEntity>>       create(ProductEntity entity);
  Future<Either<Failure, ProductEntity>>       update(ProductEntity entity);
  Future<Either<Failure, void>>                 delete(String id);
}
