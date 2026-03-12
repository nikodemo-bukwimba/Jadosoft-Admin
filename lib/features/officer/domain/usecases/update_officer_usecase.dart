import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/officer_entity.dart';
import '../repositories/officer_repository.dart';

class UpdateOfficerParams {
  final OfficerEntity entity;
  const UpdateOfficerParams({required this.entity});
}

class UpdateOfficerUseCase implements UseCase<OfficerEntity, UpdateOfficerParams> {
  final OfficerRepository repository;
  UpdateOfficerUseCase(this.repository);

  @override
  Future<Either<Failure, OfficerEntity>> call(UpdateOfficerParams p) async {
    return repository.update(p.entity);
  }
}
