// actor_type_entity.dart
// ─────────────────────────────────────────────────────────────
// Represents a platform actor type (manufacturer, retailer, etc.)
// Returned inline inside the Actor API response:
//   "actor_types": [{ "id": 1, "code": "manufacturer", "label": "Manufacturer" }]
// ─────────────────────────────────────────────────────────────

import 'package:equatable/equatable.dart';

class ActorTypeEntity extends Equatable {
  final int id;
  final String code;
  final String label;

  const ActorTypeEntity({
    required this.id,
    required this.code,
    required this.label,
  });

  @override
  List<Object?> get props => [id, code, label];
}
