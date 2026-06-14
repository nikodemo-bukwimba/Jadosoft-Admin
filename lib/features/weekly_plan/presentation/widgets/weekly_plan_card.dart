// lib/features/weekly_plan/presentation/widgets/weekly_plan_card.dart
//
// FIX: was showing item.officerId (raw actor UUID) in the title and
// in the delete-confirm dialog. Now uses item.officerName with a
// graceful fallback — same pattern as weekly_plan_tiles.dart.

import 'package:flutter/material.dart';
import '../../domain/entities/weekly_plan_entity.dart';
import '../../domain/value_objects/weekly_plan_status.dart';
import 'weekly_plan_status_badge.dart';

// Reuse the same label helper that the tiles widget already uses.
String _officerLabel(WeeklyPlanEntity item) =>
    (item.officerName != null && item.officerName!.isNotEmpty)
    ? item.officerName!
    : 'Officer ID: ${item.officerId.length > 10 ? item.officerId.substring(0, 10) : item.officerId}...';

class WeeklyPlanCard extends StatelessWidget {
  final WeeklyPlanEntity item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const WeeklyPlanCard({
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
          // ← FIXED: was item.officerId
          _officerLabel(item),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(item.weekStart.toString()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WeeklyPlanStatusBadge(
              status: WeeklyPlanStatusX.fromString(item.status),
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
        content: Text(
          // ← FIXED: was item.officerId
          'Remove plan by "${_officerLabel(item)}"? This cannot be undone.',
        ),
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
