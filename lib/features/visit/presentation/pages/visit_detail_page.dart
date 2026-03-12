import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';
import '../../domain/value_objects/visit_status.dart';
import '../widgets/visit_status_badge.dart';

class VisitDetailPage extends StatelessWidget {
  const VisitDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visits Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<VisitBloc>().state;
              if (state is VisitDetailLoaded) {
                Navigator.of(
                  context,
                ).pushNamed('/visits/edit', arguments: {'id': state.item.id});
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<VisitBloc, VisitState>(
        listener: (context, state) {
          if (state is VisitOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            if (state.updatedItem != null) {
              context.read<VisitBloc>().add(
                VisitLoadOneRequested(state.updatedItem!.id),
              );
            }
          }
          if (state is VisitFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is VisitLoading || state is VisitInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VisitFailure) {
            return Center(child: Text(state.message));
          }
          if (state is VisitDetailLoaded) {
            final item = state.item;
            final statusEnum = VisitStatusX.fromString(item.status);
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
                                VisitStatusBadge(status: statusEnum),
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
                              if ([VisitStatus.pending].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () => context
                                      .read<VisitBloc>()
                                      .add(VisitReviewRequested(item.id)),
                                  child: const Text('Mark Reviewed'),
                                ),
                              if ([VisitStatus.reviewed].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () => context
                                      .read<VisitBloc>()
                                      .add(VisitFlagRequested(item.id)),
                                  child: const Text('Flag Visit'),
                                ),
                              if ([VisitStatus.flagged].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () => context
                                      .read<VisitBloc>()
                                      .add(VisitUnflagRequested(item.id)),
                                  child: const Text('Remove Flag'),
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
                            'Business Name',
                            item.businessName ?? '',
                          ),
                          _buildField(
                            context,
                            'Visit Date',
                            item.visitDate.toIso8601String().split('T').first,
                          ),
                          _buildField(context, 'Customer Id', item.customerId),
                          _buildField(context, 'Officer Id', item.officerId),
                          _buildField(
                            context,
                            'Owner Phone',
                            item.ownerPhone ?? '',
                          ),
                          _buildField(
                            context,
                            'Contact Person Phone',
                            item.contactPersonPhone ?? '',
                          ),
                          _buildField(
                            context,
                            'Business Phone',
                            item.businessPhone ?? '',
                          ),
                          _buildField(context, 'Notes', item.notes ?? ''),
                          _buildField(
                            context,
                            'Gps Lat',
                            item.gpsLat?.toStringAsFixed(2) ?? '',
                          ),
                          _buildField(
                            context,
                            'Gps Lng',
                            item.gpsLng?.toStringAsFixed(2) ?? '',
                          ),
                          _buildField(
                            context,
                            'Image Urls',
                            item.imageUrls?.join(', ') ?? '',
                          ),
                          _buildField(
                            context,
                            'Document Urls',
                            item.documentUrls?.join(', ') ?? '',
                          ),
                          _buildField(
                            context,
                            'Promoted Product Ids',
                            item.promotedProductIds?.join(', ') ?? '',
                          ),
                          _buildField(
                            context,
                            'Discussion Summary',
                            item.discussionSummary ?? '',
                          ),
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
