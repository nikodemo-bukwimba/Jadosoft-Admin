import 'package:flutter/material.dart';

class NotificationChannelBadge extends StatelessWidget {
  final String channel;
  final bool compact;

  const NotificationChannelBadge({
    super.key,
    required this.channel,
    this.compact = false,
  });

  IconData get _icon => switch (channel) {
        'sms' => Icons.sms_outlined,
        'whatsapp' => Icons.chat_outlined,
        'in_app' => Icons.notifications_outlined,
        _ => Icons.send_outlined,
      };

  String get _label => switch (channel) {
        'sms' => 'SMS',
        'whatsapp' => 'WhatsApp',
        'in_app' => 'In-App',
        _ => channel,
      };

  Color get _color => switch (channel) {
        'sms' => Colors.orange,
        'whatsapp' => const Color(0xFF25D366),
        'in_app' => Colors.indigo,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 10 : 12, color: color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}