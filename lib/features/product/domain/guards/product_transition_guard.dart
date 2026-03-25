import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../value_objects/product_status.dart';

class ProductTransitionGuard {
  /// Validates that the transition from [current] to [target] is allowed.
  /// Returns Right(target) if valid, Left(Failure) if not.
  Either<Failure, ProductStatus> validate({
    required ProductStatus current,
    required ProductStatus target,
  }) {
    if (!current.canTransitionTo(target)) {
      return Left(ValidationFailure(
        'Cannot transition from ${current.displayName} to ${target.displayName}',
      ));
    }

    // -- HUMAN CUSTOMIZATION ZONE --
    // Add business rule checks here, e.g.:
    //   if (target == ProductStatus.approved && !hasManagerRole) {
    //     return Left(ValidationFailure('Manager approval required'));
    //   }
    // -- END CUSTOMIZATION ZONE --

    return Right(target);
  }
}
