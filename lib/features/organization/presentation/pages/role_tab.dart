import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/organization_event.dart';
import '../bloc/organization_state.dart';
import '../widgets/role_card_tile.dart';
import '../../domain/entities/org_role_entity.dart';

class RoleTab extends StatelessWidget {
  const RoleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationBloc, OrganizationState>(
      buildWhen: (_, s) =>
          s is RolesLoaded ||
          s is OrganizationLoading ||
          s is OrganizationFailure,
      builder: (c, s) {
        if (s is OrganizationLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s is RolesLoaded) {
          if (s.roles.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.admin_panel_settings_outlined, size: 48),
                  const SizedBox(height: 12),
                  const Text('No roles defined'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showCreateDialog(c),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Role'),
                  ),
                ],
              ),
            );
          }

          final availablePerms = s.availablePermissions;

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async =>
                    c.read<OrganizationBloc>().add(RolesLoadRequested()),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: s.roles.length,
                  itemBuilder: (_, i) => RoleCardTile(
                    role: s.roles[i],
                    availablePermissions: availablePerms,
                    onSyncPermissions: (roleId, permissionIds) {
                      c.read<OrganizationBloc>().add(
                        RolePermissionsSyncRequested(
                          roleId: roleId,
                          permissionIds: permissionIds,
                        ),
                      );
                    },
                    onDelete: (roleId) => _confirmDelete(c, s.roles[i]),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: () => _showCreateDialog(c),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          );
        }
        return Center(
          child: FilledButton(
            onPressed: () =>
                c.read<OrganizationBloc>().add(RolesLoadRequested()),
            child: const Text('Load Roles'),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, OrgRoleEntity role) {
    if (role.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('System roles cannot be deleted.')),
      );
      return;
    }
    if (role.memberCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete "${role.name}": ${role.memberCount} active member(s) assigned. Reassign them first.',
          ),
        ),
      );
      return;
    }

    final bloc = context.read<OrganizationBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text(
          'Are you sure you want to delete "${role.name}"?\n\n'
          'All permissions assigned to this role will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(RoleDeleteRequested(role.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Role Name *',
                hintText: 'e.g. Branch Manager',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context.read<OrganizationBloc>().add(
                RoleCreateRequested({
                  'name': nameCtrl.text.trim(),
                  if (descCtrl.text.trim().isNotEmpty)
                    'description': descCtrl.text.trim(),
                }),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
