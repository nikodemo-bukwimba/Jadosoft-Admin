import 'package:flutter/material.dart';
import '../../domain/entities/visit_entity.dart';
import '../../domain/value_objects/visit_status.dart';
import '../../../../core/utils/map_launcher.dart';

class VisitListRow extends StatelessWidget {
  final VisitEntity item;
  final VoidCallback onTap;

  const VisitListRow({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final st = VisitStatusX.fromString(item.status);
    final hasGps = item.gpsLat != null && item.gpsLng != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: st.color.withValues(alpha: 0.15),
                child: Icon(Icons.location_on, color: st.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.businessName ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.visitDate.toIso8601String().split('T').first,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
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
                        : scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  onPressed: hasGps
                      ? () => MapLauncher.open(
                          lat: item.gpsLat!,
                          lng: item.gpsLng!,
                          label: item.businessName ?? 'Visit Location',
                        )
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: st.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  st.displayName,
                  style: TextStyle(
                    color: st.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
