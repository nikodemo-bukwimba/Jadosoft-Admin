// notification_tiles.dart
// ─────────────────────────────────────────────────────────────
// Provides:
//   NotificationListRow   — compact list tile for mobile
//   NotificationTableRow  — desktop table row + header
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/value_objects/notification_status.dart';
import 'notification_status_badge.dart';

// ─── List Row ──────────────────────────────────────────────────────────────

class NotificationListRow extends StatelessWidget {
  final NotificationEntity item;
  const NotificationListRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = NotificationStatusX.fromString(item.status);

    return InkWell(
      onTap: () => context.go('/notifications/${item.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _ChannelIcon(channel: item.channel),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'To: ${item.recipientId}  ·  ${_fmtDate(item.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            NotificationStatusBadge(status: status, compact: true),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
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
    return '${m[d.month - 1]} ${d.day}';
  }
}

// ─── Table Row ─────────────────────────────────────────────────────────────

class NotificationTableRow extends StatelessWidget {
  final NotificationEntity? item;

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
          _hcell('Channel', flex: 1, theme: theme),
          _hcell('Recipient', flex: 2, theme: theme),
          _hcell('Message', flex: 4, theme: theme),
          _hcell('Sent At', flex: 2, theme: theme),
          _hcell('Status', flex: 1, theme: theme),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, ThemeData theme) {
    final e = item!;
    final status = NotificationStatusX.fromString(e.status);

    return InkWell(
      onTap: () => context.go('/notifications/${e.id}'),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Channel
            Expanded(flex: 1, child: _ChannelBadge(channel: e.channel)),
            // Recipient
            Expanded(
              flex: 2,
              child: Text(
                e.recipientId,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Message
            Expanded(
              flex: 4,
              child: Text(
                e.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            // Sent At
            Expanded(
              flex: 2,
              child: Text(
                e.sentAt != null ? _fmtDateTime(e.sentAt!) : '—',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // Status
            Expanded(
              flex: 1,
              child: NotificationStatusBadge(status: status, compact: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hcell(String text, {required int flex, required ThemeData theme}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
          fontSize: 10,
        ),
      ),
    );
  }

  String _fmtDateTime(DateTime d) {
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
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${m[d.month - 1]} ${d.day}, $h:$min';
  }
}

// ─── Channel Icon ──────────────────────────────────────────────────────────

class _ChannelIcon extends StatelessWidget {
  final String channel;
  const _ChannelIcon({required this.channel});

  @override
  Widget build(BuildContext context) {
    final color = _color(channel);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_icon(channel), size: 18, color: color),
    );
  }

  Color _color(String c) => switch (c) {
    'sms' => Colors.orange,
    'whatsapp' => const Color(0xFF25D366),
    _ => Colors.indigo,
  };

  IconData _icon(String c) => switch (c) {
    'sms' => Icons.sms_outlined,
    'whatsapp' => Icons.chat_outlined,
    _ => Icons.notifications_outlined,
  };
}

// ─── Channel Badge ─────────────────────────────────────────────────────────

class _ChannelBadge extends StatelessWidget {
  final String channel;
  const _ChannelBadge({required this.channel});

  @override
  Widget build(BuildContext context) {
    final color = switch (channel) {
      'sms' => Colors.orange,
      'whatsapp' => const Color(0xFF25D366),
      _ => Colors.indigo,
    };
    final icon = switch (channel) {
      'sms' => Icons.sms_outlined,
      'whatsapp' => Icons.chat_outlined,
      _ => Icons.notifications_outlined,
    };
    final label = switch (channel) {
      'sms' => 'SMS',
      'whatsapp' => 'WhatsApp',
      _ => 'In-App',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
