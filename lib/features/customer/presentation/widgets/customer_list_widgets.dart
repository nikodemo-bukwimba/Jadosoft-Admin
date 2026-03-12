import 'package:flutter/material.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../domain/entities/customer_entity.dart';

// ─────────────────────────────────────────────────────────────
// List view row — compact. Tap GPS icon → open in map.
// ─────────────────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasGps = item.gpsLat != null && item.gpsLng != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      scheme.primaryContainer.withValues(alpha: 0.5),
                  child: Icon(Icons.store, color: scheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.businessName,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.ownerName} • ${item.officialPhone}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // GPS icon — tappable when coords exist
                Tooltip(
                  message: hasGps ? 'Open in Map' : 'No GPS',
                  child: IconButton(
                    icon: Icon(
                      hasGps ? Icons.gps_fixed : Icons.gps_not_fixed_outlined,
                      size: 18,
                      color: hasGps
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.35),
                    ),
                    onPressed: hasGps
                        ? () => MapLauncher.open(
                              lat: item.gpsLat!,
                              lng: item.gpsLng!,
                              label: item.businessName,
                            )
                        : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 32,
                  child: IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: scheme.error, size: 18),
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

// ─────────────────────────────────────────────────────────────
// Details / table view row. Tap GPS icon → open in map.
// ─────────────────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasGps = item.gpsLat != null && item.gpsLng != null;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
              child: Icon(Icons.store, color: scheme.primary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                item.businessName,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.ownerName,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.officialPhone,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // GPS icon column
            Tooltip(
              message: hasGps ? 'Open in Map' : 'No GPS',
              child: IconButton(
                icon: Icon(
                  hasGps ? Icons.gps_fixed : Icons.gps_not_fixed_outlined,
                  size: 17,
                  color: hasGps
                      ? scheme.primary
                      : scheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
                onPressed: hasGps
                    ? () => MapLauncher.open(
                          lat: item.gpsLat!,
                          lng: item.gpsLng!,
                          label: item.businessName,
                        )
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
              ),
            ),
            SizedBox(
              width: 32,
              child: IconButton(
                icon:
                    Icon(Icons.delete_outline, color: scheme.error, size: 18),
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