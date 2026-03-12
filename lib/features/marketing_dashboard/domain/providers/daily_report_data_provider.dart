import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/daily_report/domain/entities/daily_report_entity.dart';

/// Provider interface to access DailyReport data from daily_report feature.
abstract class DailyReportDataProvider {
  Future<Either<Failure, List<DailyReportEntity>>> getAll();
}
