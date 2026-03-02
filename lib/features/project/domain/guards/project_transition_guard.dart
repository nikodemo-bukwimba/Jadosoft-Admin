import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../value_objects/project_status.dart';

class ProjectTransitionGuard {
  /// Validates that the transition from [current] to [target] is allowed.
  /// Returns Right(target) if valid, Left(Failure) if not.
  Either<Failure, ProjectStatus> validate({
    required ProjectStatus current,
    required ProjectStatus target,
  }) {
    if (!current.canTransitionTo(target)) {
      return Left(ValidationFailure(
        'Cannot transition from ${current.displayName} to ${target.displayName}',
      ));
    }

    // ── HUMAN CUSTOMIZATION ZONE ──────────────────────────
    // Add business rule checks here, e.g.:
    //   if (target == ProjectStatus.approved && !hasManagerRole) {
    //     return Left(ValidationFailure('Manager approval required'));
    //   }
    // ── END CUSTOMIZATION ZONE ────────────────────────────

    return Right(target);
  }
}
