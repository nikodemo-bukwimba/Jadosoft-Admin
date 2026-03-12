import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/daily_report_bloc.dart';
import '../bloc/daily_report_event.dart';
import '../bloc/daily_report_state.dart';
import '../../domain/value_objects/daily_report_status.dart';
import '../widgets/daily_report_status_badge.dart';

class DailyReportDetailPage extends StatelessWidget {
  const DailyReportDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reports Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<DailyReportBloc>().state;
              if (state is DailyReportDetailLoaded) {
                Navigator.of(context).pushNamed(
                  '/daily_reports/edit',
                  arguments: {'id': state.item.id},
                );
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<DailyReportBloc, DailyReportState>(
        listener: (context, state) {
          if (state is DailyReportOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            if (state.updatedItem != null) {
              context.read<DailyReportBloc>().add(
                DailyReportLoadOneRequested(state.updatedItem!.id),
              );
            }
          }
          if (state is DailyReportFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DailyReportLoading || state is DailyReportInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DailyReportFailure) {
            return Center(child: Text(state.message));
          }
          if (state is DailyReportDetailLoaded) {
            final item = state.item;
            final statusEnum = DailyReportStatusX.fromString(item.status);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.id,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                DailyReportStatusBadge(status: statusEnum),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actions',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if ([
                                DailyReportStatus.draft,
                              ].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () => context
                                      .read<DailyReportBloc>()
                                      .add(DailyReportSubmitRequested(item.id)),
                                  child: const Text('Submit Report'),
                                ),
                              if ([
                                DailyReportStatus.submitted,
                              ].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () =>
                                      context.read<DailyReportBloc>().add(
                                        DailyReportApproveRequested(item.id),
                                      ),
                                  child: const Text('Approve Report'),
                                ),
                              if ([
                                DailyReportStatus.submitted,
                              ].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () => context
                                      .read<DailyReportBloc>()
                                      .add(DailyReportRejectRequested(item.id)),
                                  child: const Text('Reject Report'),
                                ),
                              if ([
                                DailyReportStatus.rejected,
                              ].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () =>
                                      context.read<DailyReportBloc>().add(
                                        DailyReportResubmitRequested(item.id),
                                      ),
                                  child: const Text('Resubmit Report'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField(
                            context,
                            'Report Number',
                            item.reportNumber ?? '',
                          ),
                          _buildField(
                            context,
                            'Report Date',
                            item.reportDate.toIso8601String().split('T').first,
                          ),
                          _buildField(context, 'Officer Id', item.officerId),
                          _buildField(
                            context,
                            'Officer Name',
                            item.officerName ?? '',
                          ),
                          _buildField(
                            context,
                            'Officer Email',
                            item.officerEmail ?? '',
                          ),
                          _buildField(
                            context,
                            'Officer Phone',
                            item.officerPhone ?? '',
                          ),
                          _buildField(
                            context,
                            'Officer Role',
                            item.officerRole ?? '',
                          ),
                          _buildField(
                            context,
                            'Visited Customers',
                            item.visitedCustomers
                                    ?.map((e) => e.toString())
                                    .join(', ') ??
                                '',
                          ),
                          _buildField(
                            context,
                            'Key Outcomes',
                            item.keyOutcomes ?? '',
                          ),
                          _buildField(
                            context,
                            'Challenges Faced',
                            item.challengesFaced ?? '',
                          ),
                          _buildField(
                            context,
                            'Next Day Plan',
                            item.nextDayPlan ?? '',
                          ),
                          _buildField(
                            context,
                            'Custom Body',
                            item.customBody ?? '',
                          ),
                          _buildField(
                            context,
                            'Is Customized',
                            item.isCustomized.toString(),
                          ),
                          _buildField(
                            context,
                            'Reviewed By Name',
                            item.reviewedByName ?? '',
                          ),
                          _buildField(
                            context,
                            'Admin Feedback',
                            item.adminFeedback ?? '',
                          ),
                          _buildField(
                            context,
                            'Review Decision',
                            item.reviewDecision ?? '',
                          ),
                          _buildField(context, 'Status', item.status),
                          _buildField(
                            context,
                            'Submitted At',
                            item.submittedAt != null
                                ? item.submittedAt!
                                      .toIso8601String()
                                      .split('T')
                                      .first
                                : '',
                          ),
                          _buildField(
                            context,
                            'Reviewed At',
                            item.reviewedAt != null
                                ? item.reviewedAt!
                                      .toIso8601String()
                                      .split('T')
                                      .first
                                : '',
                          ),
                          _buildField(
                            context,
                            'Created At',
                            item.createdAt.toIso8601String().split('T').first,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildField(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
