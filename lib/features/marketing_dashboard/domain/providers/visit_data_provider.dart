import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/visit/domain/entities/visit_entity.dart';

/// Provider interface to access Visit data from visit feature.
abstract class VisitDataProvider {
  Future<Either<Failure, List<VisitEntity>>> getAll();
}
