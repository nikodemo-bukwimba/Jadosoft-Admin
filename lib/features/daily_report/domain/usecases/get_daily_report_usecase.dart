import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/daily_report_entity.dart';
import '../repositories/daily_report_repository.dart';

class GetDailyReportParams {
  final String id;
  const GetDailyReportParams({required this.id});
}

class GetDailyReportUseCase implements UseCase<DailyReportEntity, GetDailyReportParams> {
  final DailyReportRepository repository;
  GetDailyReportUseCase(this.repository);

  @override
  Future<Either<Failure, DailyReportEntity>> call(GetDailyReportParams p) =>
      repository.getById(p.id);
}
