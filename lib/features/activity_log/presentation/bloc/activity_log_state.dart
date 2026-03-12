import '../../domain/entities/activity_log_entity.dart';

abstract class ActivityLogState {}

class ActivityLogInitial          extends ActivityLogState {}
class ActivityLogLoading           extends ActivityLogState {}

class ActivityLogListLoaded extends ActivityLogState {
  final List<ActivityLogEntity> items;
  ActivityLogListLoaded(this.items);
}

class ActivityLogDetailLoaded extends ActivityLogState {
  final ActivityLogEntity item;
  ActivityLogDetailLoaded(this.item);
}

class ActivityLogOperationSuccess extends ActivityLogState {
  final String message;
  ActivityLogOperationSuccess(this.message);
}

class ActivityLogEmpty extends ActivityLogState {}

class ActivityLogFailure extends ActivityLogState {
  final String message;
  ActivityLogFailure(this.message);
}
