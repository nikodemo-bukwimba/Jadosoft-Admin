import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/daily_report_entity.dart';
import '../repositories/daily_report_repository.dart';

class UpdateDailyReportParams {
  final DailyReportEntity entity;
  const UpdateDailyReportParams({required this.entity});
}

class UpdateDailyReportUseCase implements UseCase<DailyReportEntity, UpdateDailyReportParams> {
  final DailyReportRepository repository;
  UpdateDailyReportUseCase(this.repository);

  @override
  Future<Either<Failure, DailyReportEntity>> call(UpdateDailyReportParams p) async {
    return repository.update(p.entity);
  }
}
