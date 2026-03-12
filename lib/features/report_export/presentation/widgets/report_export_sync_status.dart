import 'package:flutter/material.dart';

class ReportExportSyncStatus extends StatelessWidget {
  final DateTime? lastSyncAt;
  final bool isLoading;

  const ReportExportSyncStatus({
    super.key,
    this.lastSyncAt,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLoading ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isLoading ? Icons.sync : Icons.check_circle_outline,
            size: 16,
            color: isLoading ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLoading
                  ? 'Syncing...'
                  : lastSyncAt != null
                      ? 'Last sync: ' + _formatTime(lastSyncAt!)
                      : 'Not synced yet',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return dt.toIso8601String().split('T').first;
  }
}
