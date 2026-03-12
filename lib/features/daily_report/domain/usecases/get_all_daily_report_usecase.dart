import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/daily_report_entity.dart';
import '../repositories/daily_report_repository.dart';

class GetAllDailyReportUseCase implements UseCase<List<DailyReportEntity>, NoParams> {
  final DailyReportRepository repository;
  GetAllDailyReportUseCase(this.repository);

  @override
  Future<Either<Failure, List<DailyReportEntity>>> call(NoParams _) =>
      repository.getAll();
}
