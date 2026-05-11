// lib/features/officer/presentation/pages/officer_detail_page.dart
// No logic changes from your version — only the two bloc captures fixed
// (blocs captured BEFORE showDialog, passed into the dialog directly).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../../organization/domain/entities/branch_entity.dart';
import '../../../organization/domain/entities/org_role_entity.dart';
import '../../../organization/presentation/bloc/organization_bloc.dart';
import '../../../organization/presentation/bloc/organization_state.dart';
import '../../domain/entities/officer_entity.dart';
import '../../domain/value_objects/officer_status.dart';
import '../bloc/officer_bloc.dart';
import '../bloc/officer_event.dart';
import '../bloc/officer_state.dart';
import '../widgets/officer_avatar.dart';
import '../widgets/officer_status_badge.dart';

class OfficerDetailPage extends StatelessWidget {
  const OfficerDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Detail'),
        actions: [
          BlocBuilder<OfficerBloc, OfficerState>(
            builder: (context, state) {
              if (state is OfficerDetailLoaded) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () => context.push(
                        AppRouter.officerEditPath(state.item.userId),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: scheme.error),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(
                        context,
                        state.item.userId,
                        state.item.displayName,
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<OfficerBloc, OfficerState>(
        listener: (context, state) {
          if (state is OfficerOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            if (state.updatedItem != null) {
              context.read<OfficerBloc>().add(
                OfficerLoadOneRequested(state.updatedItem!.userId),
              );
            } else {
              context.pop();
            }
          }
          if (state is OfficerFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OfficerLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OfficerFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: scheme.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
          if (state is OfficerDetailLoaded) {
            return _buildContent(context, state.item);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, OfficerEntity item) {
    final scheme = Theme.of(context).colorScheme;
    final statusEnum = OfficerStatusX.fromString(item.effectiveStatus);
    final isWide = MediaQuery.of(context).size.width >= 600;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? MediaQuery.of(context).size.width * 0.1 : 16,
        vertical: 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile card ───────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    OfficerAvatar(
                      name: item.displayName,
                      status: item.effectiveStatus,
                      radius: 36,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Problem #1 fix: displayName resolves to fullName
                          Text(
                            item.displayName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.orgRoleName ?? '',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (item.branchName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.branchName!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                          const SizedBox(height: 8),
                          OfficerStatusBadge(status: statusEnum),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildActions(context, item, statusEnum),
            const SizedBox(height: 12),

            // ── Contact info card ──────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(height: 24),
                    _infoRow(
                      context,
                      Icons.email_outlined,
                      'Email',
                      item.email,
                    ),
                    _infoRow(
                      context,
                      Icons.phone_outlined,
                      'Phone',
                      item.phone ?? 'N/A',
                    ),
                    _infoRow(
                      context,
                      Icons.badge_outlined,
                      'Role',
                      item.orgRoleName ?? 'N/A',
                    ),
                    _infoRow(
                      context,
                      Icons.business_outlined,
                      'Branch',
                      item.branchName ?? 'N/A',
                    ),
                    _infoRow(
                      context,
                      Icons.calendar_today_outlined,
                      'Joined',
                      item.createdAt?.toIso8601String().split('T').first ??
                          'N/A',
                    ),
                    _infoRow(
                      context,
                      Icons.fingerprint,
                      'User ID',
                      item.userId,
                    ),
                    _infoRow(
                      context,
                      Icons.perm_identity,
                      'Actor ID',
                      item.actorId,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ── Actions card ───────────────────────────────────────────

  Widget _buildActions(
    BuildContext context,
    OfficerEntity item,
    OfficerStatus statusEnum,
  ) {
    final actions = <Widget>[];

    if (statusEnum == OfficerStatus.suspended) {
      actions.add(
        _actionButton(
          context,
          icon: Icons.check_circle_outline,
          label: 'Activate',
          color: Colors.green,
          onPressed: () => context.read<OfficerBloc>().add(
            OfficerActivateRequested(item.userId),
          ),
        ),
      );
    }

    if (statusEnum == OfficerStatus.active) {
      actions.add(
        _actionButton(
          context,
          icon: Icons.pause_circle_outline,
          label: 'Suspend',
          color: Colors.orange,
          onPressed: () => context.read<OfficerBloc>().add(
            OfficerSuspendRequested(item.userId),
          ),
        ),
      );
    }

    // Transfer Branch — visible for active or suspended officers
    if (statusEnum != OfficerStatus.deactivated && item.branchId.isNotEmpty) {
      actions.add(
        _actionButton(
          context,
          icon: Icons.swap_horiz_outlined,
          label: 'Transfer Branch',
          color: Theme.of(context).colorScheme.primary,
          onPressed: () => _showTransferDialog(context, item),
        ),
      );
    }

    if (statusEnum == OfficerStatus.active ||
        statusEnum == OfficerStatus.suspended) {
      actions.add(
        _actionButton(
          context,
          icon: Icons.cancel_outlined,
          label: 'Deactivate',
          color: Colors.grey.shade600,
          onPressed: () => _confirmDeactivate(context, item),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(height: 20),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ),
      ),
    );
  }

  // FIX: capture blocs BEFORE entering showDialog — the dialog's BuildContext
  // is detached from the widget tree and cannot find inherited blocs.
  void _showTransferDialog(BuildContext context, OfficerEntity officer) {
    final officerBloc = context.read<OfficerBloc>();
    final orgBloc = context.read<OrganizationBloc>();

    showDialog(
      context: context,
      builder: (_) => _TransferBranchDialog(
        officerBloc: officerBloc,
        orgBloc: orgBloc,
        officer: officer,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) => FilledButton.tonalIcon(
    onPressed: onPressed,
    icon: Icon(icon, size: 18, color: color),
    label: Text(label),
    style: FilledButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
  );

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivate(
    BuildContext context,
    OfficerEntity item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeactivateConfirmDialog(officerName: item.displayName),
    );
    if (confirmed == true && context.mounted) {
      context.read<OfficerBloc>().add(OfficerDeactivateRequested(item.userId));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String userId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Officer?'),
        content: Text('Remove "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<OfficerBloc>().add(OfficerDeleteRequested(userId));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Transfer Branch Dialog
// ═══════════════════════════════════════════════════════════════════

class _TransferBranchDialog extends StatefulWidget {
  final OfficerBloc officerBloc;
  final OrganizationBloc orgBloc;
  final OfficerEntity officer;

  const _TransferBranchDialog({
    required this.officerBloc,
    required this.orgBloc,
    required this.officer,
  });

  @override
  State<_TransferBranchDialog> createState() => _TransferBranchDialogState();
}

class _TransferBranchDialogState extends State<_TransferBranchDialog> {
  List<BranchEntity> _branches = [];
  List<OrgRoleEntity> _roles = [];
  bool _loading = true;
  String? _error;

  BranchEntity? _selectedBranch;
  OrgRoleEntity? _selectedRole;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<BranchEntity> branches = [];
    List<OrgRoleEntity> roles = [];

    // Use cached state when available
    final orgState = widget.orgBloc.state;
    if (orgState is BranchesLoaded) branches = orgState.branches;
    if (orgState is RolesLoaded) roles = orgState.roles;

    // Otherwise fetch directly via repository
    if (branches.isEmpty) {
      final rootOrgId = widget.orgBloc.orgContext.rootOrgId ?? '';
      final res = await widget.orgBloc.repository.getBranches(rootOrgId);
      res.fold((f) => _error = f.message, (b) => branches = b);
    }
    if (roles.isEmpty) {
      final rootOrgId = widget.orgBloc.orgContext.rootOrgId ?? '';
      final res = await widget.orgBloc.repository.getRoles(rootOrgId);
      res.fold((f) => _error ??= f.message, (r) => roles = r);
    }

    if (!mounted) return;
    setState(() {
      // Exclude current branch from targets
      _branches =
          branches.where((b) => b.id != widget.officer.branchId).toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      // Deduplicate roles
      final seen = <String, OrgRoleEntity>{};
      for (final r in roles) seen[r.id] ??= r;
      _roles = seen.values.toList()..sort((a, b) => a.name.compareTo(b.name));

      // Pre-select current role
      try {
        _selectedRole = _roles.firstWhere(
          (r) => r.id == widget.officer.orgRoleId,
        );
      } catch (_) {
        _selectedRole = null;
      }

      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.swap_horiz_outlined, color: scheme.primary),
          const SizedBox(width: 10),
          const Text('Transfer Branch'),
        ],
      ),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
          ? Text(_error!, style: TextStyle(color: scheme.error))
          : _branches.isEmpty
          ? const Text('No other branches available.')
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current branch info
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'From: ${widget.officer.branchName ?? widget.officer.branchId}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<BranchEntity>(
                    value: _selectedBranch,
                    decoration: const InputDecoration(
                      labelText: 'Transfer to Branch *',
                      prefixIcon: Icon(Icons.store_outlined),
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: _branches
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text(
                              b.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBranch = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<OrgRoleEntity>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role in New Branch *',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: _roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedRole = v),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (!_loading && _error == null && _branches.isNotEmpty)
          FilledButton.icon(
            onPressed: (_selectedBranch == null || _selectedRole == null)
                ? null
                : () {
                    Navigator.pop(context);
                    widget.officerBloc.add(
                      OfficerReassignBranchRequested(
                        userId: widget.officer.userId,
                        fromBranchId: widget.officer.branchId,
                        toBranchId: _selectedBranch!.id,
                        orgRoleId: _selectedRole!.id,
                      ),
                    );
                  },
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text('Transfer'),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Deactivate Confirmation Dialog
// ═══════════════════════════════════════════════════════════════════

class _DeactivateConfirmDialog extends StatefulWidget {
  final String officerName;
  const _DeactivateConfirmDialog({required this.officerName});

  @override
  State<_DeactivateConfirmDialog> createState() =>
      _DeactivateConfirmDialogState();
}

class _DeactivateConfirmDialogState extends State<_DeactivateConfirmDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final match = _controller.text.trim() == widget.officerName.trim();
      if (match != _matches) setState(() => _matches = match);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final errorColor = scheme.error;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: errorColor, size: 24),
          const SizedBox(width: 10),
          const Text('Deactivate Officer'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: errorColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: errorColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This action is permanent.',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: errorColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deactivating ${widget.officerName} will revoke all '
                    'platform access. This cannot be undone.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "To confirm, type the officer's name:",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.officerName,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                color: errorColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type name here',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _matches ? errorColor : scheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _matches
                ? errorColor
                : scheme.surfaceContainerHighest,
            foregroundColor: _matches
                ? scheme.onError
                : scheme.onSurfaceVariant,
          ),
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text('Deactivate'),
        ),
      ],
    );
  }
}
