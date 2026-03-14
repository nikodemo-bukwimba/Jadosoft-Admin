import 'package:flutter/material.dart';
import '../../domain/entities/visit_entity.dart';
import '../../domain/value_objects/visit_status.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../officer/data/datasources/officer_mock_datasource.dart';

class VisitCardTile extends StatelessWidget {
  final VisitEntity item;
  final VoidCallback onTap;

  const VisitCardTile({super.key, required this.item, required this.onTap});

  Future<String> _officerName() async {
    try {
      return (await OfficerMockDataSource().getById(item.officerId)).name;
    } catch (_) {
      return item.officerId;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final st = VisitStatusX.fromString(item.status);
    final hasGps = item.gpsLat != null && item.gpsLng != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: st.color.withValues(alpha: 0.15),
                    child: Icon(Icons.location_on, color: st.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.businessName ?? 'Unknown Business',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        FutureBuilder<String>(
                          future: _officerName(),
                          builder: (_, s) => Text(
                            'by ${s.data ?? '...'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: st),
                ],
              ),

              // Discussion summary
              if (item.discussionSummary != null &&
                  item.discussionSummary!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.discussionSummary!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 8),

              // Footer row — date, GPS (tappable), photos
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(item.visitDate),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),

                  // GPS chip — tappable when coords exist
                  if (hasGps) ...[
                    const SizedBox(width: 12),
                    Tooltip(
                      message: 'Open in Map',
                      child: InkWell(
                        onTap: () => MapLauncher.open(
                          lat: item.gpsLat!,
                          lng: item.gpsLng!,
                          label: item.businessName ?? 'Visit Location',
                        ),
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.gps_fixed,
                              size: 14,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'GPS',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: scheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (item.imageUrls != null && item.imageUrls!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.photo_library_outlined,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.imageUrls!.length}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final VisitStatus status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: status.color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: status.color.withValues(alpha: 0.4)),
    ),
    child: Text(
      status.displayName,
      style: TextStyle(
        color: status.color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
