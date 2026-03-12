import 'package:equatable/equatable.dart';

class ActivityLogEntity extends Equatable {
  final String id;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? entitySnapshot;
  final String? ipAddress;
  final String? userAgent;
  final DateTime occurredAt;

  const ActivityLogEntity({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.entitySnapshot,
    this.ipAddress,
    this.userAgent,
    required this.occurredAt,
  });

  ActivityLogEntity copyWith({
    String? id,
    String? actorId,
    String? actorName,
    String? actorRole,
    String? action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? entitySnapshot,
    String? ipAddress,
    String? userAgent,
    DateTime? occurredAt,
  }) {
    return ActivityLogEntity(
      id: id ?? this.id,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actorRole: actorRole ?? this.actorRole,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      entitySnapshot: entitySnapshot ?? this.entitySnapshot,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      occurredAt: occurredAt ?? this.occurredAt,
    );
  }

  @override
  List<Object?> get props => [];
}
