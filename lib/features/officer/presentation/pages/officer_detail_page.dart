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
                      onPressed: () => context.push(AppRouter.officerEditPath(state.item.id)),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: scheme.error),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(context, state.item.id, state.item.name),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            if (state.updatedItem != null) {
              context.read<OfficerBloc>().add(OfficerLoadOneRequested(state.updatedItem!.id));
            } else {
              context.pop();
            }
          }
          if (state is OfficerFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: scheme.error),
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

  Widget _buildContent(BuildContext context, OfficerEntity item) {
    final scheme = Theme.of(context).colorScheme;
    final statusEnum = OfficerStatusX.fromString(item.status);
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
            // ── Profile Header Card ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    OfficerAvatar(name: item.name, status: item.status, radius: 36),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.role,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

            // ── Actions Card (L2 State Machine) ──
            _buildActions(context, item, statusEnum),

            // ── Contact Info Card ──
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact Information',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: scheme.primary, fontWeight: FontWeight.w700)),
                    const Divider(height: 24),
                    _contactRow(context, Icons.email_outlined, 'Email', item.email),
                    _contactRow(context, Icons.phone_outlined, 'Phone', item.phone),
                    _contactRow(context, Icons.badge_outlined, 'Role', item.role),
                    _contactRow(context, Icons.calendar_today_outlined, 'Joined',
                        item.createdAt.toIso8601String().split('T').first),
                    _contactRow(context, Icons.fingerprint, 'ID', item.id),
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

  Widget _buildActions(BuildContext context, OfficerEntity item, OfficerStatus statusEnum) {
    final actions = <Widget>[];

    // suspended → active
    if (statusEnum == OfficerStatus.suspended) {
      actions.add(_actionButton(context,
          icon: Icons.check_circle_outline, label: 'Activate', color: Colors.green,
          onPressed: () => context.read<OfficerBloc>().add(OfficerActivateRequested(item.id))));
    }
    // active → suspended
    if (statusEnum == OfficerStatus.active) {
      actions.add(_actionButton(context,
          icon: Icons.pause_circle_outline, label: 'Suspend', color: Colors.orange,
          onPressed: () => context.read<OfficerBloc>().add(OfficerSuspendRequested(item.id))));
    }
    // active/suspended → deactivated
    if (statusEnum == OfficerStatus.active || statusEnum == OfficerStatus.suspended) {
      actions.add(_actionButton(context,
          icon: Icons.cancel_outlined, label: 'Deactivate', color: Colors.grey,
          onPressed: () => context.read<OfficerBloc>().add(OfficerDeactivateRequested(item.id))));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
            const Divider(height: 20),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context,
      {required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
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

  Widget _contactRow(BuildContext context, IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Officer?'),
        content: Text('Remove "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<OfficerBloc>().add(OfficerDeleteRequested(id));
    }
  }
}