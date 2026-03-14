import 'package:flutter/material.dart';
import '../../domain/entities/visit_entity.dart';
import '../../domain/value_objects/visit_status.dart';
import '../../../../core/utils/map_launcher.dart';

class VisitTableRow extends StatelessWidget {
  final VisitEntity item;
  final bool isLast;
  final VoidCallback onTap;

  const VisitTableRow({
    super.key,
    required this.item,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final st = VisitStatusX.fromString(item.status);
    final hasGps = item.gpsLat != null && item.gpsLng != null;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 14, backgroundColor: st.color.withValues(alpha: 0.15),
            child: Icon(Icons.location_on, color: st.color, size: 14)),
          const SizedBox(width: 12),

          Expanded(flex: 3,
            child: Text(item.businessName ?? 'Unknown',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis)),

          Expanded(flex: 2,
            child: Text(item.visitDate.toIso8601String().split('T').first,
              style: Theme.of(context).textTheme.bodySmall)),

          // GPS icon column — tappable when coords exist
          Tooltip(
            message: hasGps ? 'Open in Map' : 'No GPS',
            child: IconButton(
              icon: Icon(
                hasGps ? Icons.gps_fixed : Icons.gps_not_fixed_outlined,
                size: 16,
                color: hasGps ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              onPressed: hasGps
                  ? () => MapLauncher.open(
                        lat: item.gpsLat!,
                        lng: item.gpsLng!,
                        label: item.businessName ?? 'Visit Location',
                      )
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32),
            ),
          ),

          Expanded(flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: st.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
              child: Text(st.displayName,
                style: TextStyle(color: st.color, fontSize: 10, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            )),
        ]),
      ),
    );
  }
}