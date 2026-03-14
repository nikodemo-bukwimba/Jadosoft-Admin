import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/value_objects/notification_status.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notification_status_badge.dart';
import '../widgets/notification_channel_badge.dart';

class NotificationDetailPage extends StatelessWidget {
  const NotificationDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          if (state.updatedItem != null) {
            context.read<NotificationBloc>().add(
              NotificationLoadOneRequested(state.updatedItem!.id),
            );
          }
        }
        if (state is NotificationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is NotificationLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Notification')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is NotificationDetailLoaded) {
          return _DetailView(item: state.item);
        }
        if (state is NotificationFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Notification')),
            body: Center(child: Text(state.message)),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Notification')),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

// ─── Detail View ───────────────────────────────────────────────────────────

class _DetailView extends StatelessWidget {
  final NotificationEntity item;
  const _DetailView({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = NotificationStatusX.fromString(item.status);
    final isFailed = status == NotificationStatus.failed;
    final isWide = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notification #${item.id}'),
        centerTitle: false,
        actions: [
          NotificationStatusBadge(status: status),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 48 : 16,
          vertical: 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Recipient ──────────────────────────────────
                _SectionCard(
                  title: 'Recipient',
                  icon: Icons.person_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 32,
                        runSpacing: 12,
                        children: [
                          _InfoBlock(label: 'ID', value: item.recipientId),
                          _InfoBlock(
                            label: 'Type',
                            value: item.recipientType == 'officer'
                                ? 'Marketing Officer'
                                : 'Customer',
                          ),
                          _InfoBlock(
                            label: 'Channel',
                            valueWidget: NotificationChannelBadge(
                              channel: item.channel,
                            ),
                          ),
                          if (item.templateId != null)
                            _InfoBlock(
                              label: 'Template',
                              value: item.templateId,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // ── View Recipient button ──────────────
                      // Navigates to the officer/customer profile so admin
                      // can fix wrong phone numbers before retrying delivery
                      OutlinedButton.icon(
                        onPressed: () {
                          if (item.recipientType == 'officer') {
                            context.go('/officers/${item.recipientId}');
                          } else {
                            context.go('/customers/${item.recipientId}');
                          }
                        },
                        icon: Icon(
                          item.recipientType == 'officer'
                              ? Icons.badge_outlined
                              : Icons.storefront_outlined,
                          size: 16,
                        ),
                        label: Text(
                          item.recipientType == 'officer'
                              ? 'View Officer Profile'
                              : 'View Customer Profile',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                      // Hint shown only on failed notifications
                      if (isFailed) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'If the failure is due to a wrong phone number, '
                                'open the profile above, fix the number, then retry.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Message Content ────────────────────────────
                _SectionCard(
                  title: 'Message Content',
                  icon: Icons.message_outlined,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.content,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Delivery Timeline ──────────────────────────
                _SectionCard(
                  title: 'Delivery Timeline',
                  icon: Icons.timeline_outlined,
                  child: Column(
                    children: [
                      _TimelineRow(
                        icon: Icons.add_circle_outline,
                        label: 'Created',
                        time: item.createdAt,
                        color: theme.colorScheme.primary,
                        isDone: true,
                      ),
                      _TimelineRow(
                        icon: Icons.send_outlined,
                        label: 'Sent',
                        time: item.sentAt,
                        color: Colors.blue,
                        isDone: item.sentAt != null,
                      ),
                      _TimelineRow(
                        icon: Icons.done_all_outlined,
                        label: 'Delivered',
                        time: item.deliveredAt,
                        color: Colors.green,
                        isDone: item.deliveredAt != null,
                        isLast: !isFailed,
                      ),
                      if (isFailed)
                        _TimelineRow(
                          icon: Icons.error_outline,
                          label: 'Failed',
                          time: null,
                          color: Colors.red,
                          isDone: true,
                          isLast: true,
                          isError: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Failure Reason ─────────────────────────────
                if (isFailed && item.failureReason != null) ...[
                  _SectionCard(
                    title: 'Failure Reason',
                    icon: Icons.warning_amber_outlined,
                    accentColor: Colors.red,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.failureReason!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Admin Actions ──────────────────────────────
                if (isFailed) _RetryCard(item: item),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Retry Card ────────────────────────────────────────────────────────────

class _RetryCard extends StatelessWidget {
  final NotificationEntity item;
  const _RetryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Actions',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Make sure the recipient\'s phone number is correct before retrying.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _confirmRetry(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Notification'),
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRetry(BuildContext context) {
    final bloc = context.read<NotificationBloc>();
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange),
            SizedBox(width: 8),
            Text('Retry Notification'),
          ],
        ),
        content: const Text(
          'This will re-queue the notification and attempt delivery again. '
          'Make sure the recipient\'s phone number is correct first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Retry'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        bloc.add(NotificationRetryRequested(item.id));
      }
    });
  }
}

// ─── Timeline Row ──────────────────────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? time;
  final Color color;
  final bool isDone;
  final bool isLast;
  final bool isError;

  const _TimelineRow({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
    required this.isDone,
    this.isLast = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = isDone ? color : theme.colorScheme.outlineVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: activeColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: activeColor.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 16, color: activeColor),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: activeColor.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Row(
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDone ? null : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (time != null)
                  Text(
                    _fmt(time!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else if (!isDone)
                  Text(
                    'Pending',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (isError)
                  const Text(
                    'See reason below',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}, $h:$min';
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? accentColor;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _InfoBlock({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          valueWidget ?? Text(value ?? '—', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
