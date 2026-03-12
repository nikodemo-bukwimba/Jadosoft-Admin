import '../../domain/entities/activity_log_entity.dart';
import '../../domain/usecases/create_activity_log_usecase.dart';

abstract class ActivityLogEvent {}

class ActivityLogLoadAllRequested extends ActivityLogEvent {}

class ActivityLogLoadOneRequested extends ActivityLogEvent {
  final String id;
  ActivityLogLoadOneRequested(this.id);
}

class ActivityLogCreateRequested extends ActivityLogEvent {
  final CreateActivityLogParams params;
  ActivityLogCreateRequested(this.params);
}

class ActivityLogUpdateRequested extends ActivityLogEvent {
  final ActivityLogEntity entity;
  ActivityLogUpdateRequested(this.entity);
}

class ActivityLogDeleteRequested extends ActivityLogEvent {
  final String id;
  ActivityLogDeleteRequested(this.id);
}

class ActivityLogFormReset extends ActivityLogEvent {}
