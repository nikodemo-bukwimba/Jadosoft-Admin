import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/daily_report_repository.dart';

class DeleteDailyReportParams {
  final String id;
  const DeleteDailyReportParams({required this.id});
}

class DeleteDailyReportUseCase implements UseCase<void, DeleteDailyReportParams> {
  final DailyReportRepository repository;
  DeleteDailyReportUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteDailyReportParams p) =>
      repository.delete(p.id);
}
