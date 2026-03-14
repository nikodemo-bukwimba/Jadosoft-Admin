import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/daily_report_entity.dart';
import '../../domain/value_objects/daily_report_status.dart';
import 'daily_report_status_badge.dart';

// ─── List Row ──────────────────────────────────────────────────────────────

class DailyReportListRow extends StatelessWidget {
  final DailyReportEntity item;

  const DailyReportListRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = DailyReportStatusX.fromString(item.status);
    final visitCount = item.visitedCustomers?.length ?? 0;

    return InkWell(
      onTap: () => context.push('/daily-reports/${item.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Status indicator dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Report info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.reportNumber ?? 'Report',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.isCustomized) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.edit_note,
                            size: 12,
                            color: theme.colorScheme.tertiary),
                      ],
                    ],
                  ),
                  Text(
                    item.officerName ?? 'Unknown Officer',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Date
            Text(
              _formatDate(item.reportDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            // Visits count
            SizedBox(
              width: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_outlined,
                      size: 13, color: theme.colorScheme.outline),
                  const SizedBox(width: 3),
                  Text(
                    '$visitCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            DailyReportStatusBadge(status: status, compact: true),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                size: 18, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// ─── Table Row ─────────────────────────────────────────────────────────────

class DailyReportTableRow extends StatelessWidget {
  final DailyReportEntity item;
  final bool isHeader;

  const DailyReportTableRow({super.key, required this.item, this.isHeader = false});

  static Widget header(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    );
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text('REPORT NO.', style: style)),
          SizedBox(width: 150, child: Text('OFFICER', style: style)),
          SizedBox(width: 100, child: Text('DATE', style: style)),
          SizedBox(width: 60, child: Text('VISITS', style: style)),
          Expanded(child: Text('STATUS', style: style)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = DailyReportStatusX.fromString(item.status);
    final visitCount = item.visitedCustomers?.length ?? 0;

    return InkWell(
      onTap: () => context.push('/daily-reports/${item.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                item.reportNumber ?? '—',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 150,
              child: Text(
                item.officerName ?? '—',
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                _formatDate(item.reportDate),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                '$visitCount',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: DailyReportStatusBadge(status: status, compact: true),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}