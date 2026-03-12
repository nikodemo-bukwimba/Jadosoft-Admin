import 'package:flutter/material.dart';
import '../../domain/value_objects/daily_report_status.dart';

class DailyReportStatusBadge extends StatelessWidget {
  final DailyReportStatus status;
  final bool compact;

  const DailyReportStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: status.color,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
