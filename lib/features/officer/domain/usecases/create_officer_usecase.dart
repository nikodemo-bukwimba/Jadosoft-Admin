// create_officer_usecase.dart
// ─────────────────────────────────────────────────────────────
// Creates (invites) a new officer into a specific branch.
//
// Replaces the old CreateOfficerParams that had no branch or role ID.
// Now requires branchId and orgRoleId to properly place the officer
// within the org hierarchy.
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/officer_entity.dart';
import '../repositories/officer_repository.dart';

class CreateOfficerParams {
  /// Officer's email (used for invite and login).
  final String email;

  /// Optional username (if not provided, API may derive from email).
  final String? username;

  /// Phone number.
  final String? phone;

  /// The branch (org) to assign this officer to.
  final String branchId;

  /// The org role to assign (e.g., Field Officer role ID).
  final String orgRoleId;

  const CreateOfficerParams({
    required this.email,
    this.username,
    this.phone,
    required this.branchId,
    required this.orgRoleId,
  });
}

class CreateOfficerUseCase
    implements UseCase<OfficerEntity, CreateOfficerParams> {
  final OfficerRepository repository;
  CreateOfficerUseCase(this.repository);

  @override
  Future<Either<Failure, OfficerEntity>> call(CreateOfficerParams p) async {
    // ── Validation ─────────────────────────────────────────
    if (p.email.trim().isEmpty) {
      return const Left(ValidationFailure('Email is required'));
    }
    if (!p.email.contains('@')) {
      return const Left(ValidationFailure('Enter a valid email'));
    }
    if (p.branchId.trim().isEmpty) {
      return const Left(ValidationFailure('Branch assignment is required'));
    }
    if (p.orgRoleId.trim().isEmpty) {
      return const Left(ValidationFailure('Role assignment is required'));
    }

    return repository.invite(
      email: p.email.trim(),
      username: p.username?.trim(),
      phone: p.phone?.trim(),
      branchId: p.branchId,
      orgRoleId: p.orgRoleId,
    );
  }
}