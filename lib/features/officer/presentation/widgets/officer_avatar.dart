import 'package:flutter/material.dart';
import '../../domain/value_objects/officer_status.dart';

/// Circular avatar with officer initials and status-colored border ring.
class OfficerAvatar extends StatelessWidget {
  final String name;
  final String status;
  final double radius;

  const OfficerAvatar({
    super.key,
    required this.name,
    required this.status,
    this.radius = 22,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = OfficerStatusX.fromString(status).color;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: statusColor, width: 2.5),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: radius * 0.7,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}