// officer_detail_page.dart
// ─────────────────────────────────────────────────────────────
// Changes from original:
//   • Deactivate button now calls _confirmDeactivate() instead of
//     dispatching OfficerDeactivateRequested directly.
//   • _confirmDeactivate() shows a danger confirmation dialog that
//     requires the admin to type the officer's username exactly
//     before the Deactivate button becomes enabled — same UX
//     pattern as GitHub account deletion / repo deletion.
//   • All other behaviour (activate, suspend, delete) unchanged.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
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
          if (state is OfficerLoading || state is OfficerInitial) {
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

  // ── Content ───────────────────────────────────────────────

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
            // ── Profile card ────────────────────────────────
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

            // ── Contact info card ────────────────────────────
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
                    _contactRow(
                      context,
                      Icons.email_outlined,
                      'Email',
                      item.email,
                    ),
                    _contactRow(
                      context,
                      Icons.phone_outlined,
                      'Phone',
                      item.phone ?? 'N/A',
                    ),
                    _contactRow(
                      context,
                      Icons.badge_outlined,
                      'Role',
                      item.orgRoleName ?? 'N/A',
                    ),
                    _contactRow(
                      context,
                      Icons.business_outlined,
                      'Branch',
                      item.branchName ?? 'N/A',
                    ),
                    _contactRow(
                      context,
                      Icons.calendar_today_outlined,
                      'Joined',
                      item.createdAt?.toIso8601String().split('T').first ??
                          'N/A',
                    ),
                    _contactRow(
                      context,
                      Icons.fingerprint,
                      'User ID',
                      item.userId,
                    ),
                    _contactRow(
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

  // ── Actions card ──────────────────────────────────────────

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

    // Deactivate — requires typed confirmation before dispatching.
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

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  // ── Deactivate confirmation dialog ───────────────────────
  // Admin must type the officer's username exactly before the
  // destructive action is unlocked — same pattern as GitHub.

  Future<void> _confirmDeactivate(
    BuildContext context,
    OfficerEntity item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          _DeactivateConfirmDialog(officerName: item.displayName),
    );
    if (confirmed == true && context.mounted) {
      context.read<OfficerBloc>().add(OfficerDeactivateRequested(item.userId));
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  Widget _contactRow(
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

  Future<void> _confirmDelete(
    BuildContext context,
    String userId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Officer?'),
        content: Text('Remove "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
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

// ── Deactivate Confirmation Dialog ───────────────────────────
// Extracted as a StatefulWidget so it can own the TextField
// controller and reactively enable/disable the confirm button.

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
            // ── Warning banner ───────────────────────────
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
                    'platform access. This cannot be undone and will affect '
                    'all branches they belong to.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Confirmation input ───────────────────────
            Text(
              'To confirm, type the officer\'s username:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              widget.officerName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type username here',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _matches ? Colors.green : scheme.primary,
                    width: 2,
                  ),
                ),
                suffixIcon: _matches
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
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
