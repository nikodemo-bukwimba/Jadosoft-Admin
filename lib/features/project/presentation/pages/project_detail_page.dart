import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';
import '../../domain/value_objects/project_status.dart';
import '../widgets/project_status_badge.dart';

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<ProjectBloc>().state;
              if (state is ProjectDetailLoaded) {
                Navigator.of(context).pushNamed(
                  '/projects/edit',
                  arguments: {'id': state.item.id},
                );
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state is ProjectOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            if (state.updatedItem != null) {
              context.read<ProjectBloc>()
                  .add(ProjectLoadOneRequested(state.updatedItem!.id));
            }
          }
          if (state is ProjectFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProjectLoading || state is ProjectInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProjectFailure) {
            return Center(child: Text(state.message));
          }
          if (state is ProjectDetailLoaded) {
            final item = state.item;
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
                                  style: Theme.of(context).textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ProjectStatusBadge(status: item.status),
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
                          Text('Actions', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                    if ([ProjectStatus.planning].contains(item.status))
                      FilledButton.tonal(
                        onPressed: () => context.read<ProjectBloc>()
                            .add(ProjectActivateRequested(item.id)),
                        child: const Text('Start Project'),
                      ),
                    if ([ProjectStatus.active].contains(item.status))
                      FilledButton.tonal(
                        onPressed: () => context.read<ProjectBloc>()
                            .add(ProjectPauseRequested(item.id)),
                        child: const Text('Put On Hold'),
                      ),
                    if ([ProjectStatus.onHold].contains(item.status))
                      FilledButton.tonal(
                        onPressed: () => context.read<ProjectBloc>()
                            .add(ProjectResumeRequested(item.id)),
                        child: const Text('Resume'),
                      ),
                    if ([ProjectStatus.active].contains(item.status))
                      FilledButton.tonal(
                        onPressed: () => context.read<ProjectBloc>()
                            .add(ProjectCompleteRequested(item.id)),
                        child: const Text('Mark Complete'),
                      ),
                    if ([ProjectStatus.completed, ProjectStatus.onHold].contains(item.status))
                      FilledButton.tonal(
                        onPressed: () => context.read<ProjectBloc>()
                            .add(ProjectArchiveRequested(item.id)),
                        child: const Text('Archive'),
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
                    _buildField(context, 'Name', item.name),
                    _buildField(context, 'Description', item.description ?? ''),
                    _buildField(context, 'Budget', item.budget?.toStringAsFixed(2) ?? ''),
                    _buildField(context, 'Is Public', item.isPublic.toString()),
                    _buildField(context, 'Start Date', item.startDate != null ? item.startDate!.toIso8601String().split('T').first : ''),
                    _buildField(context, 'Created At', item.createdAt.toIso8601String().split('T').first),
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
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
