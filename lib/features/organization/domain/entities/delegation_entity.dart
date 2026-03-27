import 'package:equatable/equatable.dart';

class DelegationEntity extends Equatable {
  final String id;
  final String parentOrgId;
  final String childOrgId;
  final String childOrgName;
  final String roleName;
  final List<String> permissionSlugs;
  final DateTime createdAt;

  const DelegationEntity({
    required this.id,
    required this.parentOrgId,
    required this.childOrgId,
    required this.childOrgName,
    required this.roleName,
    this.permissionSlugs = const [],
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, parentOrgId, childOrgId, createdAt];
}
