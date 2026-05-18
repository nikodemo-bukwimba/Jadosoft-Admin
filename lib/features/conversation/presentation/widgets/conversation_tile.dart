// === FILE: lib/features/conversation/presentation/widgets/conversation_tile.dart ===
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
            const SnackBar(
              content: Text('ID copied'),
              duration: Duration(seconds: 1),
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
    final conv = conversation;
    final displayName = conv.displayName(currentUserId);
    final subtitle = conv.subtitle(currentUserId);
    final isClosed = conv.status == ConversationStatus.closed;
    final isGroup = conv.type == ConversationType.group;
    final hasUnread = conv.unreadCount > 0;

    // Detect if last message was a photo
    final lastIsPhoto = conv.lastMessageIsImage == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
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
                // ── Avatar — pass currentUserId so DMs show OTHER person ──
                ParticipantAvatarStack(
                  participants: conv.participants,
                  isGroup: isGroup,
                  size: 48,
                  currentUserId: currentUserId,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: display name + icons
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
                      // Row 2: online / member count
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: subtitle.contains('online')
                                ? Colors.green
                                : cs.outline,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Row 3: last message preview
                      const SizedBox(height: 3),
                      if (lastIsPhoto)
                        // ── Photo preview ──────────────────────────────
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo,
                              size: 13,
                              color: hasUnread ? cs.onSurface : cs.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Photo',
                              style: theme.textTheme.bodySmall?.copyWith(
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
                        )
                      else if (conv.lastMessage != null &&
                          conv.lastMessage!.isNotEmpty)
                        Text.rich(
                          TextSpan(
                            children: [
                              if (conv.lastMessageSenderName != null)
                                TextSpan(
                                  text: '${conv.lastMessageSenderName}: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: hasUnread
                                        ? cs.onSurface
                                        : cs.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              TextSpan(
                                text: conv.lastMessage,
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
                // ── Right: time + unread badge ──────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (conv.lastMessageAt != null)
                      Text(
                        _fmtTime(conv.lastMessageAt!),
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
                          conv.unreadCount > 99
                              ? '99+'
                              : conv.unreadCount.toString(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (isGroup)
                      Text(
                        '${conv.participants.length} members',
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
