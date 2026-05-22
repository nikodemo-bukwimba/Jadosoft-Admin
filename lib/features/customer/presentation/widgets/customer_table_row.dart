// lib/features/customer/presentation/widgets/customer_table_row.dart
// (jadosoft-admin)
// Wide-screen table layout. Location column now shows Ward · District · Region.

import 'package:flutter/material.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerTableRow extends StatelessWidget {
  final CustomerEntity item;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CustomerTableRow({
    super.key,
    required this.item,
    required this.isLast,
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

    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  scheme.primaryContainer.withValues(alpha: 0.5),
              child: Icon(
                item.isB2B ? Icons.store : Icons.person,
                color: scheme.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              flex: 3,
              child: Text(
                item.name,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Type + category
            Expanded(
              flex: 2,
              child: Text(
                '${item.customerType.toUpperCase()}'
                '${item.category != null ? ' · ${item.category}' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Phone
            Expanded(
              flex: 2,
              child: Text(
                item.phone ?? '',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Location — ward · district · region
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  if (location.isNotEmpty)
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  if (location.isNotEmpty) const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      location,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.hasGps)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.gps_fixed,
                        size: 11,
                        color: scheme.primary.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 40,
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: scheme.error,
                  size: 18,
                ),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}