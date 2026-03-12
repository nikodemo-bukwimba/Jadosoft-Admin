import '../../domain/entities/weekly_plan_entity.dart';
import '../../domain/usecases/create_weekly_plan_usecase.dart';

abstract class WeeklyPlanEvent {}

class WeeklyPlanLoadAllRequested extends WeeklyPlanEvent {}

class WeeklyPlanLoadOneRequested extends WeeklyPlanEvent {
  final String id;
  WeeklyPlanLoadOneRequested(this.id);
}

class WeeklyPlanCreateRequested extends WeeklyPlanEvent {
  final CreateWeeklyPlanParams params;
  WeeklyPlanCreateRequested(this.params);
}

class WeeklyPlanUpdateRequested extends WeeklyPlanEvent {
  final WeeklyPlanEntity entity;
  WeeklyPlanUpdateRequested(this.entity);
}

class WeeklyPlanDeleteRequested extends WeeklyPlanEvent {
  final String id;
  WeeklyPlanDeleteRequested(this.id);
}

class WeeklyPlanFormReset extends WeeklyPlanEvent {}

class WeeklyPlanApproveRequested extends WeeklyPlanEvent {
  final String id;
  WeeklyPlanApproveRequested(this.id);
}
class WeeklyPlanRejectRequested extends WeeklyPlanEvent {
  final String id;
  WeeklyPlanRejectRequested(this.id);
}
class WeeklyPlanResubmitRequested extends WeeklyPlanEvent {
  final String id;
  WeeklyPlanResubmitRequested(this.id);
}
