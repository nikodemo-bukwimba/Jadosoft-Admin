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
          // Get permissions from a separate state — store last known in bloc or use local var
          // Since BLoC emits one state at a time, keep permissions in a local variable
          // by reading from the previous state or using a secondary BlocBuilder.
          return BlocBuilder<OrganizationBloc, OrganizationState>(
            buildWhen: (_, s) => s is PermissionsLoaded,
            builder: (pc, ps) {
              final perms = ps is PermissionsLoaded
                  ? ps.permissions
                  : <OrgPermissionEntity>[];
              return Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: s.roles.length,
                    itemBuilder: (_, i) => RoleCardTile(
                      role: s.roles[i],
                      availablePermissions: perms,
                      onSyncPermissions: (roleId, permissionIds) {
                        c.read<OrganizationBloc>().add(
                          RolePermissionsSyncRequested(
                            roleId: roleId,
                            permissionIds: permissionIds,
                          ),
                        );
                      },
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
            },
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
