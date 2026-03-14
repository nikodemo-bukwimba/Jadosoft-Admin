import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/value_objects/notification_status.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import 'notification_status_badge.dart';
import 'notification_channel_badge.dart';

class NotificationCardTile extends StatelessWidget {
  final NotificationEntity item;

  const NotificationCardTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = NotificationStatusX.fromString(item.status);
    final isFailed = status == NotificationStatus.failed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isFailed
              ? Colors.red.withOpacity(0.3)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/notifications/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  _RecipientIcon(recipientType: item.recipientType),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.recipientId,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          item.recipientType.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  NotificationStatusBadge(status: status, compact: true),
                ],
              ),
              const SizedBox(height: 10),
              // Content preview
              Text(
                item.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              // Failure reason
              if (isFailed && item.failureReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 13, color: Colors.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.failureReason!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontStyle: FontStyle.italic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // Footer
              Row(
                children: [
                  NotificationChannelBadge(channel: item.channel, compact: true),
                  const Spacer(),
                  if (isFailed)
                    TextButton.icon(
                      onPressed: () => context
                          .read<NotificationBloc>()
                          .add(NotificationRetryRequested(item.id)),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Retry',
                          style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  Text(
                    _formatTime(item.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}';
  }
}

class _RecipientIcon extends StatelessWidget {
  final String recipientType;
  const _RecipientIcon({required this.recipientType});

  @override
  Widget build(BuildContext context) {
    final isOfficer = recipientType == 'officer';
    final color = isOfficer
        ? Theme.of(context).colorScheme.primary
        : Colors.teal;
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.12),
      child: Icon(
        isOfficer ? Icons.badge_outlined : Icons.storefront_outlined,
        size: 18,
        color: color,
      ),
    );
  }
}