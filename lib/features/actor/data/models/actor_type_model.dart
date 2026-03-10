// actor_type_model.dart
// ─────────────────────────────────────────────────────────────
// Data model for actor types returned inline in the actors API.
// Maps JSON: { "id": 1, "code": "manufacturer", "label": "Manufacturer" }
// ─────────────────────────────────────────────────────────────

import '../../domain/entities/actor_type_entity.dart';

class ActorTypeModel extends ActorTypeEntity {
  const ActorTypeModel({
    required super.id,
    required super.code,
    required super.label,
  });

  factory ActorTypeModel.fromJson(Map<String, dynamic> json) {
    return ActorTypeModel(
      id: json['id'] as int,
      code: json['code'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'label': label,
      };

  factory ActorTypeModel.fromEntity(ActorTypeEntity entity) {
    return ActorTypeModel(
      id: entity.id,
      code: entity.code,
      label: entity.label,
    );
  }
}