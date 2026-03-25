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
  final String? notes;
  WeeklyPlanApproveRequested(this.id, {this.notes});
}
class WeeklyPlanRejectRequested extends WeeklyPlanEvent {
  final String id;
  final String notes;
  WeeklyPlanRejectRequested(this.id, {required this.notes});
}
class WeeklyPlanResubmitRequested extends WeeklyPlanEvent {
  final String id;
  WeeklyPlanResubmitRequested(this.id);
}
