import 'package:flutter/material.dart';
import '../../../../config/di/injection_container.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../domain/entities/customer_entity.dart';
import '../../../officer/data/datasources/officer_remote_datasource.dart';

/// Cards view tile. Tap the GPS row to open location in Maps.
/// Shows officer name resolved via DI.
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

  /// Resolve officer display name from assigned_officer_id (actorId).
  Future<String> _getOfficerName() async {
    final officerId = item.assignedOfficerId;
    if (officerId == null || officerId.isEmpty) return 'Not assigned';
    try {
      final ds = sl<OfficerRemoteDataSource>();
      final result = await ds.getAll();
      final match =
          result.items.where((o) => o.actorId == officerId).firstOrNull ??
          result.items.where((o) => o.userId == officerId).firstOrNull;
      if (match != null) return match.displayName;
      return officerId;
    } catch (_) {
      return officerId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final contact = item.primaryContact;

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
                child: Icon(
                  item.isB2B ? Icons.store : Icons.person,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Name + tier chip ──
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _tierChip(context, item.tier),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // ── Type + category ──
                    _infoRow(
                      context,
                      Icons.label_outlined,
                      '${item.customerType.toUpperCase()}${item.category != null ? ' · ${item.category}' : ''}',
                    ),

                    // ── Primary contact person ──
                    if (contact != null)
                      _infoRow(
                        context,
                        Icons.person_outline,
                        '${contact.name}${contact.role != null ? ' (${contact.role})' : ''}',
                      ),

                    // ── Phone ──
                    if (item.phone != null)
                      _infoRow(context, Icons.phone_outlined, item.phone!),

                    // ── Address ──
                    if (item.address != null && item.address!.isNotEmpty)
                      _infoRow(
                        context,
                        Icons.location_on_outlined,
                        item.address!,
                      ),

                    // ── GPS row — tappable when coords exist ──
                    if (item.hasGps)
                      _gpsRow(context)
                    else
                      _infoRow(
                        context,
                        Icons.gps_not_fixed_outlined,
                        'No GPS',
                        muted: true,
                      ),

                    // ── Assigned officer via FutureBuilder ──
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

  Widget _tierChip(BuildContext context, String tier) {
    final color = switch (tier) {
      'platinum' => Colors.deepPurple,
      'gold' => Colors.amber.shade700,
      'silver' => Colors.blueGrey,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tier,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
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
            lat: item.latitude!,
            lng: item.longitude!,
            label: item.name,
          ),
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Icon(Icons.gps_fixed, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${item.latitude!.toStringAsFixed(4)}, ${item.longitude!.toStringAsFixed(4)}',
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
