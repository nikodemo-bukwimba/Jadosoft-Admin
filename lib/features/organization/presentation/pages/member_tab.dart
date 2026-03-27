import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/org_role_entity.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/organization_event.dart';
import '../bloc/organization_state.dart';
import '../widgets/member_card_tile.dart';

class MemberTab extends StatelessWidget {
  const MemberTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationBloc, OrganizationState>(
      buildWhen: (_, s) => s is MembersLoaded || s is OrganizationLoading,
      builder: (c, s) {
        if (s is OrganizationLoading)
          return const Center(child: CircularProgressIndicator());
        if (s is MembersLoaded) {
          if (s.members.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text('No members'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showInviteDialog(c),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Invite Member'),
                  ),
                ],
              ),
            );
          }
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async =>
                    c.read<OrganizationBloc>().add(MembersLoadRequested()),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: s.members.length,
                  itemBuilder: (_, i) => MemberCardTile(
                    member: s.members[i],
                    onSuspend: (uid) => c.read<OrganizationBloc>().add(
                      MemberUpdateRequested(
                        userId: uid,
                        data: {'status': 'suspended'},
                      ),
                    ),
                    onActivate: (uid) => c.read<OrganizationBloc>().add(
                      MemberUpdateRequested(
                        userId: uid,
                        data: {'status': 'active'},
                      ),
                    ),
                    onRemove: (uid) =>
                        _confirmRemove(c, c.read<OrganizationBloc>(), uid),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: () => _showInviteDialog(c),
                  child: const Icon(Icons.person_add),
                ),
              ),
            ],
          );
        }
        return Center(
          child: FilledButton(
            onPressed: () =>
                c.read<OrganizationBloc>().add(MembersLoadRequested()),
            child: const Text('Load Members'),
          ),
        );
      },
    );
  }

  void _showInviteDialog(BuildContext context) {
    final bloc = context.read<OrganizationBloc>();
    bloc.add(RolesLoadRequested());

    final emailCtrl = TextEditingController();
    final levelCtrl = TextEditingController(text: '50');
    String? selectedRoleId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Invite Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'An invitation email will be sent. The user must accept it to join the organization.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    hintText: 'officer@company.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
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
                        labelText: 'Role *',
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                      items: [
                        if (roles.isEmpty)
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Loading roles...'),
                          ),
                        ...roles.map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(r.name),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => selectedRoleId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: levelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Authority Level (0-100)',
                    hintText: '50',
                    prefixIcon: Icon(Icons.trending_up),
                    helperText: '100 = full authority, 0 = view only',
                  ),
                  keyboardType: TextInputType.number,
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
                if (emailCtrl.text.trim().isEmpty) return;
                if (selectedRoleId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a role')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                bloc.add(
                  MemberInviteRequested(
                    data: {
                      // ← bloc, not context.read
                      'email': emailCtrl.text.trim(),
                      'org_role_id': selectedRoleId,
                      'level': int.tryParse(levelCtrl.text.trim()) ?? 50,
                    },
                  ),
                );
              },
              child: const Text('Send Invitation'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(
    BuildContext context,
    OrganizationBloc bloc,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text(
          'This will remove the member from the organization. Are you sure?',
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
              bloc.add(MemberRemoveRequested(userId: userId));
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
