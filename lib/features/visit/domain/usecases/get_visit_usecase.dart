// get_visit_usecase.dart
// Fetches a single record by ID.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/visit_repository.dart';

class GetVisitParams {
  final String id;
  const GetVisitParams({required this.id});
}

class GetVisitUseCase
    implements UseCase<CategoryEntity, GetVisitParams> {

  final VisitRepository repository;
  GetVisitUseCase(this.repository);

  @override
  Future<Either<Failure, CategoryEntity>> call(
      GetVisitParams params) {
    if (params.id.isEmpty) {
      return Future.value(const Left(ValidationFailure('ID is required')));
    }
    return repository.getById(params.id);
  }
}
