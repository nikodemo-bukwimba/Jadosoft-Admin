import 'package:equatable/equatable.dart';

class BranchEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String parentOrgId;
  final String? address;
  final String? phone;
  final int memberCount;
  final DateTime createdAt;

  const BranchEntity({
    required this.id,
    required this.name,
    this.description,
    required this.parentOrgId,
    this.address,
    this.phone,
    this.memberCount = 0,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, parentOrgId, createdAt];
}
