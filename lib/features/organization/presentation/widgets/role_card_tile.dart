import 'package:flutter/material.dart';
import '../../domain/entities/org_role_entity.dart';

class RoleCardTile extends StatelessWidget {
  final OrgRoleEntity role;
  final List<OrgPermissionEntity> availablePermissions;
  final void Function(String roleId, List<String> permissionIds)?
  onSyncPermissions;
  final void Function(String roleId)? onDelete;

  const RoleCardTile({
    super.key,
    required this.role,
    required this.availablePermissions,
    this.onSyncPermissions,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: scheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    role.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (role.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'System',
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    switch (v) {
                      case 'permissions':
                        _showPermissionsDialog(context);
                        break;
                      case 'delete':
                        onDelete?.call(role.id);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'permissions',
                      child: Row(
                        children: [
                          Icon(Icons.tune, size: 18),
                          SizedBox(width: 8),
                          Text('Manage Permissions'),
                        ],
                      ),
                    ),
                    if (!role.isDefault)
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
                              'Delete Role',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${role.permissions.length} permissions  •  ${role.memberCount} members',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            if (role.description != null) ...[
              const SizedBox(height: 4),
              Text(
                role.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (role.permissions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: role.permissions
                    .take(8)
                    .map(
                      (p) => Chip(
                        label: Text(
                          p.slug,
                          style: const TextStyle(fontSize: 10),
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
              if (role.permissions.length > 8)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${role.permissions.length - 8} more',
                    style: TextStyle(fontSize: 11, color: scheme.primary),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPermissionsDialog(BuildContext context) {
    final selectedIds = role.permissions.map((p) => p.id).toSet();

    final Map<String, List<OrgPermissionEntity>> grouped = {};
    for (final p in availablePermissions) {
      final key = p.group ?? 'General';
      grouped.putIfAbsent(key, () => []).add(p);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Permissions: ${role.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: availablePermissions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No permissions available. Run the permissions seeder migration on the server.',
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select permissions to assign to this role.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...grouped.entries.map(
                          (entry) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 4,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _formatGroupName(entry.key),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${entry.value.length})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...entry.value.map(
                                (p) => CheckboxListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    p.slug,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    p.name,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  value: selectedIds.contains(p.id),
                                  onChanged: (v) => setDialogState(() {
                                    if (v == true)
                                      selectedIds.add(p.id);
                                    else
                                      selectedIds.remove(p.id);
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: availablePermissions.isEmpty
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      onSyncPermissions?.call(role.id, selectedIds.toList());
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatGroupName(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
