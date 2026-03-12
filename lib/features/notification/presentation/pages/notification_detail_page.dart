import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../../domain/value_objects/notification_status.dart';
import '../widgets/notification_status_badge.dart';

class NotificationDetailPage extends StatelessWidget {
  const NotificationDetailPage({super.key});

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<NotificationBloc>().state;
              if (state is NotificationDetailLoaded) {
                Navigator.of(context).pushNamed(
                  '/notifications/edit',
                  arguments: {'id': state.item.id},
                );
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            if (state.updatedItem != null) {
              context.read<NotificationBloc>()
                  .add(NotificationLoadOneRequested(state.updatedItem!.id));
            }
          }
          if (state is NotificationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading || state is NotificationInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationFailure) {
            return Center(child: Text(state.message));
          }
          if (state is NotificationDetailLoaded) {
            final item = state.item;
            final statusEnum = NotificationStatusX.fromString(item.status);
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
                                NotificationStatusBadge(status: statusEnum)
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
                    if ([NotificationStatus.failed].contains(statusEnum))
                      FilledButton.tonal(
                        onPressed: () => context.read<NotificationBloc>()
                            .add(NotificationRetryRequested(item.id)),
                        child: const Text('Retry Notification'),
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
                    _buildField(context, 'Recipient Id', item.recipientId),
                    _buildField(context, 'Channel', item.channel),
                    _buildField(context, 'Recipient Type', item.recipientType),
                    _buildField(context, 'Content', item.content),
                    _buildField(context, 'Template Id', item.templateId ?? ''),
                    _buildField(context, 'Status', item.status),
                    _buildField(context, 'Sent At', item.sentAt != null ? item.sentAt!.toIso8601String().split('T').first : ''),
                    _buildField(context, 'Delivered At', item.deliveredAt != null ? item.deliveredAt!.toIso8601String().split('T').first : ''),
                    _buildField(context, 'Failure Reason', item.failureReason ?? ''),
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
