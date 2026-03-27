import 'package:equatable/equatable.dart';

class OrgTreeNode extends Equatable {
  final String id;
  final String name;
  final String? type;
  final int memberCount;
  final List<OrgTreeNode> children;

  const OrgTreeNode({
    required this.id,
    required this.name,
    this.type,
    this.memberCount = 0,
    this.children = const [],
  });

  @override
  List<Object?> get props => [id, name, children.length];
}
