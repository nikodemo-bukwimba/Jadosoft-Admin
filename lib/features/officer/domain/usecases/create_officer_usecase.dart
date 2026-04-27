import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/officer_entity.dart';
import '../repositories/officer_repository.dart';

class CreateOfficerParams {
  final String email;
  final String? username;
  final String? phone;
  final String branchId;
  final String orgRoleId;
  final String? appPassword;
  final String? appPasswordConfirmation;
  const CreateOfficerParams({
    required this.email,
    this.username,
    this.phone,
    required this.branchId,
    required this.orgRoleId,
    this.appPassword, // ← ADD
    this.appPasswordConfirmation, // ← ADD
  });
}

class CreateOfficerUseCase
    implements UseCase<OfficerEntity, CreateOfficerParams> {
  final OfficerRepository repository;
  CreateOfficerUseCase(this.repository);
  @override
  Future<Either<Failure, OfficerEntity>> call(CreateOfficerParams p) async {
    if (p.email.trim().isEmpty) {
      return const Left(ValidationFailure('Email is required'));
    }
    if (!p.email.contains('@')) {
      return const Left(ValidationFailure('Enter a valid email'));
    }
    if (p.branchId.trim().isEmpty) {
      return const Left(ValidationFailure('Branch is required'));
    }
    if (p.orgRoleId.trim().isEmpty) {
      return const Left(ValidationFailure('Role is required'));
    }
    return repository.invite(
      email: p.email.trim(),
      username: p.username?.trim(),
      phone: p.phone?.trim(),
      branchId: p.branchId,
      orgRoleId: p.orgRoleId,
      appPassword: p.appPassword, // ← ADD
      appPasswordConfirmation: p.appPasswordConfirmation, // ← ADD
    );
  }
}
