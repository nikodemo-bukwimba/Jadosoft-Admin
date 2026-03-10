// actor_entity.dart
// ─────────────────────────────────────────────────────────────
// Domain entity for a platform actor.
//
// Phase 2 changes:
//   - Added actorTypes (many-to-many from API response)
//   - Added metadata (JSONB flexible extension data)
//   - Added deletedAt (soft delete support)
// ─────────────────────────────────────────────────────────────

import 'package:equatable/equatable.dart';
import 'actor_type_entity.dart';

class ActorEntity extends Equatable {
  final String id;
  final String displayName;
  final String status;
  final Map<String, dynamic>? metadata;
  final List<ActorTypeEntity> actorTypes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ActorEntity({
    required this.id,
    required this.displayName,
    required this.status,
    this.metadata,
    this.actorTypes = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  ActorEntity copyWith({
    String? id,
    String? displayName,
    String? status,
    Map<String, dynamic>? metadata,
    List<ActorTypeEntity>? actorTypes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ActorEntity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      actorTypes: actorTypes ?? this.actorTypes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Convenience: comma-separated type labels for display.
  String get typeLabels =>
      actorTypes.map((t) => t.label).join(', ');

  @override
  List<Object?> get props => [
        id,
        displayName,
        status,
        metadata,
        actorTypes,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}