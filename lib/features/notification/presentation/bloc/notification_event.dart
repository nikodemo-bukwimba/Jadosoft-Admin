// notification_event.dart
abstract class NotificationEvent {}

class NotificationLoadAllRequested extends NotificationEvent {
  final String? status;
  final String? channel;
  final int perPage;
  final int page;

  NotificationLoadAllRequested({
    this.status,
    this.channel,
    this.perPage = 50,
    this.page = 1,
  });
}

class NotificationLoadOneRequested extends NotificationEvent {
  final String id;
  NotificationLoadOneRequested(this.id);
}

class NotificationRetryRequested extends NotificationEvent {
  final String id;
  NotificationRetryRequested(this.id);
}

/// Fired when the user changes a status or channel filter chip.
class NotificationFilterChanged extends NotificationEvent {
  final String? status;
  final String? channel;
  NotificationFilterChanged({this.status, this.channel});
}

class NotificationFormReset extends NotificationEvent {}
