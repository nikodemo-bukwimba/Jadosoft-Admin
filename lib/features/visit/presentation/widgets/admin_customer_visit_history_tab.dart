import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../../config/di/injection_container.dart';
import '../../domain/entities/visit_entity.dart';
import '../../domain/value_objects/visit_status.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';

/// Read-only visit history for a customer shown in the admin
/// CustomerDetailPage Visits tab. Shows all visits from all officers.
class AdminCustomerVisitHistoryTab extends StatefulWidget {
  final String customerId;
  const AdminCustomerVisitHistoryTab({super.key, required this.customerId});

  @override
  State<AdminCustomerVisitHistoryTab> createState() =>
      _AdminCustomerVisitHistoryTabState();
}

class _AdminCustomerVisitHistoryTabState
    extends State<AdminCustomerVisitHistoryTab> {
  @override
  void initState() {
    super.initState();
    context
        .read<VisitBloc>()
        .add(VisitLoadByCustomerRequested(widget.customerId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VisitBloc, VisitState>(
      buildWhen: (_, s) =>
          s is VisitLoading ||
          s is VisitFailure ||
          s is CustomerVisitHistoryLoaded,
      builder: (context, state) {
        if (state is VisitLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is VisitFailure) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context
                .read<VisitBloc>()
                .add(VisitLoadByCustomerRequested(widget.customerId)),
          );
        }
        if (state is CustomerVisitHistoryLoaded) {
          if (state.items.isEmpty) return const _EmptyView();
          final sorted = List<VisitEntity>.from(state.items)
            ..sort((a, b) => b.visitDate.compareTo(a.visitDate));
          return _HistoryList(visits: sorted);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<VisitEntity> visits;
  const _HistoryList({required this.visits});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: visits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) =>
          _VisitCard(visit: visits[i], isFirst: i == 0),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final VisitEntity visit;
  final bool isFirst;
  const _VisitCard({required this.visit, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final st = VisitStatusX.fromString(visit.status);
    final hasGps = visit.gpsLat != null && visit.gpsLng != null;
    final date = _fmt(visit.visitDate);
    final officerDisplay = visit.officerName ?? visit.officerId;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isFirst
              ? scheme.primary.withValues(alpha: 0.4)
              : scheme.outlineVariant.withValues(alpha: 0.3),
          width: isFirst ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(AppRouter.visitDetailPath(visit.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: date + latest label + status badge ─────────────────
              Row(
                children: [
                  if (isFirst) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Latest',
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(Icons.calendar_today_outlined,
                      size: 13, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  _Badge(label: st.displayName, color: st.color),
                ],
              ),
              const SizedBox(height: 10),

              // ── Row 2: visit type + officer ───────────────────────────────
              Row(
                children: [
                  if (visit.visitType != null)
                    _InfoChip(
                      icon: Icons.directions_walk,
                      label: visit.visitType!
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      scheme: scheme,
                    ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.person_outline,
                    label: officerDisplay,
                    scheme: scheme,
                  ),
                ],
              ),

              // ── Objective ─────────────────────────────────────────────────
              if (visit.objective != null &&
                  visit.objective!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.flag_outlined,
                  label: 'Objective',
                  value: visit.objective!,
                  scheme: scheme,
                ),
              ],

              // ── Discussion ────────────────────────────────────────────────
              if (visit.discussionSummary != null &&
                  visit.discussionSummary!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _DetailRow(
                  icon: Icons.chat_bubble_outline,
                  label: 'Discussion',
                  value: visit.discussionSummary!,
                  scheme: scheme,
                  maxLines: 2,
                ),
              ],

              // ── Outcome ───────────────────────────────────────────────────
              if (visit.outcome != null &&
                  visit.outcome!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _DetailRow(
                  icon: Icons.check_circle_outline,
                  label: 'Outcome',
                  value: visit.outcome!,
                  scheme: scheme,
                  valueColor: _outcomeColor(visit.outcomeStatus),
                ),
              ],

              // ── Flag reason ───────────────────────────────────────────────
              if (visit.flagReason != null &&
                  visit.flagReason!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _DetailRow(
                  icon: Icons.flag,
                  label: 'Flag',
                  value: visit.flagReason!,
                  scheme: scheme,
                  valueColor: scheme.error,
                  maxLines: 2,
                ),
              ],

              // ── Admin comments ─────────────────────────────────────────────
              if (visit.adminComments.isNotEmpty) ...[
                const SizedBox(height: 6),
                _DetailRow(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Admin note',
                  value: visit.adminComments.last.comment,
                  scheme: scheme,
                  valueColor: scheme.tertiary,
                  maxLines: 2,
                ),
              ],

              // ── Footer: duration + photos + gps ───────────────────────────
              const SizedBox(height: 10),
              Row(
                children: [
                  if (visit.durationMinutes != null) ...[
                    Icon(Icons.timer_outlined,
                        size: 13, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(
                      '${visit.durationMinutes} min',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (visit.imageUrls != null &&
                      visit.imageUrls!.isNotEmpty) ...[
                    Icon(Icons.photo_library_outlined,
                        size: 13, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(
                      '${visit.imageUrls!.length} photo(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Spacer(),
                  if (hasGps)
                    Tooltip(
                      message: 'Open visit location in map',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => MapLauncher.open(
                          lat: visit.gpsLat!,
                          lng: visit.gpsLng!,
                          label: visit.businessName ?? '',
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.gps_fixed,
                              size: 15, color: scheme.primary),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 16,
                      color:
                          scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Color _outcomeColor(String? s) => switch (s) {
        'positive' => Colors.green,
        'negative' => Colors.red,
        'follow_up_needed' => Colors.orange,
        _ => Colors.grey,
      };
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme scheme;
  const _InfoChip(
      {required this.icon, required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme scheme;
  final Color? valueColor;
  final int maxLines;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
    this.valueColor,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          SizedBox(
            width: 72,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500, color: valueColor)),
          ),
        ],
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined,
              size: 52,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No visits recorded yet',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(
            'Visit history from all officers will appear here.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}