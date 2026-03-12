import 'package:flutter/material.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../domain/entities/customer_entity.dart';
import '../../../officer/data/datasources/officer_mock_datasource.dart';

/// Cards view tile. Tap the GPS row to open location in Maps.
class CustomerCardTile extends StatelessWidget {
  final CustomerEntity item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CustomerCardTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  Future<String> _getOfficerName() async {
    try {
      final ds = OfficerMockDataSource();
      final officer = await ds.getById(item.assignedOfficerId);
      return officer.name;
    } catch (_) {
      return item.assignedOfficerId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasGps = item.gpsLat != null && item.gpsLng != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
                child: Icon(Icons.store, color: scheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.businessName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _infoRow(context, Icons.person_outline, item.ownerName),
                    _infoRow(context, Icons.phone_outlined, item.officialPhone),
                    if (item.officeAddress != null &&
                        item.officeAddress!.isNotEmpty)
                      _infoRow(
                        context,
                        Icons.location_on_outlined,
                        item.officeAddress!,
                      ),
                    // GPS row — tappable when coords exist
                    if (hasGps)
                      _gpsRow(context)
                    else
                      _infoRow(
                        context,
                        Icons.gps_not_fixed_outlined,
                        'No GPS',
                        muted: true,
                      ),
                    FutureBuilder<String>(
                      future: _getOfficerName(),
                      builder: (_, snap) => _infoRow(
                        context,
                        Icons.badge_outlined,
                        snap.data ?? '...',
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: scheme.error, size: 20),
                tooltip: 'Delete',
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gpsRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Tooltip(
        message: 'Open in Map',
        child: InkWell(
          onTap: () => MapLauncher.open(
            lat: item.gpsLat!,
            lng: item.gpsLng!,
            label: item.businessName,
          ),
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Icon(Icons.gps_fixed, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${item.gpsLat!.toStringAsFixed(4)}, '
                  '${item.gpsLng!.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: scheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.open_in_new, size: 11, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String text, {
    bool isPrimary = false,
    bool muted = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final color = muted
        ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
        : isPrimary
        ? scheme.primary
        : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: isPrimary ? FontWeight.w600 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
