import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/create_notification_usecase.dart';

abstract class NotificationEvent {}

class NotificationLoadAllRequested extends NotificationEvent {}

class NotificationLoadOneRequested extends NotificationEvent {
  final String id;
  NotificationLoadOneRequested(this.id);
}

class NotificationCreateRequested extends NotificationEvent {
  final CreateNotificationParams params;
  NotificationCreateRequested(this.params);
}

class NotificationUpdateRequested extends NotificationEvent {
  final NotificationEntity entity;
  NotificationUpdateRequested(this.entity);
}

class NotificationDeleteRequested extends NotificationEvent {
  final String id;
  NotificationDeleteRequested(this.id);
}

class NotificationFormReset extends NotificationEvent {}

class NotificationRetryRequested extends NotificationEvent {
  final String id;
  NotificationRetryRequested(this.id);
}
