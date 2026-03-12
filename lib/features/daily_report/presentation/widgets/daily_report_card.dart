import 'package:flutter/material.dart';
import '../../domain/entities/daily_report_entity.dart';
import '../../domain/value_objects/daily_report_status.dart';
import 'daily_report_status_badge.dart';

class DailyReportCard extends StatelessWidget {
  final DailyReportEntity item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DailyReportCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(
          item.reportNumber ?? '',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(item.reportDate.toString()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DailyReportStatusBadge(
              status: DailyReportStatusX.fromString(item.status),
              compact: true,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, color: scheme.error),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Remove "${item.reportNumber}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }
}
