import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/visit_entity.dart';
import '../../domain/value_objects/visit_status.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../officer/data/datasources/officer_mock_datasource.dart';
import '../../../customer/data/datasources/customer_mock_datasource.dart';

class VisitDetailPage extends StatelessWidget {
  const VisitDetailPage({super.key});

  Future<String> _officerName(String id) async {
    try {
      return (await OfficerMockDataSource().getById(id)).name;
    } catch (_) {
      return id;
    }
  }

  Future<String> _customerName(String id) async {
    try {
      return (await CustomerMockDataSource().getById(id)).businessName;
    } catch (_) {
      return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Visit Detail')),
      body: BlocConsumer<VisitBloc, VisitState>(
        listener: (c, s) {
          if (s is VisitOperationSuccess) {
            ScaffoldMessenger.of(
              c,
            ).showSnackBar(SnackBar(content: Text(s.message)));
            if (s.updatedItem != null)
              c.read<VisitBloc>().add(VisitLoadOneRequested(s.updatedItem!.id));
            else
              c.pop();
          }
          if (s is VisitFailure)
            ScaffoldMessenger.of(c).showSnackBar(
              SnackBar(content: Text(s.message), backgroundColor: scheme.error),
            );
        },
        builder: (c, s) {
          if (s is VisitLoading || s is VisitInitial)
            return const Center(child: CircularProgressIndicator());
          if (s is VisitFailure)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: scheme.error),
                  const SizedBox(height: 16),
                  Text(s.message),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => c.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            );
          if (s is VisitDetailLoaded) return _body(context, s.item);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _body(BuildContext context, VisitEntity item) {
    final scheme = Theme.of(context).colorScheme;
    final st = VisitStatusX.fromString(item.status);
    final isWide = MediaQuery.of(context).size.width >= 600;
    final hasGps = item.gpsLat != null && item.gpsLng != null;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? MediaQuery.of(context).size.width * 0.1 : 16,
        vertical: 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: st.color.withValues(alpha: 0.15),
                      child: Icon(Icons.location_on, color: st.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.businessName ?? 'Unknown Business',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<String>(
                            future: _officerName(item.officerId),
                            builder: (_, s) => Text(
                              'Visited by ${s.data ?? '...'}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: st.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: st.color.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              st.displayName,
                              style: TextStyle(
                                color: st.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Admin Actions ────────────────────────────────────────
            _actions(context, item, st),

            // ── Discussion Summary ───────────────────────────────────
            if (item.discussionSummary != null &&
                item.discussionSummary!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discussion Summary',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Divider(height: 20),
                      Text(
                        item.discussionSummary!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Visit Details ────────────────────────────────────────
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visit Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(height: 24),
                    FutureBuilder<String>(
                      future: _customerName(item.customerId),
                      builder: (_, s) => _row(
                        context,
                        Icons.store,
                        'Customer',
                        s.data ?? '...',
                      ),
                    ),
                    FutureBuilder<String>(
                      future: _officerName(item.officerId),
                      builder: (_, s) => _row(
                        context,
                        Icons.badge,
                        'Officer',
                        s.data ?? '...',
                      ),
                    ),
                    _row(
                      context,
                      Icons.calendar_today,
                      'Visit Date',
                      item.visitDate.toIso8601String().split('T').first,
                    ),
                    if (item.ownerPhone != null)
                      _row(
                        context,
                        Icons.phone,
                        'Owner Phone',
                        item.ownerPhone!,
                      ),
                    if (item.businessPhone != null)
                      _row(
                        context,
                        Icons.phone_android,
                        'Business Phone',
                        item.businessPhone!,
                      ),
                    // GPS row — tappable when coords exist
                    if (hasGps)
                      _gpsRow(context, item)
                    else
                      _row(
                        context,
                        Icons.gps_not_fixed_outlined,
                        'GPS',
                        'Not recorded',
                        muted: true,
                      ),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      _row(context, Icons.notes, 'Notes', item.notes!),
                    _row(context, Icons.fingerprint, 'ID', item.id),
                  ],
                ),
              ),
            ),

            // ── Photos ───────────────────────────────────────────────
            if (item.imageUrls != null && item.imageUrls!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Photos (${item.imageUrls!.length})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: item.imageUrls!.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item.imageUrls![i],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 120,
                                  height: 120,
                                  color: scheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// GPS row — tappable, opens map.
  Widget _gpsRow(BuildContext context, VisitEntity item) {
    final scheme = Theme.of(context).colorScheme;
    final coords =
        '${item.gpsLat!.toStringAsFixed(4)}, ${item.gpsLng!.toStringAsFixed(4)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Tooltip(
        message: 'Open in Map',
        child: InkWell(
          onTap: () => MapLauncher.open(
            lat: item.gpsLat!,
            lng: item.gpsLng!,
            label: item.businessName ?? 'Visit Location',
          ),
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Icon(Icons.gps_fixed, size: 20, color: scheme.primary),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: Text(
                  'GPS',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  coords,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: scheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: scheme.primary,
                  ),
                ),
              ),
              Icon(Icons.open_in_new, size: 14, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, VisitEntity item, VisitStatus st) {
    final actions = <Widget>[];
    if (st == VisitStatus.pending)
      actions.add(
        _btn(
          context,
          Icons.check_circle_outline,
          'Mark Reviewed',
          Colors.green,
          () => context.read<VisitBloc>().add(VisitReviewRequested(item.id)),
        ),
      );
    if (st == VisitStatus.reviewed)
      actions.add(
        _btn(
          context,
          Icons.flag_outlined,
          'Flag Visit',
          Colors.red,
          () => context.read<VisitBloc>().add(VisitFlagRequested(item.id)),
        ),
      );
    if (st == VisitStatus.flagged)
      actions.add(
        _btn(
          context,
          Icons.flag,
          'Remove Flag',
          Colors.green,
          () => context.read<VisitBloc>().add(VisitUnflagRequested(item.id)),
        ),
      );
    if (actions.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Actions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(height: 20),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ),
      ),
    );
  }

  Widget _btn(
    BuildContext c,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) => FilledButton.tonalIcon(
    onPressed: onPressed,
    icon: Icon(icon, size: 18, color: color),
    label: Text(label),
    style: FilledButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
  );

  Widget _row(
    BuildContext c,
    IconData icon,
    String label,
    String value, {
    bool muted = false,
  }) {
    final scheme = Theme.of(c).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: muted
                ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
                : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(
                c,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(c).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: muted
                    ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
