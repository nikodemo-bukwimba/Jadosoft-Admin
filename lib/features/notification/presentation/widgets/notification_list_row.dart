import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/value_objects/notification_status.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import 'notification_status_badge.dart';
import 'notification_channel_badge.dart';

// ─── List Row ──────────────────────────────────────────────────────────────

class NotificationListRow extends StatelessWidget {
  final NotificationEntity item;
  const NotificationListRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = NotificationStatusX.fromString(item.status);
    final isFailed = status == NotificationStatus.failed;

    return InkWell(
      onTap: () => context.go('/notifications/${item.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Icon
            CircleAvatar(
              radius: 16,
              backgroundColor: item.recipientType == 'officer'
                  ? theme.colorScheme.primary.withOpacity(0.12)
                  : Colors.teal.withOpacity(0.12),
              child: Icon(
                item.recipientType == 'officer'
                    ? Icons.badge_outlined
                    : Icons.storefront_outlined,
                size: 15,
                color: item.recipientType == 'officer'
                    ? theme.colorScheme.primary
                    : Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.recipientId,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      NotificationChannelBadge(
                          channel: item.channel, compact: true),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (isFailed && item.failureReason != null)
                    Text(
                      item.failureReason!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                          fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right side
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                NotificationStatusBadge(status: status, compact: true),
                const SizedBox(height: 4),
                Text(
                  _formatTime(item.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (isFailed) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => context
                    .read<NotificationBloc>()
                    .add(NotificationRetryRequested(item.id)),
                icon: const Icon(Icons.refresh, size: 16),
                color: Colors.orange,
                tooltip: 'Retry',
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ],
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

// ─── Table Row ─────────────────────────────────────────────────────────────

class NotificationTableRow extends StatelessWidget {
  final NotificationEntity? item; // null = header
  const NotificationTableRow({super.key, this.item});
  const NotificationTableRow.header({super.key}) : item = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (item == null) return _buildHeader(theme);
    return _buildRow(context, theme);
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _cell('Recipient', flex: 2, theme: theme, isHeader: true),
          _cell('Channel', flex: 1, theme: theme, isHeader: true),
          _cell('Content', flex: 4, theme: theme, isHeader: true),
          _cell('Status', flex: 1, theme: theme, isHeader: true),
          _cell('Created', flex: 1, theme: theme, isHeader: true),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, ThemeData theme) {
    final e = item!;
    final status = NotificationStatusX.fromString(e.status);
    final isFailed = status == NotificationStatus.failed;

    return InkWell(
      onTap: () => context.go('/notifications/${e.id}'),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          color: isFailed ? Colors.red.withOpacity(0.02) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.recipientId,
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  Text(e.recipientType,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10)),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: NotificationChannelBadge(
                  channel: e.channel, compact: true),
            ),
            Expanded(
              flex: 4,
              child: Text(
                e.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: NotificationStatusBadge(status: status, compact: true),
            ),
            Expanded(
              flex: 1,
              child: Text(
                _formatShort(e.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: isFailed
                  ? IconButton(
                      onPressed: () => context
                          .read<NotificationBloc>()
                          .add(NotificationRetryRequested(e.id)),
                      icon: const Icon(Icons.refresh, size: 16),
                      color: Colors.orange,
                      tooltip: 'Retry',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 28, minHeight: 28),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text,
      {required int flex,
      required ThemeData theme,
      bool isHeader = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: isHeader
            ? theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
                fontSize: 10,
              )
            : theme.textTheme.bodySmall,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatShort(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}';
  }
}