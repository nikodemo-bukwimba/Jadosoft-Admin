import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/report_export_cubit.dart';
import '../cubit/report_export_state.dart';
import '../widgets/report_export_operation_card.dart';
import '../widgets/report_export_sync_status.dart';

class ReportExportPage extends StatelessWidget {
  const ReportExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Export'),
      ),
      body: BlocBuilder<ReportExportCubit, ReportExportState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              ReportExportSyncStatus(
                lastSyncAt: state.lastSyncAt,
                isLoading: state.isLoading,
              ),
              const SizedBox(height: 16),
              Text('Operations', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ReportExportOperationCard(
                title: 'Request Export',
                subtitle: 'Request an async export of a report in PDF or Excel format',
                icon: Icons.upload_file,
                isLoading: state.isRequestExportLoading,
                error: state.requestExportError,
              // Requires parameters -- wire up from your UI
              ),
              const SizedBox(height: 8),
              ReportExportOperationCard(
                title: 'Get Export Status',
                subtitle: 'Poll the status of an export request until ready',
                icon: Icons.hourglass_empty,
                isLoading: state.isGetExportStatusLoading,
                error: state.getExportStatusError,
              // Requires parameters -- wire up from your UI
              ),
              const SizedBox(height: 8),
              ReportExportOperationCard(
                title: 'Download Export',
                subtitle: 'Download the completed export file',
                icon: Icons.download,
                isLoading: state.isDownloadExportLoading,
                error: state.downloadExportError,
              // Requires parameters -- wire up from your UI
              ),
              const SizedBox(height: 8),

              ],
            ),
          );
        },
      ),
    );
  }
}
