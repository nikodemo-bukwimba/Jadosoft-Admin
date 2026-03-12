import '../../domain/entities/daily_report_entity.dart';
import '../../domain/usecases/create_daily_report_usecase.dart';

abstract class DailyReportEvent {}

class DailyReportLoadAllRequested extends DailyReportEvent {}

class DailyReportLoadOneRequested extends DailyReportEvent {
  final String id;
  DailyReportLoadOneRequested(this.id);
}

class DailyReportCreateRequested extends DailyReportEvent {
  final CreateDailyReportParams params;
  DailyReportCreateRequested(this.params);
}

class DailyReportUpdateRequested extends DailyReportEvent {
  final DailyReportEntity entity;
  DailyReportUpdateRequested(this.entity);
}

class DailyReportDeleteRequested extends DailyReportEvent {
  final String id;
  DailyReportDeleteRequested(this.id);
}

class DailyReportFormReset extends DailyReportEvent {}

class DailyReportSubmitRequested extends DailyReportEvent {
  final String id;
  DailyReportSubmitRequested(this.id);
}
class DailyReportApproveRequested extends DailyReportEvent {
  final String id;
  DailyReportApproveRequested(this.id);
}
class DailyReportRejectRequested extends DailyReportEvent {
  final String id;
  DailyReportRejectRequested(this.id);
}
class DailyReportResubmitRequested extends DailyReportEvent {
  final String id;
  DailyReportResubmitRequested(this.id);
}
