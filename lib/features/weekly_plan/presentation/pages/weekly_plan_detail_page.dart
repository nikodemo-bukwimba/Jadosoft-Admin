import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/weekly_plan_bloc.dart';
import '../bloc/weekly_plan_event.dart';
import '../bloc/weekly_plan_state.dart';
import '../../domain/value_objects/weekly_plan_status.dart';
import '../widgets/weekly_plan_status_badge.dart';

class WeeklyPlanDetailPage extends StatelessWidget {
  const WeeklyPlanDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Plans Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<WeeklyPlanBloc>().state;
              if (state is WeeklyPlanDetailLoaded) {
                Navigator.of(context).pushNamed(
                  '/weekly_plans/edit',
                  arguments: {'id': state.item.id},
                );
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<WeeklyPlanBloc, WeeklyPlanState>(
        listener: (context, state) {
          if (state is WeeklyPlanOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            if (state.updatedItem != null) {
              context.read<WeeklyPlanBloc>().add(
                WeeklyPlanLoadOneRequested(state.updatedItem!.id),
              );
            }
          }
          if (state is WeeklyPlanFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is WeeklyPlanLoading || state is WeeklyPlanInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is WeeklyPlanFailure) {
            return Center(child: Text(state.message));
          }
          if (state is WeeklyPlanDetailLoaded) {
            final item = state.item;
            final statusEnum = WeeklyPlanStatusX.fromString(item.status);
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
                                WeeklyPlanStatusBadge(status: statusEnum),
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
                                WeeklyPlanStatus.submitted,
                              ].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () => context
                                      .read<WeeklyPlanBloc>()
                                      .add(WeeklyPlanApproveRequested(item.id)),
                                  child: const Text('Approve Plan'),
                                ),
                              if ([
                                WeeklyPlanStatus.submitted,
                              ].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () => context
                                      .read<WeeklyPlanBloc>()
                                      .add(WeeklyPlanRejectRequested(item.id)),
                                  child: const Text('Reject Plan'),
                                ),
                              if ([
                                WeeklyPlanStatus.rejected,
                              ].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () =>
                                      context.read<WeeklyPlanBloc>().add(
                                        WeeklyPlanResubmitRequested(item.id),
                                      ),
                                  child: const Text('Resubmit Plan'),
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
                          _buildField(context, 'Officer Id', item.officerId),
                          _buildField(
                            context,
                            'Week Start',
                            item.weekStart.toIso8601String().split('T').first,
                          ),
                          _buildField(
                            context,
                            'Week End',
                            item.weekEnd.toIso8601String().split('T').first,
                          ),
                          _buildField(
                            context,
                            'Planned Customer Ids',
                            item.plannedCustomerIds?.join(', ') ?? '',
                          ),
                          _buildField(
                            context,
                            'Planned Activities',
                            item.plannedActivities ?? '',
                          ),
                          _buildField(context, 'Notes', item.notes ?? ''),
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
