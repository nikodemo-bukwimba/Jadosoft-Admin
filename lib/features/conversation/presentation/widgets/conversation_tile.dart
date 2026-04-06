import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/conversation_entity.dart';
import 'participant_avatar_stack.dart';

class ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
    this.onDelete,
  });

  void _showMenu(BuildContext ctx, Offset pos) {
    final cs = Theme.of(ctx).colorScheme;
    showMenu<String>(
      context: ctx,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx + 1, pos.dy + 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.chat, size: 18, color: cs.onSurface),
              const SizedBox(width: 10),
              const Text('Open'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy_id',
          child: Row(
            children: [
              Icon(Icons.copy, size: 18, color: cs.onSurface),
              const SizedBox(width: 10),
              const Text('Copy ID'),
            ],
          ),
        ),
        if (onDelete != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_forever, size: 18, color: cs.error),
                const SizedBox(width: 10),
                Text('Delete', style: TextStyle(color: cs.error)),
              ],
            ),
          ),
        ],
      ],
    ).then((v) {
      if (v == null || !ctx.mounted) return;
      switch (v) {
        case 'open':
          onTap();
        case 'copy_id':
          Clipboard.setData(ClipboardData(text: conversation.id));
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('Copied ${conversation.id}'),
              duration: const Duration(seconds: 1),
            ),
          );
        case 'delete':
          showDialog(
            context: ctx,
            builder: (d) => AlertDialog(
              title: const Text('Delete Conversation?'),
              content: Text(
                'Delete "${conversation.displayName(currentUserId)}" and all messages?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(d),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                  ),
                  onPressed: () {
                    Navigator.pop(d);
                    onDelete?.call();
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final displayName = conversation.displayName(currentUserId);
    final isClosed = conversation.status == ConversationStatus.closed;
    final isGroup = conversation.type == ConversationType.group;
    final hasUnread = conversation.unreadCount > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: GestureDetector(
        onSecondaryTapUp: (d) => _showMenu(context, d.globalPosition),
        onLongPressStart: (d) => _showMenu(context, d.globalPosition),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                ParticipantAvatarStack(
                  participants: conversation.participants,
                  isGroup: isGroup,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isClosed) ...[
                            Icon(Icons.lock, size: 14, color: cs.outline),
                            const SizedBox(width: 4),
                          ],
                          if (isGroup) ...[
                            Icon(Icons.group, size: 14, color: cs.primary),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              displayName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conversation.id.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.outline,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (conversation.lastMessage != null)
                        Text.rich(
                          TextSpan(
                            children: [
                              if (conversation.lastMessageSenderName != null)
                                TextSpan(
                                  text:
                                      '${conversation.lastMessageSenderName}: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: hasUnread
                                        ? cs.onSurface
                                        : cs.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              TextSpan(
                                text: conversation.lastMessage,
                                style: TextStyle(
                                  color: hasUnread
                                      ? cs.onSurface
                                      : cs.onSurfaceVariant,
                                  fontWeight: hasUnread
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (conversation.lastMessageAt != null)
                      Text(
                        _fmtTime(conversation.lastMessageAt!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: hasUnread ? cs.primary : cs.outline,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          conversation.unreadCount > 99
                              ? '99+'
                              : conversation.unreadCount.toString(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (isGroup && !hasUnread)
                      Text(
                        '${conversation.participants.length} members',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.outline,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }
}