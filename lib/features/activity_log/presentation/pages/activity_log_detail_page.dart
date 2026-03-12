import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/activity_log_bloc.dart';
import '../bloc/activity_log_event.dart';
import '../bloc/activity_log_state.dart';

class ActivityLogDetailPage extends StatelessWidget {
  const ActivityLogDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logs Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<ActivityLogBloc>().state;
              if (state is ActivityLogDetailLoaded) {
                Navigator.of(context).pushNamed(
                  '/activity_logs/edit',
                  arguments: {'id': state.item.id},
                );
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<ActivityLogBloc, ActivityLogState>(
        builder: (context, state) {
          if (state is ActivityLogLoading || state is ActivityLogInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ActivityLogFailure) {
            return Center(child: Text(state.message));
          }
          if (state is ActivityLogDetailLoaded) {
            final item = state.item;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _buildField(context, 'Action', item.action),
                    _buildField(context, 'Actor Name', item.actorName),
                    _buildField(context, 'Actor Id', item.actorId),
                    _buildField(context, 'Actor Role', item.actorRole),
                    _buildField(context, 'Entity Type', item.entityType),
                    _buildField(context, 'Entity Id', item.entityId),
                    _buildField(context, 'Entity Snapshot', item.entitySnapshot?.toString() ?? ''),
                    _buildField(context, 'Ip Address', item.ipAddress?.toString() ?? ''),
                    _buildField(context, 'User Agent', item.userAgent?.toString() ?? ''),
                    _buildField(context, 'Occurred At', item.occurredAt.toIso8601String().split('T').first),
                    ],
                  ),
                ),
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
