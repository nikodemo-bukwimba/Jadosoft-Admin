// lib/features/customer/presentation/widgets/customer_list_row.dart
// (jadosoft-admin)
// Compact list item. Subtitle now shows location summary when available.

import 'package:flutter/material.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerListRow extends StatelessWidget {
  final CustomerEntity item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CustomerListRow({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  String _locationSummary() {
    final parts = <String>[
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      scheme.primaryContainer.withValues(alpha: 0.5),
                  child: Icon(
                    item.isB2B ? Icons.store : Icons.person,
                    color: scheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row
                      Text(
                        item.name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Type + phone
                      Text(
                        '${item.customerType.toUpperCase()}'
                        '${item.phone != null ? ' · ${item.phone}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Location summary
                      if (location.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 11,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                location,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                      fontSize: 11,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (item.hasGps)
                  Icon(
                    Icons.gps_fixed,
                    size: 16,
                    color: scheme.primary.withValues(alpha: 0.5),
                  ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 36,
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: scheme.error,
                      size: 18,
                    ),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}