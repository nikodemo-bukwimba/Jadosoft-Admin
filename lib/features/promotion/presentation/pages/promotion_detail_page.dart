import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/promotion_bloc.dart';
import '../bloc/promotion_event.dart';
import '../bloc/promotion_state.dart';
import '../../domain/value_objects/promotion_status.dart';
import '../widgets/promotion_status_badge.dart';

class PromotionDetailPage extends StatelessWidget {
  const PromotionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<PromotionBloc>().state;
              if (state is PromotionDetailLoaded) {
                Navigator.of(context).pushNamed(
                  '/promotions/edit',
                  arguments: {'id': state.item.id},
                );
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<PromotionBloc, PromotionState>(
        listener: (context, state) {
          if (state is PromotionOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            if (state.updatedItem != null) {
              context.read<PromotionBloc>()
                  .add(PromotionLoadOneRequested(state.updatedItem!.id));
            }
          }
          if (state is PromotionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PromotionLoading || state is PromotionInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PromotionFailure) {
            return Center(child: Text(state.message));
          }
          if (state is PromotionDetailLoaded) {
            final item = state.item;
            final statusEnum = PromotionStatusX.fromString(item.status);
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
                               PromotionStatusBadge(status: statusEnum),
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
                    if ([PromotionStatus.draft].contains(statusEnum))
                      FilledButton.tonal(
                        onPressed: () => context.read<PromotionBloc>()
                            .add(PromotionActivateRequested(item.id)),
                        child: const Text('Activate Promotion'),
                      ),
                    if ([PromotionStatus.active].contains(statusEnum))
                      FilledButton.tonal(
                        onPressed: () => context.read<PromotionBloc>()
                            .add(PromotionEndRequested(item.id)),
                        child: const Text('End Promotion'),
                      ),
                    if ([PromotionStatus.draft, PromotionStatus.active].contains(statusEnum))
                      FilledButton.tonal(
                        onPressed: () => context.read<PromotionBloc>()
                            .add(PromotionCancelRequested(item.id)),
                        child: const Text('Cancel Promotion'),
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
                    _buildField(context, 'Title', item.title),
                    _buildField(context, 'Description', item.description ?? ''),
                    _buildField(context, 'Product Ids', item.productIds.join(', ')),
                    _buildField(context, 'Start Date', item.startDate.toIso8601String().split('T').first),
                    _buildField(context, 'End Date', item.endDate.toIso8601String().split('T').first),
                    _buildField(context, 'Channels', item.channels.join(', ')),
                    _buildField(context, 'Status', item.status),
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
