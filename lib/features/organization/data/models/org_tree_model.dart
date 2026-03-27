import '../../domain/entities/org_tree_entity.dart';

class OrgTreeNodeModel extends OrgTreeNode {
  const OrgTreeNodeModel({
    required super.id,
    required super.name,
    super.type,
    super.memberCount,
    super.children,
  });

  factory OrgTreeNodeModel.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>? ?? [];
    return OrgTreeNodeModel(
      id: json['id']?.toString() ?? json['actor_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String?,
      memberCount: json['memberships_count'] as int? ?? json['member_count'] as int? ?? 0,
      children: childrenJson.map((c) => OrgTreeNodeModel.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }
}
