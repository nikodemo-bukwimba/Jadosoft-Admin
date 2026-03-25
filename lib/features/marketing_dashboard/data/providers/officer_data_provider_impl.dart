// officer_data_provider_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/officer/domain/entities/officer_entity.dart';
import '../../../../features/officer/domain/repositories/officer_repository.dart';
import '../../domain/providers/officer_data_provider.dart';

class OfficerDataProviderImpl implements OfficerDataProvider {
  final OfficerRepository _repository;

  OfficerDataProviderImpl({required OfficerRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, List<OfficerEntity>>> getAll() async {
    final result = await _repository.getAll();
    return result.fold(
      Left.new,
      (paginated) => Right(paginated.items),
    );
  }
}