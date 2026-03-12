import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/product/domain/entities/product_entity.dart';
import '../../../../features/product/domain/repositories/product_repository.dart';
import '../../domain/providers/product_data_provider.dart';

class ProductDataProviderImpl implements ProductDataProvider {
  final ProductRepository _repository;

  ProductDataProviderImpl({required ProductRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, List<ProductEntity>>> getAll() =>
      _repository.getAll();
}
