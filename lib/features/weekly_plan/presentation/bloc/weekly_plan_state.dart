import '../../domain/entities/weekly_plan_entity.dart';

abstract class WeeklyPlanState {}

class WeeklyPlanInitial extends WeeklyPlanState {}
class WeeklyPlanLoading extends WeeklyPlanState {}

class WeeklyPlanListLoaded extends WeeklyPlanState {
  final List<WeeklyPlanEntity> items;
  WeeklyPlanListLoaded(this.items);
}

class WeeklyPlanDetailLoaded extends WeeklyPlanState {
  final WeeklyPlanEntity item;
  WeeklyPlanDetailLoaded(this.item);
}

class WeeklyPlanOperationSuccess extends WeeklyPlanState {
  final String message;
  final WeeklyPlanEntity? updatedItem;
  WeeklyPlanOperationSuccess(this.message, {this.updatedItem});
}

class WeeklyPlanEmpty extends WeeklyPlanState {}

class WeeklyPlanFailure extends WeeklyPlanState {
  final String message;
  WeeklyPlanFailure(this.message);
}
