import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/officer/domain/entities/officer_entity.dart';

/// Provider interface to access Officer data from officer feature.
abstract class OfficerDataProvider {
  Future<Either<Failure, List<OfficerEntity>>> getAll();
}
