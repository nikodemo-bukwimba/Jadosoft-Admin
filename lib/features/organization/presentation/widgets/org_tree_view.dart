import 'package:flutter/material.dart';
import '../../domain/entities/org_tree_entity.dart';

class OrgTreeView extends StatelessWidget {
  final OrgTreeNode root;
  const OrgTreeView({super.key, required this.root});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildNode(context, root, 0));
  }

  Widget _buildNode(BuildContext context, OrgTreeNode node, int depth) {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(left: depth * 24.0), child: Card(child: ListTile(
        leading: Icon(depth == 0 ? Icons.business : Icons.store_outlined, color: scheme.primary),
        title: Text(node.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${node.memberCount} members', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      ))),
      ...node.children.map((c) => _buildNode(context, c, depth + 1)),
    ]);
  }
}
