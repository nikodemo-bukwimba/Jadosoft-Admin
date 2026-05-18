// notification_state.dart
import '../../domain/entities/notification_entity.dart';

abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationListLoaded extends NotificationState {
  final List<NotificationEntity> items;
  final String? statusFilter;
  final String? channelFilter;

  NotificationListLoaded(this.items, {this.statusFilter, this.channelFilter});
}

class NotificationDetailLoaded extends NotificationState {
  final NotificationEntity item;
  NotificationDetailLoaded(this.item);
}

class NotificationOperationSuccess extends NotificationState {
  final String message;
  final NotificationEntity? updatedItem;
  NotificationOperationSuccess(this.message, {this.updatedItem});
}

class NotificationEmpty extends NotificationState {}

class NotificationFailure extends NotificationState {
  final String message;
  NotificationFailure(this.message);
}
