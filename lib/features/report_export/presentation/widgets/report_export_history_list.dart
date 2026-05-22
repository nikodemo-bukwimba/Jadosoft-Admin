// lib/features/report_export/presentation/widgets/report_export_history_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/report_export_cubit.dart';
import '../cubit/report_export_state.dart';
import '../utils/report_export_label.dart';

class ReportExportHistoryList extends StatelessWidget {
  final List<ExportHistoryEntry> entries;

  const ReportExportHistoryList({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        children: entries.map((e) {
          final isReady  = e.status == 'ready';
          final isFailed = e.status == 'failed';

          return ListTile(
            leading: Icon(
              isReady
                  ? Icons.check_circle_outline
                  : isFailed
                      ? Icons.error_outline
                      : Icons.hourglass_empty,
              color: isReady
                  ? Colors.green
                  : isFailed
                      ? scheme.error
                      : scheme.onSurfaceVariant,
            ),
            title: Text(reportExportLabel(e.reportType)),
            subtitle: Text(
                '${e.format.toUpperCase()} · ${_timeAgo(e.requestedAt)}'),
            trailing: isReady
                ? TextButton.icon(
                    onPressed: () => context
                        .read<ReportExportCubit>()
                        .downloadExport(e.exportId),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                  )
                : isFailed
                    ? Text('Failed',
                        style:
                            TextStyle(color: scheme.error, fontSize: 12))
                    : const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
          );
        }).toList(),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}