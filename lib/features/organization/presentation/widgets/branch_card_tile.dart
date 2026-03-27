import 'package:flutter/material.dart';
import '../../domain/entities/branch_entity.dart';

class BranchCardTile extends StatelessWidget {
  final BranchEntity branch;
  final void Function(String branchId)? onViewMembers;
  final void Function(String branchId)? onDelete;
  const BranchCardTile({
    super.key,
    required this.branch,
    this.onViewMembers,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.store, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (branch.address != null && branch.address!.isNotEmpty)
                        Text(
                          branch.address!,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        '${branch.memberCount} members',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    switch (v) {
                      case 'members':
                        onViewMembers?.call(branch.id);
                        break;
                      case 'delete':
                        onDelete?.call(branch.id);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'members',
                      child: Row(
                        children: [
                          Icon(Icons.people_outline, size: 18),
                          SizedBox(width: 8),
                          Text('View Members'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete Branch',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (branch.description != null &&
                branch.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                branch.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
