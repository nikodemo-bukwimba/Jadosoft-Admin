import '../../domain/entities/daily_report_entity.dart';

abstract class DailyReportState {}

class DailyReportInitial extends DailyReportState {}
class DailyReportLoading extends DailyReportState {}

class DailyReportListLoaded extends DailyReportState {
  final List<DailyReportEntity> items;
  DailyReportListLoaded(this.items);
}

class DailyReportDetailLoaded extends DailyReportState {
  final DailyReportEntity item;
  DailyReportDetailLoaded(this.item);
}

class DailyReportOperationSuccess extends DailyReportState {
  final String message;
  final DailyReportEntity? updatedItem;
  DailyReportOperationSuccess(this.message, {this.updatedItem});
}

class DailyReportEmpty extends DailyReportState {}

class DailyReportFailure extends DailyReportState {
  final String message;
  DailyReportFailure(this.message);
}
