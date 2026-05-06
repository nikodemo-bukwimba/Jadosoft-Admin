// lib/features/organization/presentation/pages/member_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
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

  static const _staffCategories = {'owner', 'manager', 'officer'};

  List<OrgMemberEntity> _toStaffList(List<OrgMemberEntity> raw) {
    final Map<String, OrgMemberEntity> seen = {};
    for (final m in raw) {
      if (!_staffCategories.contains(m.roleCategory)) continue;
      final existing = seen[m.userId];
      if (existing == null || m.authorityLevel > existing.authorityLevel) {
        seen[m.userId] = m;
      }
    }
    return seen.values.toList()
      ..sort((a, b) => b.authorityLevel.compareTo(a.authorityLevel));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrganizationBloc, OrganizationState>(
      // MemberInvitedWithToken is handled at OrganizationHubPage level —
      // do NOT handle it here to avoid stale-context sheet failures.
      listener: (context, state) {
        if (state is OrganizationOperationSuccess) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
        if (state is OrganizationFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      },
      child: BlocBuilder<OrganizationBloc, OrganizationState>(
        buildWhen: (_, s) =>
            s is MembersLoaded ||
            s is OrganizationLoading ||
            s is UserManagementSuccess,
        builder: (c, s) {
          if (s is OrganizationLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s is MembersLoaded) {
            final staffMembers = _toStaffList(s.members);
            return Column(
              children: [
                if (viewingBranchId != null)
                  _BranchScopeBar(onBack: onBackToRootMembers),
                Expanded(
                  child: staffMembers.isEmpty
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
                                    MembersLoadRequested(
                                      orgId: viewingBranchId,
                                    ),
                                  ),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  80,
                                ),
                                itemCount: staffMembers.length,
                                itemBuilder: (_, i) => MemberCardTile(
                                  member: staffMembers[i],
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
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final bloc = context.read<OrganizationBloc>();
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (_) => _InviteDialog(bloc: bloc, messenger: messenger),
    );
  }

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

<<<<<<< HEAD
// ── Branch scope bar ──────────────────────────────────────────
=======
// ── Branch scope bar ──────────────────────────────────────────────
>>>>>>> promotion_and_bulk_sms
class _BranchScopeBar extends StatelessWidget {
  final VoidCallback? onBack;
  const _BranchScopeBar({this.onBack});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.primaryContainer.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.store_outlined, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Viewing branch members',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(onPressed: onBack, child: const Text('Back to all')),
        ],
      ),
    );
  }
}

<<<<<<< HEAD
// ═══════════════════════════════════════════════════════════
// Invite Dialog — email + branch + role → emits MemberInvitedWithToken
// ═══════════════════════════════════════════════════════════
=======
// ═══════════════════════════════════════════════════════════════════
// Invite Dialog
// ═══════════════════════════════════════════════════════════════════
>>>>>>> promotion_and_bulk_sms
class _InviteDialog extends StatefulWidget {
  final OrganizationBloc bloc;
  final ScaffoldMessengerState messenger;
  const _InviteDialog({required this.bloc, required this.messenger});

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _emailCtrl = TextEditingController();
  final _levelCtrl = TextEditingController(text: '50');

  List<BranchEntity> branches = [];
  List<OrgRoleEntity> roles = [];
  bool loading = true;
<<<<<<< HEAD
  // FIX: These start null; the dropdown value: binding controls them correctly.
=======

  // FIX: Use value: (controlled) not initialValue: (uncontrolled).
  // initialValue is read-only on first render — it NEVER reflects
  String? selectedBranchId;
  String? selectedRoleId;

  @override
  void initState() {
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
      rolesRes.fold((_) {}, (r) {
        final seen = <String, OrgRoleEntity>{};
        for (final role in r) {
          seen[role.id] ??= role;
        }
        roles = seen.values.toList()..sort((a, b) => a.name.compareTo(b.name));
      });
      loading = false;
    });
  }

  void _submit() {
    if (_emailCtrl.text.trim().isEmpty) {
      _snack('Enter an email address');
      return;
    }
    if (selectedBranchId == null) {
      _snack('Select a target branch or HQ');
      return;
    }
    if (selectedRoleId == null) {
      _snack('Select a role');
      return;
    }
    final bloc = widget.bloc;
    Navigator.of(context).pop();
    bloc.add(
      MemberInviteRequested(
        orgId: selectedBranchId!,
        data: {
          'email': _emailCtrl.text.trim(),
          'org_role_id': selectedRoleId,
          'level': int.tryParse(_levelCtrl.text.trim()) ?? 50,
        },
      ),
    );
  }

  void _snack(String msg) {
    widget.messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
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
                  _InfoBanner(
                    icon: Icons.info_outline,
                    color: Colors.blue,
                    text:
                        'An invitation email will be sent. You will also '
                        'receive a token to share via WhatsApp.',
                  ),
                  const SizedBox(height: 16),

                  // ── Email ────────────────────────────────────
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
<<<<<<< HEAD
                  // FIX: Use `value:` not `initialValue:`.
                  // `initialValue` is read-only on first render and does NOT
                  // reflect state changes after async load. `value:` is the
                  // controlled prop that keeps the dropdown in sync with state.
                  DropdownButtonFormField<String>(
                    value: selectedBranchId,
=======

                  // ── Branch — value: (controlled) ─────────────
                    ),
                    items: [
                      DropdownMenuItem(
                        value: widget.bloc.orgContext.rootOrgId,
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
<<<<<<< HEAD
                  // FIX: Use `value:` not `initialValue:`.
                  DropdownButtonFormField<String>(
                    value: selectedRoleId,
=======

                  // ── Role — value: (controlled) ───────────────
                  DropdownButtonFormField<String>(
                    value: selectedRoleId, // ← FIX
>>>>>>> promotion_and_bulk_sms
                    decoration: const InputDecoration(
                      labelText: 'Role *',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedRoleId = v),
                  ),

                  // ── Level ────────────────────────────────────
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: loading ? null : _submit,
          child: const Text('Send Invitation'),
        ),
      ],
    );
  }
}

<<<<<<< HEAD
// ═══════════════════════════════════════════════════════════
// Invitation Token Bottom Sheet
// ═══════════════════════════════════════════════════════════
=======
// ═══════════════════════════════════════════════════════════════════
// Invitation Token Sheet — called from OrganizationHubPage listener
// ═══════════════════════════════════════════════════════════════════
>>>>>>> promotion_and_bulk_sms
class InvitationTokenSheet extends StatelessWidget {
  final String email;
  final String token;
  final String orgName;

  const InvitationTokenSheet({
    super.key,
    required this.email,
    required this.token,
    required this.orgName,
  });

  /// Call this from OrganizationHubPage's BlocConsumer listener.
  static void show(
    BuildContext context, {
    required String email,
    required String token,
    required String orgName,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          InvitationTokenSheet(email: email, token: token, orgName: orgName),
    );
  }

  String get _whatsAppMessage =>
      'You have been invited to join *$orgName* on Barick Pharma.\n\n'
      'To accept:\n'
      '1. Open the *Barick Officer* app\n'
      '2. Register/login with: *$email*\n'
      '3. Tap *Enter Invitation Token* and paste:\n\n'
      '$token\n\n'
      'Token expires in 7 days.';

  Future<void> _shareWhatsApp(BuildContext context) async {
    final uri = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(_whatsAppMessage)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp not found on this device.')),
      );
    }
  }

  Future<void> _copyToken(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token copied.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _copyMessage(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _whatsAppMessage));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full message copied.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invitation Sent',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'To: $email',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'An email has been sent. Share the token below via WhatsApp '
            'so the user can accept immediately.\n'
            'You can also view this token later in the Invitations tab.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Token box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INVITATION TOKEN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  token.isNotEmpty ? token : '(token not returned by server)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: token.isNotEmpty ? null : scheme.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: token.isNotEmpty ? () => _copyToken(context) : null,
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Token Only'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 8),

          FilledButton.icon(
            onPressed: () => _shareWhatsApp(context),
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share via WhatsApp'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 8),

          TextButton.icon(
            onPressed: () => _copyMessage(context),
            icon: const Icon(Icons.message_outlined, size: 16),
            label: const Text('Copy Full Message'),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
          const SizedBox(height: 4),

          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Assign Dialog
// ═══════════════════════════════════════════════════════════════════
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
<<<<<<< HEAD
  // FIX: Use value: binding — starts null, controlled by setState.
  String? selectedUserId;
  String? selectedRoleId;
=======
  String? selectedUserId; // ← controlled with value:
  String? selectedRoleId; // ← controlled with value:
>>>>>>> promotion_and_bulk_sms
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
      membersRes.fold((f) => error = f.message, (m) {
        final seen = <String, OrgMemberEntity>{};
        for (final member in m) {
          if (!member.isActive) continue;
          final existing = seen[member.userId];
          if (existing == null ||
              member.authorityLevel > existing.authorityLevel) {
            seen[member.userId] = member;
          }
        }
        rootMembers = seen.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      });
      rolesRes.fold((f) => error ??= f.message, (r) {
        final seen = <String, OrgRoleEntity>{};
        for (final role in r) {
          seen[role.id] ??= role;
        }
        roles = seen.values.toList()..sort((a, b) => a.name.compareTo(b.name));
      });
      loading = false;
    });
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                        'Assign an existing org member to this branch '
                        'with a specific role.',
                  ),
                  const SizedBox(height: 16),
                  // FIX: value: instead of initialValue:
                  DropdownButtonFormField<String>(
<<<<<<< HEAD
                    value: selectedUserId,
=======
                    value: selectedUserId, // ← FIX
>>>>>>> promotion_and_bulk_sms
                    decoration: const InputDecoration(
                      labelText: 'Member *',
                      prefixIcon: Icon(Icons.person_outlined),
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: rootMembers
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
                  // FIX: value: instead of initialValue:
                  DropdownButtonFormField<String>(
<<<<<<< HEAD
                    value: selectedRoleId,
=======
                    value: selectedRoleId, // ← FIX
>>>>>>> promotion_and_bulk_sms
                    decoration: const InputDecoration(
                      labelText: 'Branch Role *',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
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

// ═══════════════════════════════════════════════════════════════════
// Manage Account Sheet
// ═══════════════════════════════════════════════════════════════════
class _ManageAccountSheet extends StatefulWidget {
  final OrganizationBloc bloc;
  final OrgMemberEntity member;
  const _ManageAccountSheet({required this.bloc, required this.member});

  @override
  State<_ManageAccountSheet> createState() => _ManageAccountSheetState();
}

class _ManageAccountSheetState extends State<_ManageAccountSheet> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
                    if (_saveError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _saveError!,
                        style: TextStyle(color: scheme.error, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
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
                            : const Text('Save Name'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Account Actions',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _StatusActionTile(
                      icon: Icons.lock_reset,
                      color: Colors.orange,
                      label: 'Reset Password',
                      description: 'Send a password reset email',
                      onTap: () {
                        Navigator.pop(context);
                        widget.bloc.add(
                          UserPasswordResetRequested(member.email),
                        );
                      },
                    ),
                    if (member.isActive)
                      _StatusActionTile(
                        icon: Icons.pause_circle_outline,
                        color: Colors.red,
                        label: 'Suspend Account',
                        description: 'Prevent login temporarily',
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
                        icon: Icons.play_circle_outline,
                        color: Colors.green,
                        label: 'Reactivate Account',
                        description: 'Restore login access',
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
<<<<<<< HEAD

// ── Shared helpers ────────────────────────────────────────────
=======
>>>>>>> promotion_and_bulk_sms

// ── Shared helpers ─────────────────────────────────────────────────
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
        color: color.withValues(alpha: 0.08),
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
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.9),
              ),
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
