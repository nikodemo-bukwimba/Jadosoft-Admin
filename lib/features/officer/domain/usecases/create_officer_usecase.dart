import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/officer_entity.dart';
import '../repositories/officer_repository.dart';

/// Parameters for creating an officer with a full account.
///
/// Problem #2 fix: [fullName] and [password] are now required so the
/// backend can create a login-ready User account immediately.
class CreateOfficerParams {
  /// Real full name — stored as actor.display_name.
  /// This is what gets displayed everywhere in the UI.
  final String fullName;

  final String email;
  final String password;
  final String passwordConfirmation;
  final String? phone;
  final String branchId;
  final String orgRoleId;
  final int? level;

  const CreateOfficerParams({
    required this.fullName,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.phone,
    required this.branchId,
    required this.orgRoleId,
    this.level,
  });
}

class CreateOfficerUseCase
    implements UseCase<OfficerEntity, CreateOfficerParams> {
  final OfficerRepository repository;
  CreateOfficerUseCase(this.repository);

  @override
  Future<Either<Failure, OfficerEntity>> call(CreateOfficerParams p) async {
    // Validate
    if (p.fullName.trim().isEmpty) {
      return const Left(ValidationFailure('Full name is required'));
    }
    if (p.email.trim().isEmpty || !p.email.contains('@')) {
      return const Left(ValidationFailure('Enter a valid email'));
    }
    if (p.password.isEmpty) {
      return const Left(ValidationFailure('Password is required'));
    }
    if (p.password != p.passwordConfirmation) {
      return const Left(ValidationFailure('Passwords do not match'));
    }
    if (p.branchId.trim().isEmpty) {
      return const Left(ValidationFailure('Branch is required'));
    }
    if (p.orgRoleId.trim().isEmpty) {
      return const Left(ValidationFailure('Role is required'));
    }

    return repository.create(
      fullName: p.fullName.trim(),
      email: p.email.trim(),
      password: p.password,
      passwordConfirmation: p.passwordConfirmation,
      phone: p.phone?.trim(),
      branchId: p.branchId,
      orgRoleId: p.orgRoleId,
      level: p.level,
    );
  }
}
