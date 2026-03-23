import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetAllProductParams {
  final int page;
  final int perPage;
  final String? status;
  final String? type;
  final String? search;

  const GetAllProductParams({
    this.page = 1,
    this.perPage = 25,
    this.status,
    this.type,
    this.search,
  });
}

class GetAllProductUsecase
    implements UseCase<List<ProductEntity>, GetAllProductParams> {
  final ProductRepository repository;

  const GetAllProductUsecase(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(
    GetAllProductParams params,
  ) {
    return repository.getAll(
      page: params.page,
      perPage: params.perPage,
      status: params.status,
      type: params.type,
      search: params.search,
    );
  }
}
