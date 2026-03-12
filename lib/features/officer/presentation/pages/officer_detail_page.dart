import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/officer_bloc.dart';
import '../bloc/officer_event.dart';
import '../bloc/officer_state.dart';
import '../../domain/value_objects/officer_status.dart';
import '../widgets/officer_status_badge.dart';

class OfficerDetailPage extends StatelessWidget {
  const OfficerDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officers Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<OfficerBloc>().state;
              if (state is OfficerDetailLoaded) {
                Navigator.of(
                  context,
                ).pushNamed('/officers/edit', arguments: {'id': state.item.id});
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<OfficerBloc, OfficerState>(
        listener: (context, state) {
          if (state is OfficerOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            if (state.updatedItem != null) {
              context.read<OfficerBloc>().add(
                OfficerLoadOneRequested(state.updatedItem!.id),
              );
            }
          }
          if (state is OfficerFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OfficerLoading || state is OfficerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OfficerFailure) {
            return Center(child: Text(state.message));
          }
          if (state is OfficerDetailLoaded) {
            final item = state.item;
            final statusEnum = OfficerStatusX.fromString(item.status);
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
                                OfficerStatusBadge(status: statusEnum),
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
                                OfficerStatus.suspended,
                              ].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () => context
                                      .read<OfficerBloc>()
                                      .add(OfficerActivateRequested(item.id)),
                                  child: const Text('Activate'),
                                ),
                              if ([OfficerStatus.active].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () => context
                                      .read<OfficerBloc>()
                                      .add(OfficerSuspendRequested(item.id)),
                                  child: const Text('Suspend'),
                                ),
                              if ([
                                OfficerStatus.active,
                                OfficerStatus.suspended,
                              ].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () => context
                                      .read<OfficerBloc>()
                                      .add(OfficerDeactivateRequested(item.id)),
                                  child: const Text('Deactivate'),
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
                          _buildField(context, 'Role', item.role),
                          _buildField(context, 'Email', item.email),
                          _buildField(context, 'Phone', item.phone),
                          _buildField(context, 'Status', item.status),
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
