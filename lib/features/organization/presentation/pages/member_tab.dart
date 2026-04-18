// member_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/org_member_entity.dart';
import '../../domain/entities/org_role_entity.dart';
import '../../domain/entities/branch_entity.dart';
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
      buildWhen: (_, s) =>
          s is MembersLoaded ||
          s is OrganizationLoading ||
          s is UserManagementSuccess,
      builder: (c, s) {
        if (s is OrganizationLoading)
          return const Center(child: CircularProgressIndicator());

        if (s is MembersLoaded) {
          return Column(
            children: [
              if (viewingBranchId != null)
                _BranchScopeBar(onBack: onBackToRootMembers),
              Expanded(
                child: s.members.isEmpty
                    ? _EmptyState(
                        isBranch: viewingBranchId != null,
                        onInvite: () => _showInviteDialog(c),
                        onAssign: viewingBranchId != null
                            ? () => _showAssignDialog(c, viewingBranchId!)
                            : null,
                      )
                    : Stack(
                        children: [
                          RefreshIndicator(
                            onRefresh: () async =>
                                c.read<OrganizationBloc>().add(
                                  MembersLoadRequested(orgId: viewingBranchId),
                                ),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                80,
                              ),
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
                                onRemove: (uid) => _confirmRemove(c, uid),
                                onManageAccount: (member) =>
                                    _showManageAccountSheet(c, member),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: FloatingActionButton.extended(
                              onPressed: () => viewingBranchId != null
                                  ? _showAssignDialog(c, viewingBranchId!)
                                  : _showInviteDialog(c),
                              icon: Icon(
                                viewingBranchId != null
                                    ? Icons.person_add_alt_1
                                    : Icons.person_add,
                              ),
                              label: Text(
                                viewingBranchId != null ? 'Assign' : 'Invite',
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

  // ── Invite Dialog — email + branch + role ────────────────
  void _showInviteDialog(BuildContext context) {
    final bloc = context.read<OrganizationBloc>();
    showDialog(
      context: context,
      builder: (_) => _InviteDialog(bloc: bloc),
    );
  }

  // ── Assign Dialog — member from root + role ──────────────
  void _showAssignDialog(BuildContext context, String branchId) {
    final bloc = context.read<OrganizationBloc>();
    showDialog(
      context: context,
      builder: (_) => _AssignDialog(bloc: bloc, branchId: branchId),
    );
  }

  void _confirmRemove(BuildContext context, String userId) {
    final bloc = context.read<OrganizationBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Remove this member from the organization?'),
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

  // ── Manage Account Sheet ─────────────────────────────────
  void _showManageAccountSheet(BuildContext context, OrgMemberEntity member) {
    final bloc = context.read<OrganizationBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ManageAccountSheet(bloc: bloc, member: member),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Invite Dialog — email + branch selection + role
// Issue 3 FIX: invitation now includes the target branch
// ═══════════════════════════════════════════════════════════
class _InviteDialog extends StatefulWidget {
  final OrganizationBloc bloc;
  const _InviteDialog({required this.bloc});

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _emailCtrl = TextEditingController();
  final _levelCtrl = TextEditingController(text: '50');
  List<BranchEntity> branches = [];
  List<OrgRoleEntity> roles = [];
  bool loading = true;
  String? selectedBranchId; // which branch they'll join
  String? selectedRoleId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _levelCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rootOrgId = widget.bloc.orgContext.rootOrgId ?? '';
    final branchRes = await widget.bloc.repository.getBranches(rootOrgId);
    final rolesRes = await widget.bloc.repository.getRoles(rootOrgId);
    if (!mounted) return;
    setState(() {
      branchRes.fold((_) {}, (b) => branches = b);
      rolesRes.fold((_) {}, (r) => roles = r);
      // Default target = root org (no specific branch)
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite Member'),
      content: loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info banner
                  _InfoBanner(
                    icon: Icons.info_outline,
                    color: Colors.blue,
                    text:
                        'An invitation email will be sent. Select the branch and role the user will join.',
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      hintText: 'officer@company.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),

                  // Branch selector — Issue 3 FIX
                  DropdownButtonFormField<String>(
                    value: selectedBranchId,
                    decoration: const InputDecoration(
                      labelText: 'Target Branch *',
                      hintText: 'Select the branch they will join',
                      prefixIcon: Icon(Icons.store_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: widget.bloc.orgContext.rootOrgId,
                        child: const Text('HQ (Root Organization)'),
                      ),
                      ...branches.map(
                        (b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => selectedBranchId = v),
                  ),
                  const SizedBox(height: 12),

                  // Role selector
                  DropdownButtonFormField<String>(
                    value: selectedRoleId,
                    decoration: const InputDecoration(
                      labelText: 'Role *',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(
                              r.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedRoleId = v),
                  ),
                  const SizedBox(height: 12),

                  // Authority Level
                  TextField(
                    controller: _levelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Authority Level (0–100)',
                      prefixIcon: Icon(Icons.trending_up),
                      helperText: '100 = full authority, 0 = view only',
                      border: OutlineInputBorder(),
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
          onPressed: loading
              ? null
              : () {
                  if (_emailCtrl.text.trim().isEmpty) {
                    _snack(context, 'Enter an email address');
                    return;
                  }
                  if (selectedBranchId == null) {
                    _snack(context, 'Select a target branch');
                    return;
                  }
                  if (selectedRoleId == null) {
                    _snack(context, 'Select a role');
                    return;
                  }
                  Navigator.pop(context);
                  widget.bloc.add(
                    MemberInviteRequested(
                      orgId: selectedBranchId!, // ← the target branch
                      data: {
                        'email': _emailCtrl.text.trim(),
                        'org_role_id': selectedRoleId,
                        'level': int.tryParse(_levelCtrl.text.trim()) ?? 50,
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

// ═══════════════════════════════════════════════════════════
// Assign Dialog — for assigning existing root members to branch
// ═══════════════════════════════════════════════════════════
class _AssignDialog extends StatefulWidget {
  final OrganizationBloc bloc;
  final String branchId;
  const _AssignDialog({required this.bloc, required this.branchId});

  @override
  State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  List<OrgMemberEntity> rootMembers = [];
  List<OrgRoleEntity> roles = [];
  bool loading = true;
  String? selectedUserId;
  String? selectedRoleId;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rootOrgId = widget.bloc.orgContext.rootOrgId ?? '';
    final membersRes = await widget.bloc.repository.getMembers(rootOrgId);
    final rolesRes = await widget.bloc.repository.getRoles(rootOrgId);
    if (!mounted) return;
    setState(() {
      membersRes.fold((f) => error = f.message, (m) => rootMembers = m);
      rolesRes.fold((f) => error ??= f.message, (r) => roles = r);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Member to Branch'),
      content: loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : error != null
          ? Text(error!, style: const TextStyle(color: Colors.red))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _InfoBanner(
                    icon: Icons.info_outline,
                    color: Colors.green,
                    text:
                        'Assign an existing organization member to this branch with a specific role.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Member *',
                      prefixIcon: Icon(Icons.person_outlined),
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: rootMembers
                        .where((m) => m.isActive)
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.userId,
                            child: Text(
                              m.name.isNotEmpty
                                  ? '${m.name} · ${m.roleName}'
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
                      border: OutlineInputBorder(),
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
                    _snack(context, 'Select both a member and a role');
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
// Manage Account Bottom Sheet — Issue 1: user management
// ═══════════════════════════════════════════════════════════
class _ManageAccountSheet extends StatefulWidget {
  final OrganizationBloc bloc;
  final OrgMemberEntity member;
  const _ManageAccountSheet({required this.bloc, required this.member});

  @override
  State<_ManageAccountSheet> createState() => _ManageAccountSheetState();
}

class _ManageAccountSheetState extends State<_ManageAccountSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member.name);
    _emailCtrl = TextEditingController(text: widget.member.email);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final member = widget.member;

    return BlocListener<OrganizationBloc, OrganizationState>(
      bloc: widget.bloc,
      listener: (ctx, state) {
        if (state is UserManagementSuccess) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (state is OrganizationFailure) {
          setState(() {
            _saving = false;
            _saveError = state.message;
          });
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle bar ─────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      radius: 20,
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Account',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            member.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),

              // ── Update Name ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_saveError != null)
                      Text(
                        _saveError!,
                        style: TextStyle(color: scheme.error, fontSize: 12),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: _saving
                                ? null
                                : () {
                                    final name = _nameCtrl.text.trim();
                                    if (name.isEmpty) return;
                                    setState(() {
                                      _saving = true;
                                      _saveError = null;
                                    });
                                    widget.bloc.add(
                                      UserInfoUpdateRequested(
                                        userId: member.userId,
                                        name: name,
                                      ),
                                    );
                                  },
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Update Name'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 28),

              // ── Password Reset ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_reset_outlined),
                      title: const Text('Reset Password'),
                      subtitle: Text(
                        'Send a password reset email to ${member.email}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: SizedBox(
                        width: 90,
                        child: TextButton(
                          onPressed: () => _confirmPasswordReset(context),
                          child: const Text(
                            'Send Email',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 28),

              // ── Account Status ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Status',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Issue 4: permission-aware status actions
                    if (member.isActive)
                      _StatusActionTile(
                        icon: Icons.pause_circle_outline,
                        color: Colors.orange,
                        label: 'Suspend Account',
                        description: 'User cannot log in while suspended',
                        onTap: () {
                          Navigator.pop(context);
                          widget.bloc.add(
                            UserStatusUpdateRequested(
                              userId: member.userId,
                              status: 'suspended',
                            ),
                          );
                        },
                      ),
                    if (member.isSuspended)
                      _StatusActionTile(
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                        label: 'Reactivate Account',
                        description: 'Allow user to log in again',
                        onTap: () {
                          Navigator.pop(context);
                          widget.bloc.add(
                            UserStatusUpdateRequested(
                              userId: member.userId,
                              status: 'active',
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmPasswordReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Password Reset?'),
        content: Text(
          'A password reset link will be emailed to ${widget.member.email}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.bloc.add(UserPasswordResetRequested(widget.member.email));
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════

class _BranchScopeBar extends StatelessWidget {
  final VoidCallback? onBack;
  const _BranchScopeBar({this.onBack});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: scheme.primaryContainer.withOpacity(0.3),
        child: Row(
          children: [
            Icon(Icons.store, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Branch members',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 14),
              label: const Text('All Members', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isBranch;
  final VoidCallback? onInvite;
  final VoidCallback? onAssign;
  const _EmptyState({required this.isBranch, this.onInvite, this.onAssign});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(isBranch ? 'No members in this branch' : 'No members yet'),
          const SizedBox(height: 8),
          if (isBranch && onAssign != null)
            ElevatedButton.icon(
              onPressed: onAssign,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Assign Member'),
            ),
          if (!isBranch && onInvite != null)
            ElevatedButton.icon(
              onPressed: onInvite,
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Member'),
            ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String description;
  final VoidCallback onTap;
  const _StatusActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      trailing: SizedBox(
        width: 80,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text('Apply', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
