import 'package:flutter/material.dart';

enum NotificationStatus {
  queued,
  sent,
  delivered,
  failed,
}

extension NotificationStatusX on NotificationStatus {
  static const Map<NotificationStatus, Set<NotificationStatus>> _transitions = {
    NotificationStatus.queued:    {NotificationStatus.sent, NotificationStatus.failed},
    NotificationStatus.sent:      {NotificationStatus.delivered, NotificationStatus.failed},
    NotificationStatus.failed:    {NotificationStatus.queued},
    NotificationStatus.delivered: {},
  };

  static const NotificationStatus initial = NotificationStatus.queued;

  bool canTransitionTo(NotificationStatus target) =>
      _transitions[this]?.contains(target) ?? false;

  String get displayName => switch (this) {
    NotificationStatus.queued    => 'Queued',
    NotificationStatus.sent      => 'Sent',
    NotificationStatus.delivered => 'Delivered',
    NotificationStatus.failed    => 'Failed',
  };

  Color get color => switch (this) {
    NotificationStatus.queued    => Colors.orange,
    NotificationStatus.sent      => Colors.blue,
    NotificationStatus.delivered => Colors.green,
    NotificationStatus.failed    => Colors.red,
  };

  static NotificationStatus fromString(String? value) =>
      NotificationStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => NotificationStatus.queued,
      );
}