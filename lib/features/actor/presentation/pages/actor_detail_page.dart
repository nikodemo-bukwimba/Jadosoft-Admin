// actor_detail_page.dart
// ─────────────────────────────────────────────────────────────
// Phase 2: Shows actor types as chips, status badge, metadata.
// Uses GoRouter (context.push) for navigation.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/actor_entity.dart';
import '../bloc/actor_bloc.dart';
import '../bloc/actor_event.dart';
import '../bloc/actor_state.dart';

class ActorDetailPage extends StatelessWidget {
  const ActorDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actor Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () async {
              final bloc = context.read<ActorBloc>();
              final state = bloc.state;
              if (state is ActorDetailLoaded) {
                final updated = await context.push<bool>(
                  AppRouter.actorEditPath(state.item.id),
                );
                // Re-fetch actor when edit was successful
                if (updated == true) {
                  bloc.add(ActorLoadOneRequested(state.item.id));
                }
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<ActorBloc, ActorState>(
        builder: (context, state) {
          if (state is ActorLoading || state is ActorInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ActorFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () {
                      // Retry — pop and let list re-push
                      context.pop();
                    },
                  ),
                ],
              ),
            );
          }
          if (state is ActorDetailLoaded) {
            return _ActorDetailBody(item: state.item);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ActorDetailBody extends StatelessWidget {
  final ActorEntity item;
  const _ActorDetailBody({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ──────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          item.displayName.isNotEmpty
                              ? item.displayName[0].toUpperCase()
                              : '?',
                          style: textTheme.headlineSmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayName,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _StatusBadge(status: item.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildField(context, 'ID', item.id),
                  _buildField(
                    context,
                    'Created',
                    item.createdAt.toIso8601String().split('T').first,
                  ),
                  _buildField(
                    context,
                    'Updated',
                    item.updatedAt.toIso8601String().split('T').first,
                  ),
                  if (item.deletedAt != null)
                    _buildField(
                      context,
                      'Deleted',
                      item.deletedAt!.toIso8601String().split('T').first,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Actor Types card ─────────────────────────────
          if (item.actorTypes.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Actor Types',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.actorTypes
                          .map(
                            (t) => Chip(
                              avatar: CircleAvatar(
                                backgroundColor: scheme.primaryContainer,
                                child: Text(
                                  t.label[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              label: Text(t.label),
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

          // ── Metadata card ────────────────────────────────
          if (item.metadata != null && item.metadata!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.data_object,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Metadata',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...item.metadata!.entries.map(
                      (e) => _buildField(context, e.key, e.value.toString()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      'active' => (Colors.green.shade50, Colors.green.shade700),
      'pending' => (Colors.orange.shade50, Colors.orange.shade700),
      'suspended' => (Colors.red.shade50, Colors.red.shade700),
      'inactive' => (Colors.grey.shade200, Colors.grey.shade600),
      _ => (
        Theme.of(context).colorScheme.surfaceContainerHighest,
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
