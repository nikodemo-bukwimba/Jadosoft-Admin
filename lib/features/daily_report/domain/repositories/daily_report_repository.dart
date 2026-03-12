import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/daily_report_entity.dart';

abstract class DailyReportRepository {
  Future<Either<Failure, List<DailyReportEntity>>> getAll();
  Future<Either<Failure, DailyReportEntity>>       getById(String id);
  Future<Either<Failure, DailyReportEntity>>       create(DailyReportEntity entity);
  Future<Either<Failure, DailyReportEntity>>       update(DailyReportEntity entity);
  Future<Either<Failure, void>>                 delete(String id);
}
