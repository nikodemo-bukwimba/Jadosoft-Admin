// delegation_tab.dart
// ─────────────────────────────────────────────────────────────
// Issue 5 FIX: Delegation redesigned to be concrete and actionable.
//
// WHAT IS DELEGATION (clarified):
//   Delegation = "HQ grants a specific branch the right to use a
//   specific role (and its permissions) on behalf of HQ."
//
//   Example: "Grant Mbeya Branch the Branch Manager role, so that
//   Nikodemo there can approve weekly plans."
//
//   The backend endpoint is:
//     POST /orgs/{rootOrgId}/delegations
//     { child_org_id, org_role_id, permission_ids? }
//
//   The member_user_id field in the dialog is UI-only context
//   (shown for clarity) — the backend delegates the role to the
//   entire branch, not one person. The branch admin then assigns
//   that role to specific members.
//
// DISPLAY:
//   Each delegation card shows: Branch → Role → Permissions
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/org_member_entity.dart';
import '../../domain/entities/org_role_entity.dart';
import '../../domain/entities/delegation_entity.dart';
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
                  child: _EmptyDelegations(onAdd: () => _showCreateDialog(c)),
                )
              else
                RefreshIndicator(
                  onRefresh: () async => c.read<OrganizationBloc>().add(
                    DelegationsLoadRequested(),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: s.delegations.length,
                    itemBuilder: (_, i) => _DelegationCard(
                      delegation: s.delegations[i],
                      onRevoke: () => _confirmRevoke(c, s.delegations[i]),
                    ),
                  ),
                ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => _showCreateDialog(c),
                  icon: const Icon(Icons.add),
                  label: const Text('New Delegation'),
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

  void _confirmRevoke(BuildContext context, DelegationEntity d) {
    final bloc = context.read<OrganizationBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Delegation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revoke the "${d.roleName}" delegation from "${d.childOrgName}"?',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Branch members using this delegated role will lose associated permissions.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              bloc.add(DelegationRevokeRequested(d.id));
            },
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final bloc = context.read<OrganizationBloc>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateDelegationDialog(bloc: bloc),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Delegation Card
// ═══════════════════════════════════════════════════════════
class _DelegationCard extends StatelessWidget {
  final DelegationEntity delegation;
  final VoidCallback onRevoke;
  const _DelegationCard({required this.delegation, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Arrow: HQ → Branch
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business, size: 14, color: scheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'HQ',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.arrow_forward, size: 14),
                          ),
                          Icon(
                            Icons.store_outlined,
                            size: 14,
                            color: Colors.teal,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              delegation.childOrgName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.teal,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Role badge
                      Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 13,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              delegation.roleName,
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Revoke button
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  tooltip: 'Revoke',
                  onPressed: onRevoke,
                ),
              ],
            ),

            // Permissions
            if (delegation.permissionSlugs.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Delegated Permissions',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: delegation.permissionSlugs
                    .take(8)
                    .map((p) => _PermChip(label: p))
                    .toList(),
              ),
              if (delegation.permissionSlugs.length > 8)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${delegation.permissionSlugs.length - 8} more',
                    style: TextStyle(fontSize: 11, color: scheme.primary),
                  ),
                ),
            ],

            // Date
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Granted ${_fmtDate(delegation.createdAt)}',
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ═══════════════════════════════════════════════════════════
// Create Delegation Dialog
// Issue 5 FIX: branch + role + optional member context
// ═══════════════════════════════════════════════════════════
class _CreateDelegationDialog extends StatefulWidget {
  final OrganizationBloc bloc;
  const _CreateDelegationDialog({required this.bloc});

  @override
  State<_CreateDelegationDialog> createState() =>
      _CreateDelegationDialogState();
}

class _CreateDelegationDialogState extends State<_CreateDelegationDialog> {
  List<BranchEntity> branches = [];
  List<OrgRoleEntity> roles = [];
  List<OrgMemberEntity> branchMembers = [];
  bool loading = true;
  bool loadingBranchMembers = false;

  String? selectedBranchId;
  String? selectedBranchName;
  String? selectedRoleId;
  String? selectedRoleName;
  List<String> selectedPermissionIds = [];
  String? contextMemberUserId; // UI-only: who will benefit
  List<OrgPermissionEntity> rolePermissions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rootOrgId = widget.bloc.orgContext.rootOrgId ?? '';
    final branchRes = await widget.bloc.repository.getBranches(rootOrgId);
    final rolesRes = await widget.bloc.repository.getRoles(rootOrgId);
    if (!mounted) return;
    setState(() {
      branchRes.fold((_) {}, (b) => branches = b);
      rolesRes.fold((_) {}, (r) => roles = r);
      loading = false;
    });
  }

  Future<void> _loadBranchMembers(String branchId) async {
    setState(() {
      loadingBranchMembers = true;
      branchMembers = [];
      contextMemberUserId = null;
    });
    final result = await widget.bloc.repository.getMembers(branchId);
    if (!mounted) return;
    setState(() {
      result.fold(
        (_) {},
        (m) => branchMembers = m.where((m) => m.isActive).toList(),
      );
      loadingBranchMembers = false;
    });
  }

  void _onRoleChanged(String? roleId) {
    if (roleId == null) return;
    final role = roles.firstWhere(
      (r) => r.id == roleId,
      orElse: () => roles.first,
    );
    setState(() {
      selectedRoleId = roleId;
      selectedRoleName = role.name;
      rolePermissions = role.permissions;
      // Default: delegate all permissions in the role
      selectedPermissionIds = role.permissions.map((p) => p.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 320,
          maxWidth: 480,
          maxHeight: 640,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title bar ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'New Role Delegation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Explanation
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Delegation grants a branch the ability to use a role and its permissions. '
                                    'The branch admin can then assign that role to their members.',
                                    style: TextStyle(fontSize: 12, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Step 1: Branch ─────────────────────
                          _StepLabel(
                            number: '1',
                            label: 'Select Target Branch',
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedBranchId,
                            decoration: const InputDecoration(
                              labelText: 'Branch *',
                              prefixIcon: Icon(Icons.store_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: branches
                                .map(
                                  (b) => DropdownMenuItem(
                                    value: b.id,
                                    child: Text(
                                      b.memberCount > 0
                                          ? '${b.name} · ${b.memberCount} members'
                                          : b.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                selectedBranchId = v;
                                selectedBranchName = branches
                                    .firstWhere((b) => b.id == v)
                                    .name;
                              });
                              if (v != null) _loadBranchMembers(v);
                            },
                          ),
                          const SizedBox(height: 20),

                          // ── Step 2: Role ────────────────────────
                          _StepLabel(
                            number: '2',
                            label: 'Select Role to Delegate',
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedRoleId,
                            decoration: const InputDecoration(
                              labelText: 'Role *',
                              prefixIcon: Icon(
                                Icons.admin_panel_settings_outlined,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            items: roles
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r.id,
                                    child: Text(
                                      r.permissions.isNotEmpty
                                          ? '${r.name} (${r.permissions.length} perms)'
                                          : r.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _onRoleChanged,
                          ),

                          // Show permissions of selected role
                          if (rolePermissions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Permissions included in this role:',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: rolePermissions
                                  .map((p) => _PermChip(label: p.slug))
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 20),

                          // ── Step 3: Member context (optional) ───
                          _StepLabel(
                            number: '3',
                            label: 'Who will use this role? (optional)',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select a branch member for context. This helps you remember who this delegation is for. '
                            'The branch admin can also assign this role to other members.',
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (selectedBranchId == null)
                            Text(
                              'Select a branch first to see its members.',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else if (loadingBranchMembers)
                            const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Loading members...'),
                              ],
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: contextMemberUserId,
                              decoration: const InputDecoration(
                                labelText: 'Member (optional)',
                                hintText: 'Not required',
                                prefixIcon: Icon(Icons.person_outlined),
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    '— Any branch member —',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                ...branchMembers.map(
                                  (m) => DropdownMenuItem(
                                    value: m.userId,
                                    child: Text(
                                      m.name.isNotEmpty
                                          ? '${m.name} · ${m.roleName}'
                                          : m.email,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => contextMemberUserId = v),
                            ),

                          // ── Summary ────────────────────────────
                          if (selectedBranchId != null &&
                              selectedRoleId != null) ...[
                            const SizedBox(height: 20),
                            _DelegationSummary(
                              branchName: selectedBranchName ?? '',
                              roleName: selectedRoleName ?? '',
                              permCount: rolePermissions.length,
                              memberName: branchMembers
                                  .where((m) => m.userId == contextMemberUserId)
                                  .firstOrNull
                                  ?.name,
                            ),
                          ],
                        ],
                      ),
                    ),
            ),

            // ── Actions ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: scheme.outlineVariant.withOpacity(0.4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          selectedBranchId != null && selectedRoleId != null
                          ? () {
                              Navigator.pop(context);
                              widget.bloc.add(
                                DelegationCreateRequested({
                                  'child_org_id': selectedBranchId,
                                  'org_role_id': selectedRoleId,
                                  if (selectedPermissionIds.isNotEmpty)
                                    'permission_ids': selectedPermissionIds,
                                }),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Create Delegation'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Summary card
// ═══════════════════════════════════════════════════════════
class _DelegationSummary extends StatelessWidget {
  final String branchName;
  final String roleName;
  final int permCount;
  final String? memberName;
  const _DelegationSummary({
    required this.branchName,
    required this.roleName,
    required this.permCount,
    this.memberName,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delegation Summary',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            icon: Icons.store_outlined,
            label: 'Branch',
            value: branchName,
          ),
          _SummaryRow(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Role',
            value: roleName,
          ),
          _SummaryRow(
            icon: Icons.lock_outlined,
            label: 'Permissions',
            value: '$permCount included',
          ),
          if (memberName != null && memberName!.isNotEmpty)
            _SummaryRow(
              icon: Icons.person_outlined,
              label: 'For member',
              value: memberName!,
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String number;
  final String label;
  const _StepLabel({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: scheme.primary,
          child: Text(
            number,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PermChip extends StatelessWidget {
  final String label;
  const _PermChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _EmptyDelegations extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyDelegations({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            size: 56,
            color: scheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Delegations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Delegate roles to branches so branch admins can manage their own members with appropriate permissions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Create First Delegation'),
          ),
        ],
      ),
    );
  }
}
