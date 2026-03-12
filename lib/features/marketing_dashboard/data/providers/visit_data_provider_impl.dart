import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/visit/domain/entities/visit_entity.dart';
import '../../../../features/visit/domain/repositories/visit_repository.dart';
import '../../domain/providers/visit_data_provider.dart';

class VisitDataProviderImpl implements VisitDataProvider {
  final VisitRepository _repository;

  VisitDataProviderImpl({required VisitRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, List<VisitEntity>>> getAll() =>
      _repository.getAll();
}
