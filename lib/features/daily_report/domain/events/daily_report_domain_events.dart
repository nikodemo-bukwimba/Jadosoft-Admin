import '../entities/daily_report_entity.dart';

/// Base class for all DailyReport domain events.
abstract class DailyReportDomainEvent {
  final String entityId;
  final Map<String, dynamic>? payload;
  final DateTime occurredAt;

  DailyReportDomainEvent({
    required this.entityId,
    this.payload,
    DateTime? occurredAt,
  }) : occurredAt = occurredAt ?? DateTime.now();

  String get name;

  Map<String, dynamic> toMap() => {
    'event':      name,
    'entityId':   entityId,
    'occurredAt': occurredAt.toIso8601String(),
    if (payload != null) 'payload': payload,
  };
}

class DailyReportCreatedEvent extends DailyReportDomainEvent {
  DailyReportCreatedEvent({required super.entityId, super.payload, super.occurredAt});

  @override
  String get name => 'daily_report.created';
}

class DailyReportUpdatedEvent extends DailyReportDomainEvent {
  DailyReportUpdatedEvent({required super.entityId, super.payload, super.occurredAt});

  @override
  String get name => 'daily_report.updated';
}

class DailyReportStatusChangedEvent extends DailyReportDomainEvent {
  final String fromStatus;
  final String toStatus;

  DailyReportStatusChangedEvent({
    required super.entityId,
    required this.fromStatus,
    required this.toStatus,
    super.payload,
    super.occurredAt,
  });

  @override
  String get name => 'daily_report.status_changed';

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'fromStatus': fromStatus,
    'toStatus':   toStatus,
  };
}

class DailyReportDeletedEvent extends DailyReportDomainEvent {
  DailyReportDeletedEvent({required super.entityId, super.payload, super.occurredAt});

  @override
  String get name => 'daily_report.deleted';
}

class DailyReportNotifyadminonsubmitEvent extends DailyReportDomainEvent {
  DailyReportNotifyadminonsubmitEvent({
    required super.entityId,
    super.payload,
    super.occurredAt,
  });

  @override
  String get name => 'notifyAdminOnSubmit';
}

class DailyReportNotifyofficerapprovedEvent extends DailyReportDomainEvent {
  DailyReportNotifyofficerapprovedEvent({
    required super.entityId,
    super.payload,
    super.occurredAt,
  });

  @override
  String get name => 'notifyOfficerApproved';
}

class DailyReportNotifyofficerrejectedEvent extends DailyReportDomainEvent {
  DailyReportNotifyofficerrejectedEvent({
    required super.entityId,
    super.payload,
    super.occurredAt,
  });

  @override
  String get name => 'notifyOfficerRejected';
}
