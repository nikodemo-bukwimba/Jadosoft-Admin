import 'package:equatable/equatable.dart';

class OrgPermissionEntity extends Equatable {
  final String id; // ← was int
  final String name;
  final String slug;
  final String? group;

  const OrgPermissionEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.group,
  });

  @override
  List<Object?> get props => [id, slug];
}

class OrgRoleEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final List<OrgPermissionEntity> permissions;
  final int memberCount;
  final bool isDefault;
  final DateTime createdAt;

  const OrgRoleEntity({
    required this.id,
    required this.name,
    this.description,
    this.permissions = const [],
    this.memberCount = 0,
    this.isDefault = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, permissions.length, createdAt];
}
