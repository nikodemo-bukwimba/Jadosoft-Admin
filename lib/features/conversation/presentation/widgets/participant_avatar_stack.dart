import 'package:flutter/material.dart';
import '../../domain/entities/conversation_entity.dart';

class ParticipantAvatarStack extends StatelessWidget {
  final List<ConversationParticipant> participants;
  final bool isGroup;
  final double size;
  const ParticipantAvatarStack({
    super.key,
    required this.participants,
    required this.isGroup,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!isGroup || participants.length <= 1) {
      final p = participants.isNotEmpty ? participants.first : null;
      return _avatarWithStatus(
        context,
        p?.name ?? '?',
        _roleColor(p?.role ?? 'unknown', cs),
        size,
        p?.onlineStatus,
      );
    }
    final visible = participants.take(3).toList();
    final overlap = size * 0.3;
    final smallSize = size * 0.7;
    final totalWidth =
        size + (visible.length - 1) * (smallSize - overlap * 0.5);
    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: [
          for (var i = visible.length - 1; i >= 0; i--)
            Positioned(
              left: i * (smallSize - overlap * 0.5),
              top: (size - smallSize) / 2,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
                child: _buildAvatar(
                  context,
                  visible[i].name,
                  _roleColor(visible[i].role, cs),
                  smallSize - 4,
                ),
              ),
            ),
          if (participants.length > 3)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${participants.length - 3}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatarWithStatus(
    BuildContext context,
    String name,
    Color color,
    double s,
    OnlineStatus? status,
  ) {
    return Stack(
      children: [
        _buildAvatar(context, name, color, s),
        if (status != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: s * 0.28,
              height: s * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status == OnlineStatus.online
                    ? Colors.green
                    : (status == OnlineStatus.away
                          ? Colors.amber
                          : Theme.of(context).colorScheme.outline),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    String name,
    Color color,
    double s,
  ) {
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return CircleAvatar(
      radius: s / 2,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: s * 0.35,
        ),
      ),
    );
  }

  Color _roleColor(String role, ColorScheme cs) => switch (role) {
    'admin' => cs.primary,
    'officer' => Colors.teal,
    'customer' => Colors.orange,
    _ => cs.outline,
  };
}
