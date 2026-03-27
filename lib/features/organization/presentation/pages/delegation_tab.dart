import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/org_role_entity.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/organization_event.dart';
import '../bloc/organization_state.dart';

class DelegationTab extends StatelessWidget {
  const DelegationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<OrganizationBloc, OrganizationState>(
      buildWhen: (_, s) => s is DelegationsLoaded || s is OrganizationLoading,
      builder: (c, s) {
        if (s is OrganizationLoading)
          return const Center(child: CircularProgressIndicator());
        if (s is DelegationsLoaded) {
          return Stack(
            children: [
              if (s.delegations.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        size: 48,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      const Text('No delegations configured'),
                      const SizedBox(height: 8),
                      Text(
                        'Delegate authority from HQ to branches.\nBranch admins can then manage their own area.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _showCreateDialog(c),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Delegation'),
                      ),
                    ],
                  ),
                )
              else
                RefreshIndicator(
                  onRefresh: () async => c.read<OrganizationBloc>().add(
                    DelegationsLoadRequested(),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: s.delegations.length,
                    itemBuilder: (_, i) {
                      final d = s.delegations[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: scheme.primaryContainer,
                                    radius: 18,
                                    child: Icon(
                                      Icons.swap_horiz,
                                      color: scheme.onPrimaryContainer,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.childOrgName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Role: ${d.roleName}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _confirmRevoke(c, d.id, d.childOrgName),
                                  ),
                                ],
                              ),
                              if (d.permissionSlugs.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: d.permissionSlugs
                                      .take(6)
                                      .map(
                                        (p) => Chip(
                                          label: Text(
                                            p,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      )
                                      .toList(),
                                ),
                                if (d.permissionSlugs.length > 6)
                                  Text(
                                    '+${d.permissionSlugs.length - 6} more',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.primary,
                                    ),
                                  ),
                              ],
                            ],
                          ),
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
        }
        return Center(
          child: FilledButton(
            onPressed: () =>
                c.read<OrganizationBloc>().add(DelegationsLoadRequested()),
            child: const Text('Load Delegations'),
          ),
        );
      },
    );
  }

  void _confirmRevoke(
    BuildContext context,
    String delegationId,
    String branchName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Delegation'),
        content: Text('Revoke all delegated permissions from "$branchName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OrganizationBloc>().add(
                DelegationRevokeRequested(delegationId),
              );
            },
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final bloc = context.read<OrganizationBloc>();
    bloc.add(BranchesLoadRequested());
    bloc.add(RolesLoadRequested());

    String? selectedBranchId;
    String? selectedRoleId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Delegation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Delegate a role and its permissions to a branch. The branch admin can then manage users with those permissions.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                BlocBuilder<OrganizationBloc, OrganizationState>(
                  bloc: bloc, // ← fix
                  buildWhen: (_, s) => s is BranchesLoaded,
                  builder: (c, s) {
                    final branches = s is BranchesLoaded
                        ? s.branches
                        : <BranchEntity>[];
                    return DropdownButtonFormField<String>(
                      value: selectedBranchId,
                      decoration: const InputDecoration(
                        labelText: 'Branch *',
                        prefixIcon: Icon(Icons.store_outlined),
                      ),
                      items: branches
                          .map(
                            (b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(b.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedBranchId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),
                BlocBuilder<OrganizationBloc, OrganizationState>(
                  bloc: bloc, // ← fix
                  buildWhen: (_, s) => s is RolesLoaded,
                  builder: (c, s) {
                    final roles = s is RolesLoaded
                        ? s.roles
                        : <OrgRoleEntity>[];
                    return DropdownButtonFormField<String>(
                      value: selectedRoleId,
                      decoration: const InputDecoration(
                        labelText: 'Role to Delegate *',
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                      items: roles
                          .map(
                            (r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(r.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedRoleId = v),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (selectedBranchId == null || selectedRoleId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Select both branch and role'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                bloc.add(
                  DelegationCreateRequested({
                    // ← bloc, not context.read
                    'child_org_id': selectedBranchId,
                    'org_role_id': selectedRoleId,
                  }),
                );
              },
              child: const Text('Delegate'),
            ),
          ],
        ),
      ),
    );
  }
}
