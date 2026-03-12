import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/daily_report/domain/entities/daily_report_entity.dart';
import '../../../../features/daily_report/domain/repositories/daily_report_repository.dart';
import '../../domain/providers/daily_report_data_provider.dart';

class DailyReportDataProviderImpl implements DailyReportDataProvider {
  final DailyReportRepository _repository;

  DailyReportDataProviderImpl({required DailyReportRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, List<DailyReportEntity>>> getAll() =>
      _repository.getAll();
}
