// lib/features/officer/domain/usecases/get_officer_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/officer_entity.dart';
import '../repositories/officer_repository.dart';

class GetOfficerParams {
  final String userId;
  final String? branchId;
  const GetOfficerParams({required this.userId, this.branchId});
}

class GetOfficerUseCase implements UseCase<OfficerEntity, GetOfficerParams> {
  final OfficerRepository repository;
  GetOfficerUseCase(this.repository);

  @override
  Future<Either<Failure, OfficerEntity>> call(GetOfficerParams p) =>
      repository.getById(p.userId, branchId: p.branchId);
}
