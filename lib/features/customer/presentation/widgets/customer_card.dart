// lib/features/customer/presentation/widgets/customer_card.dart
// (jadosoft-admin)
// Shows: name, type/category, phone, location summary (street→ward→district→region),
// GPS indicator. Delete confirmation preserved.

import 'package:flutter/material.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerCard extends StatelessWidget {
  final CustomerEntity item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CustomerCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  /// Build a concise one-line location summary from the hierarchy,
  /// most-specific level first: Street · Ward · District · Region
  String _locationSummary() {
    final parts = <String>[
      if (item.street != null && item.street!.isNotEmpty) item.street!,
      if (item.ward != null && item.ward!.isNotEmpty) item.ward!,
      if (item.city != null && item.city!.isNotEmpty) item.city!,
      if (item.county != null && item.county!.isNotEmpty) item.county!,
    ];
    return parts.isEmpty ? (item.address ?? '') : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final location = _locationSummary();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
          child: Icon(
            item.isB2B ? Icons.store : Icons.person,
            color: scheme.primary,
            size: 18,
          ),
        ),
        title: Text(
          item.name,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.customerType.toUpperCase()}'
              '${item.category != null ? ' · ${item.category}' : ''}'
              '${item.phone != null ? ' · ${item.phone}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (location.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      location,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.hasGps) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.gps_fixed,
                      size: 11,
                      color: scheme.primary.withValues(alpha: 0.6),
                    ),
                  ],
                ],
              ),
          ],
        ),
        isThreeLine: location.isNotEmpty,
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: scheme.error),
          tooltip: 'Delete',
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete?'),
                content: Text('Remove "${item.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (ok == true) onDelete();
          },
        ),
      ),
    );
  }
}