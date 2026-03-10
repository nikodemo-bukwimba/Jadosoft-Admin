// actor_model.dart
// ─────────────────────────────────────────────────────────────
// Data model for platform actors.
//
// Phase 2 changes:
//   - Parses actor_types from nested JSON array
//   - Parses metadata (JSONB)
//   - Handles deleted_at (nullable)
//   - toJson() sends only mutable fields for create/update
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import '../../domain/entities/actor_entity.dart';

import 'actor_type_model.dart';

class ActorModel extends ActorEntity {
  const ActorModel({
    required super.id,
    required super.displayName,
    required super.status,
    super.metadata,
    super.actorTypes,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  /// Parses from HMSCP API JSON shape:
  /// ```json
  /// {
  ///   "id": "01KK...",
  ///   "display_name": "Lockman and Sons",
  ///   "status": "active",
  ///   "metadata": null,
  ///   "actor_types": [{ "id": 1, "code": "manufacturer", "label": "Manufacturer" }],
  ///   "created_at": "2026-03-06T14:46:33+00:00",
  ///   "updated_at": "2026-03-06T14:46:33+00:00",
  ///   "deleted_at": null
  /// }
  /// ```
  factory ActorModel.fromJson(Map<String, dynamic> json) {
    // Parse nested actor_types
    final rawTypes = json['actor_types'] as List<dynamic>? ?? [];
    final types = rawTypes
        .map((t) => ActorTypeModel.fromJson(t as Map<String, dynamic>))
        .toList();

    // Parse metadata — could be null, a Map, or a JSON string
    Map<String, dynamic>? meta;
    final rawMeta = json['metadata'];
    if (rawMeta is Map<String, dynamic>) {
      meta = rawMeta;
    } else if (rawMeta is String && rawMeta.isNotEmpty) {
      meta = jsonDecode(rawMeta) as Map<String, dynamic>?;
    }

    return ActorModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      status: json['status'] as String,
      metadata: meta,
      actorTypes: types,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  /// Full serialisation — used for local cache storage.
  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'status': status,
    'metadata': metadata,
    'actor_types': actorTypes
        .map((t) => ActorTypeModel.fromEntity(t).toJson())
        .toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };

  /// Serialise only mutable fields for API create/update requests.
  /// Server ignores id, created_at, updated_at, deleted_at, actor_types.
  Map<String, dynamic> toCreateJson() => {
    'display_name': displayName,
    'status': status,
    if (metadata != null) 'metadata': metadata,
  };

  factory ActorModel.fromEntity(ActorEntity entity) {
    return ActorModel(
      id: entity.id,
      displayName: entity.displayName,
      status: entity.status,
      metadata: entity.metadata,
      actorTypes: entity.actorTypes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }
}
