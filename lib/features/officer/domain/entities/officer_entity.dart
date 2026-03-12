import 'package:equatable/equatable.dart';
import '../value_objects/officer_status.dart';

class OfficerEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final DateTime createdAt;

  const OfficerEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  OfficerEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? status,
    DateTime? createdAt,
  }) {
    return OfficerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, email, phone, role, status, createdAt];
}
