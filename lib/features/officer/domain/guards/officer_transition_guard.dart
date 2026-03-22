import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../value_objects/officer_status.dart';

class OfficerTransitionGuard {
  Either<Failure, OfficerStatus> validate({
    required OfficerStatus current, required OfficerStatus target,
  }) {
    if (!current.canTransitionTo(target)) {
      return Left(ValidationFailure(
        'Cannot transition from ${current.displayName} to ${target.displayName}',
      ));
    }
    return Right(target);
  }
}
