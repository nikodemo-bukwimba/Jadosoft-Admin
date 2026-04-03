import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/org_role_entity.dart';
import '../../domain/entities/org_member_entity.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/organization_event.dart';
import '../bloc/organization_state.dart';
import '../widgets/member_card_tile.dart';

class MemberTab extends StatelessWidget {
  final String? viewingBranchId;
  final VoidCallback? onBackToRootMembers;

  const MemberTab({super.key, this.viewingBranchId, this.onBackToRootMembers});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationBloc, OrganizationState>(
      buildWhen: (_, s) => s is MembersLoaded || s is OrganizationLoading,
      builder: (c, s) {
        if (s is OrganizationLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s is MembersLoaded) {
          return Column(
            children: [
              if (viewingBranchId != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: Theme.of(
                    c,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  child: Row(
                    children: [
                      Icon(
                        Icons.store,
                        size: 16,
                        color: Theme.of(c).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Viewing branch members',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(c).colorScheme.primary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onBackToRootMembers,
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text(
                          'All Members',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: s.members.isEmpty
                    ? _emptyState(c)
                    : Stack(
                        children: [
                          RefreshIndicator(
                            onRefresh: () async =>
                                c.read<OrganizationBloc>().add(
                                  MembersLoadRequested(orgId: viewingBranchId),
                                ),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: s.members.length,
                              itemBuilder: (_, i) => MemberCardTile(
                                member: s.members[i],
                                onSuspend: (uid) =>
                                    c.read<OrganizationBloc>().add(
                                      MemberUpdateRequested(
                                        orgId: viewingBranchId,
                                        userId: uid,
                                        data: {'status': 'suspended'},
                                      ),
                                    ),
                                onActivate: (uid) =>
                                    c.read<OrganizationBloc>().add(
                                      MemberUpdateRequested(
                                        orgId: viewingBranchId,
                                        userId: uid,
                                        data: {'status': 'active'},
                                      ),
                                    ),
                                onRemove: (uid) => _confirmRemove(
                                  c,
                                  c.read<OrganizationBloc>(),
                                  uid,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: FloatingActionButton(
                              onPressed: () => viewingBranchId != null
                                  ? _showAssignDialog(c, viewingBranchId!)
                                  : _showInviteDialog(c),
                              tooltip: viewingBranchId != null
                                  ? 'Assign Member'
                                  : 'Invite Member',
                              child: Icon(
                                viewingBranchId != null
                                    ? Icons.person_add_alt_1
                                    : Icons.person_add,
                              ),
                            ),
                          ),
                        ],
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

  Widget _emptyState(BuildContext c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 48),
          const SizedBox(height: 12),
          Text(
            viewingBranchId != null
                ? 'No members in this branch'
                : 'No members',
          ),
          const SizedBox(height: 8),
          if (viewingBranchId != null) ...[
            Text(
              'Assign existing organization members\nto this branch.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(c).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showAssignDialog(c, viewingBranchId!),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Assign Member'),
            ),
          ] else ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _showInviteDialog(c),
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Member'),
            ),
          ],
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context, String branchId) {
    final bloc = context.read<OrganizationBloc>();
    showDialog(
      context: context,
      builder: (_) => _AssignMemberDialog(
        bloc: bloc,
        rootOrgId: bloc.orgContext.rootOrgId ?? '',
        branchId: branchId,
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final bloc = context.read<OrganizationBloc>();
    showDialog(
      context: context,
      builder: (_) => _InviteDialogContent(bloc: bloc),
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
              bloc.add(
                MemberRemoveRequested(orgId: viewingBranchId, userId: userId),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Assign Member Dialog — loads data from repository directly
// Does NOT trigger BLoC state changes (no OrganizationLoading)
// ═══════════════════════════════════════════════════════════

class _AssignMemberDialog extends StatefulWidget {
  final OrganizationBloc bloc;
  final String rootOrgId;
  final String branchId;

  const _AssignMemberDialog({
    required this.bloc,
    required this.rootOrgId,
    required this.branchId,
  });

  @override
  State<_AssignMemberDialog> createState() => _AssignMemberDialogState();
}

class _AssignMemberDialogState extends State<_AssignMemberDialog> {
  List<OrgMemberEntity> rootMembers = [];
  List<OrgRoleEntity> roles = [];
  bool loading = true;
  String? error;
  String? selectedUserId;
  String? selectedRoleId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final membersResult = await widget.bloc.repository.getMembers(
      widget.rootOrgId,
    );
    final rolesResult = await widget.bloc.repository.getRoles(widget.rootOrgId);

    if (!mounted) return;

    setState(() {
      membersResult.fold(
        (f) => error = 'Failed to load members: ${f.message}',
        (m) => rootMembers = m,
      );
      rolesResult.fold(
        (f) => error = error ?? 'Failed to load roles: ${f.message}',
        (r) => roles = r,
      );
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Member to Branch'),
      content: loading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : error != null
          ? Text(error!, style: const TextStyle(color: Colors.red))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Select a member from your organization to assign to this branch.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Member *',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    isExpanded: true,
                    items: rootMembers
                        .where((m) => m.isActive)
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.userId,
                            child: Text(
                              m.name.isNotEmpty
                                  ? '${m.name} (${m.email})'
                                  : m.email,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedUserId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRoleId,
                    decoration: const InputDecoration(
                      labelText: 'Branch Role *',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    isExpanded: true,
                    items: roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(r.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedRoleId = v),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: loading || error != null
              ? null
              : () {
                  if (selectedUserId == null || selectedRoleId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Select both a member and a role'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  widget.bloc.add(
                    MemberAssignToBranchRequested(
                      branchId: widget.branchId,
                      data: {
                        'user_id': selectedUserId,
                        'org_role_id': selectedRoleId,
                      },
                    ),
                  );
                },
          child: const Text('Assign'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Invite Dialog — loads roles from repository directly
// ═══════════════════════════════════════════════════════════

class _InviteDialogContent extends StatefulWidget {
  final OrganizationBloc bloc;

  const _InviteDialogContent({required this.bloc});

  @override
  State<_InviteDialogContent> createState() => _InviteDialogContentState();
}

class _InviteDialogContentState extends State<_InviteDialogContent> {
  final emailCtrl = TextEditingController();
  final levelCtrl = TextEditingController(text: '50');
  List<OrgRoleEntity> roles = [];
  bool loading = true;
  String? selectedRoleId;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    levelCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    final rootOrgId = widget.bloc.orgContext.rootOrgId ?? '';
    final result = await widget.bloc.repository.getRoles(rootOrgId);
    if (!mounted) return;
    setState(() {
      result.fold((_) {}, (r) => roles = r);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : DropdownButtonFormField<String>(
                    value: selectedRoleId,
                    decoration: const InputDecoration(
                      labelText: 'Role *',
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
                    onChanged: (v) => setState(() => selectedRoleId = v),
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
          onPressed: () => Navigator.pop(context),
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
            Navigator.pop(context);
            widget.bloc.add(
              MemberInviteRequested(
                data: {
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
    );
  }
}
