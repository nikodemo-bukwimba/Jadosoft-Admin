import '../../domain/entities/officer_entity.dart';

class OfficerModel extends OfficerEntity {
  const OfficerModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    required super.status,
    required super.createdAt,
  });

  factory OfficerModel.fromJson(Map<String, dynamic> json) {
    return OfficerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };

  factory OfficerModel.fromEntity(OfficerEntity entity) {
    return OfficerModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      role: entity.role,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }
}