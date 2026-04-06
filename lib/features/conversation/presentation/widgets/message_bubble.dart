import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/message_entity.dart';

class MessageBubble extends StatefulWidget {
  final MessageEntity message;
  final String currentUserId;
  final bool showSenderName;
  final bool showDateSeparator;
  final String? dateSeparatorLabel;
  final void Function(String messageId)? onDelete;
  final void Function(MessageEntity message)? onReply;
  final void Function(String messageId, String emoji)? onReact;
  final void Function(String messageId)? onTogglePin;
  final void Function(String messageId)? onToggleStar;
  final void Function(MessageEntity message)? onForward;
  final void Function(MessageEntity message)? onEdit;
  final void Function(String messageId)? onViewReadReceipts;
  final void Function(String participantId, String name, String role)?
      onPrivateReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.showSenderName = false,
    this.showDateSeparator = false,
    this.dateSeparatorLabel,
    this.onDelete,
    this.onReply,
    this.onReact,
    this.onTogglePin,
    this.onToggleStar,
    this.onForward,
    this.onEdit,
    this.onViewReadReceipts,
    this.onPrivateReply,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  double _dragOffset = 0;
  bool _triggered = false;
  static const _threshold = 60.0;

  bool get _isMe => widget.message.senderId == widget.currentUserId;

  void _onDragUpdate(DragUpdateDetails d) {
    if (widget.onReply == null) return;
    setState(() {
      _dragOffset = _isMe
          ? (_dragOffset + d.delta.dx).clamp(-_threshold * 1.2, 0)
          : (_dragOffset + d.delta.dx).clamp(0, _threshold * 1.2);
      if (_dragOffset.abs() >= _threshold && !_triggered) {
        _triggered = true;
        HapticFeedback.lightImpact();
      }
    });
  }

  void _onDragEnd(DragEndDetails d) {
    if (_triggered) widget.onReply?.call(widget.message);
    setState(() {
      _dragOffset = 0;
      _triggered = false;
    });
  }

  void _showMenu(BuildContext ctx, Offset pos) {
    final cs = Theme.of(ctx).colorScheme;
    final msg = widget.message;
    final items = <PopupMenuEntry<String>>[];
    if (widget.onReply != null)
      items.add(_popItem('reply', Icons.reply, 'Reply', cs.primary));
    if (widget.onPrivateReply != null && !_isMe)
      items.add(
        _popItem('private_reply', Icons.lock, 'Reply Privately', cs.tertiary),
      );
    if (msg.content.isNotEmpty && !msg.isImage)
      items.add(_popItem('copy', Icons.copy, 'Copy Text', cs.onSurface));
    if (widget.onTogglePin != null)
      items.add(
        _popItem(
          'pin',
          msg.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          msg.isPinned ? 'Unpin' : 'Pin',
          Colors.amber,
        ),
      );
    if (widget.onToggleStar != null)
      items.add(
        _popItem(
          'star',
          msg.isStarred ? Icons.star : Icons.star_outline,
          msg.isStarred ? 'Unstar' : 'Star',
          Colors.amber,
        ),
      );
    if (widget.onForward != null)
      items.add(_popItem('forward', Icons.forward, 'Forward', cs.onSurface));
    if (_isMe && widget.onEdit != null && !msg.isImage && !msg.isVoice)
      items.add(_popItem('edit', Icons.edit, 'Edit', cs.onSurface));
    if (widget.onViewReadReceipts != null && _isMe)
      items.add(
        _popItem('receipts', Icons.done_all, 'Read Receipts', Colors.blue),
      );
    if (widget.onReact != null) {
      items.add(const PopupMenuDivider());
      items.add(
        PopupMenuItem(
          value: 'react_placeholder',
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['👍', '✅', '👀', '❓', '❤️', '😂']
                .map(
                  (e) => InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onReact?.call(msg.id, e);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 4,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }
    if (widget.onDelete != null) {
      items.add(const PopupMenuDivider());
      items.add(_popItem('delete', Icons.delete, 'Delete', cs.error));
    }

    showMenu<String>(
      context: ctx,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx + 1, pos.dy + 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: items,
    ).then((v) {
      if (v == null || !ctx.mounted) return;
      switch (v) {
        case 'reply':
          widget.onReply?.call(msg);
        case 'private_reply':
          widget.onPrivateReply?.call(
            msg.senderId,
            msg.senderName,
            msg.senderRole,
          );
        case 'copy':
          Clipboard.setData(ClipboardData(text: msg.content));
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Copied'),
              duration: Duration(seconds: 1),
            ),
          );
        case 'pin':
          widget.onTogglePin?.call(msg.id);
        case 'star':
          widget.onToggleStar?.call(msg.id);
        case 'forward':
          widget.onForward?.call(msg);
        case 'edit':
          widget.onEdit?.call(msg);
        case 'receipts':
          widget.onViewReadReceipts?.call(msg.id);
        case 'delete':
          _confirmDelete(ctx);
      }
    });
  }

  PopupMenuItem<String> _popItem(
    String val,
    IconData icon,
    String label,
    Color color,
  ) =>
      PopupMenuItem(
        value: val,
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      );

  void _confirmDelete(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Delete Message?'),
        content: Text(
          _isMe ? 'Deleted for everyone.' : 'Removed from conversation.',
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
              widget.onDelete?.call(widget.message.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    return Column(
      children: [
        if (widget.showDateSeparator && widget.dateSeparatorLabel != null)
          _DateSep(label: widget.dateSeparatorLabel!),
        if (msg.isSystem)
          _SystemBubble(message: msg)
        else
          GestureDetector(
            onSecondaryTapUp: (d) => _showMenu(context, d.globalPosition),
            onLongPressStart: (d) => _showMenu(context, d.globalPosition),
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: Stack(
              children: [
                if (_dragOffset.abs() > 10)
                  Positioned.fill(
                    child: Align(
                      alignment: _isMe
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: _isMe ? 16 : 0,
                          right: _isMe ? 0 : 16,
                        ),
                        child: AnimatedOpacity(
                          opacity: (_dragOffset.abs() / _threshold).clamp(
                            0.0,
                            1.0,
                          ),
                          duration: Duration.zero,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary
                                  .withValues(
                                    alpha: _triggered ? 0.2 : 0.1,
                                  ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.reply,
                              size: _triggered ? 22 : 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Transform.translate(
                  offset: Offset(_dragOffset, 0),
                  child: _buildBubble(context),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBubble(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final msg = widget.message;
    final bubbleColor = _isMe
        ? cs.primary.withValues(alpha: 0.12)
        : cs.surfaceContainerHighest;
    final br = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft:
          _isMe ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight:
          _isMe ? const Radius.circular(4) : const Radius.circular(16),
    );

    return Align(
      alignment: _isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width > 800
              ? 480
              : MediaQuery.of(context).size.width * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Column(
            crossAxisAlignment: _isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (widget.showSenderName && !_isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    msg.senderName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _roleColor(msg.senderRole, cs),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: br,
                  border: _isMe
                      ? null
                      : Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.isForwarded)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.forward, size: 12, color: cs.outline),
                            const SizedBox(width: 4),
                            Text(
                              'Forwarded from ${msg.forwardedFromSenderName ?? "unknown"}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.outline,
                                fontStyle: FontStyle.italic,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (msg.isReply)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(color: cs.primary, width: 3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.replyToSenderName ?? 'Unknown',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              msg.replyToContent ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (msg.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.push_pin,
                              size: 11,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Pinned',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.amber.shade700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (msg.isImage && msg.imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: msg.imageUrl!.startsWith('http')
                              ? Image.network(
                                  msg.imageUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    height: 100,
                                    child: Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  ),
                                )
                              : Image.file(
                                  File(msg.imageUrl!),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    height: 100,
                                    child: Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    if (msg.isVoice)
                      _VoiceNote(duration: msg.voiceDurationSeconds ?? 0),
                    if (msg.content.isNotEmpty) _buildText(context, msg),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (msg.isEdited) ...[
                          Text(
                            'edited ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.outline,
                              fontSize: 9,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(width: 2),
                        ],
                        if (msg.isStarred) ...[
                          Icon(
                            Icons.star,
                            size: 11,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 2),
                        ],
                        Text(
                          '${msg.sentAt.hour.toString().padLeft(2, '0')}:${msg.sentAt.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.outline,
                            fontSize: 10,
                          ),
                        ),
                        if (_isMe) ...[
                          const SizedBox(width: 3),
                          _Receipt(status: msg.deliveryStatus, color: cs),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (msg.reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    spacing: 4,
                    children: _groupReactions(msg)
                        .entries
                        .map(
                          (e) => GestureDetector(
                            onTap: () => widget.onReact?.call(msg.id, e.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: e.value.any(
                                    (r) =>
                                        r.userId == widget.currentUserId,
                                  )
                                      ? cs.primary
                                      : cs.outlineVariant.withValues(
                                          alpha: 0.3,
                                        ),
                                ),
                              ),
                              child: Text(
                                '${e.key} ${e.value.length}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildText(BuildContext ctx, MessageEntity msg) {
    final cs = Theme.of(ctx).colorScheme;
    if (msg.hasMentions) {
      final text = msg.content;
      final spans = <InlineSpan>[];
      final regex = RegExp(r'@\w+');
      int last = 0;
      for (final m in regex.allMatches(text)) {
        if (m.start > last) {
          spans.add(TextSpan(text: text.substring(last, m.start)));
        }
        spans.add(
          TextSpan(
            text: m.group(0),
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              backgroundColor: cs.primary.withValues(alpha: 0.1),
            ),
          ),
        );
        last = m.end;
      }
      if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
      return Text.rich(
        TextSpan(
          children: spans,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
            color: cs.onSurface,
            height: 1.3,
          ),
        ),
      );
    }
    return Text(
      msg.content,
      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
        color: cs.onSurface,
        height: 1.3,
      ),
    );
  }

  Map<String, List<MessageReaction>> _groupReactions(MessageEntity msg) {
    final map = <String, List<MessageReaction>>{};
    for (final r in msg.reactions) {
      map.putIfAbsent(r.emoji, () => []).add(r);
    }
    return map;
  }

  Color _roleColor(String role, ColorScheme cs) => switch (role) {
        'admin' => cs.primary,
        'officer' => Colors.teal,
        'customer' => Colors.orange,
        _ => cs.outline,
      };
}

class _VoiceNote extends StatelessWidget {
  final int duration;
  const _VoiceNote({required this.duration});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mins = duration ~/ 60;
    final secs = duration % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow, size: 20, color: cs.primary),
          const SizedBox(width: 6),
          Container(
            height: 3,
            width: 100,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$mins:${secs.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _DateSep extends StatelessWidget {
  final String label;
  const _DateSep({required this.label});
  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                color: cs.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }
}

class _SystemBubble extends StatelessWidget {
  final MessageEntity message;
  const _SystemBubble({required this.message});
  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.content,
          textAlign: TextAlign.center,
          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  final DeliveryStatus status;
  final ColorScheme color;
  const _Receipt({required this.status, required this.color});
  @override
  Widget build(BuildContext ctx) => switch (status) {
        DeliveryStatus.sending => Icon(
            Icons.access_time,
            size: 13,
            color: color.outline,
          ),
        DeliveryStatus.sent =>
          Icon(Icons.check, size: 13, color: color.outline),
        DeliveryStatus.delivered => Icon(
            Icons.done_all,
            size: 13,
            color: color.outline,
          ),
        DeliveryStatus.read => const Icon(
            Icons.done_all,
            size: 13,
            color: Colors.blue,
          ),
      };
}