// actor_card.dart
// ─────────────────────────────────────────────────────────────
// Phase 2: shows actor types as chips + status badge.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../domain/entities/actor_entity.dart';

class ActorCard extends StatelessWidget {
  final ActorEntity item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ActorCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ── Avatar with first letter ─────────────────
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  item.displayName.isNotEmpty
                      ? item.displayName[0].toUpperCase()
                      : '?',
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Name + types ─────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.actorTypes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: item.actorTypes
                            .map(
                              (t) => _TypeChip(label: t.label, scheme: scheme),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Status badge + delete ────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(status: item.status, scheme: scheme),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 32,
                    width: 32,
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: scheme.error,
                      ),
                      tooltip: 'Delete',
                      padding: EdgeInsets.zero,
                      onPressed: () => _confirmDelete(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Remove "${item.displayName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }
}

// ── Private sub-widgets ──────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final ColorScheme scheme;
  const _TypeChip({required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final ColorScheme scheme;
  const _StatusBadge({required this.status, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      'active' => (Colors.green.shade50, Colors.green.shade700),
      'pending' => (Colors.orange.shade50, Colors.orange.shade700),
      'suspended' => (Colors.red.shade50, Colors.red.shade700),
      'inactive' => (Colors.grey.shade200, Colors.grey.shade600),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
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
