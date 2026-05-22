// lib/features/report_export/presentation/widgets/report_export_polling_banner.dart

import 'package:flutter/material.dart';
import '../../domain/models/get_export_status_response.dart';

class ReportExportPollingBanner extends StatelessWidget {
  final GetExportStatusResponse? status;

  const ReportExportPollingBanner({super.key, this.status});

  @override
  Widget build(BuildContext context) {
    final scheme   = Theme.of(context).colorScheme;
    final progress = status?.progress ?? 0;
    final label    = status?.status == 'processing'
        ? 'Preparing export… $progress%'
        : 'Export queued…';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (status?.status == 'processing')
            SizedBox(
              width: 80,
              child: LinearProgressIndicator(value: progress / 100),
            ),
        ],
      ),
    );
  }
}