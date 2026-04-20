import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/weekly_plan_entity.dart';
import '../../domain/value_objects/weekly_plan_status.dart';
import '../bloc/weekly_plan_bloc.dart';
import '../bloc/weekly_plan_event.dart';
import '../bloc/weekly_plan_state.dart';
import '../../../officer/data/datasources/officer_mock_datasource.dart';

class WeeklyPlanDetailPage extends StatelessWidget {
  const WeeklyPlanDetailPage({super.key});

  // Only called if officerName is null (mock fallback)
  Future<String> _resolveOfficerName(String id, String? name) async {
    if (name != null && name.isNotEmpty) return name;
    try {
      return (await OfficerMockDataSource().getById(id)).displayName;
    } catch (_) {
      return id;
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // String _fmtDateOpt(DateTime? d) => d != null ? _fmtDate(d) : '—';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Detail')),
      body: BlocConsumer<WeeklyPlanBloc, WeeklyPlanState>(
        listener: (c, s) {
          if (s is WeeklyPlanOperationSuccess) {
            ScaffoldMessenger.of(
              c,
            ).showSnackBar(SnackBar(content: Text(s.message)));
            if (s.updatedItem != null) {
              c.read<WeeklyPlanBloc>().add(
                WeeklyPlanLoadOneRequested(s.updatedItem!.id),
              );
            } else {
              c.pop();
            }
          }
          if (s is WeeklyPlanFailure) {
            ScaffoldMessenger.of(c).showSnackBar(
              SnackBar(content: Text(s.message), backgroundColor: scheme.error),
            );
          }
        },
        builder: (c, s) {
          if (s is WeeklyPlanLoading || s is WeeklyPlanInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s is WeeklyPlanFailure) {
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
          }
          if (s is WeeklyPlanDetailLoaded) return _body(context, s.item);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _body(BuildContext context, WeeklyPlanEntity item) {
    final scheme = Theme.of(context).colorScheme;
    final st = WeeklyPlanStatusX.fromString(item.status);
    final isWide = MediaQuery.of(context).size.width >= 600;

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
            // ── Header card ───────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: st.color.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.calendar_month,
                        color: st.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_fmtDate(item.weekStart)} – ${_fmtDate(item.weekEnd)}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          // Officer name — prefer API value, fallback mock
                          FutureBuilder<String>(
                            future: _resolveOfficerName(
                              item.officerId,
                              item.officerName,
                            ),
                            builder: (_, s) => Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  s.data ?? '...',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
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

            // ── Admin Actions ─────────────────────────────────
            _actions(context, item, st),

            // ── Planned Activities (text) ─────────────────────
            if (item.plannedActivities != null &&
                item.plannedActivities!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Planned Activities',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Divider(height: 20),
                      Text(
                        item.plannedActivities!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Planned Visits (rich items) ───────────────────
            if (item.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 18,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Planned Visits (${item.items.length})',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      ...item.items.asMap().entries.map(
                        (e) => _visitCard(
                          context,
                          e.value,
                          e.key,
                          item.items.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (item.plannedCustomerIds != null &&
                item.plannedCustomerIds!.isNotEmpty) ...[
              // Fallback: only IDs available (old mock data)
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Customers (${item.plannedCustomerIds!.length})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Divider(height: 20),
                      ...item.plannedCustomerIds!.map(
                        (cId) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.store,
                                size: 18,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                cId,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Plan Details ──────────────────────────────────
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan Details',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(height: 24),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      _row(context, Icons.notes, 'Notes', item.notes!),
                    if (item.submittedAt != null)
                      _row(
                        context,
                        Icons.upload,
                        'Submitted',
                        _fmtDate(item.submittedAt!),
                      ),
                    if (item.reviewedAt != null)
                      _row(
                        context,
                        Icons.rate_review,
                        'Reviewed',
                        _fmtDate(item.reviewedAt!),
                      ),
                    if (item.reviewNotes != null &&
                        item.reviewNotes!.isNotEmpty)
                      _row(
                        context,
                        Icons.comment_outlined,
                        'Review Notes',
                        item.reviewNotes!,
                      ),
                    _row(
                      context,
                      Icons.calendar_today,
                      'Created',
                      _fmtDate(item.createdAt),
                    ),
                    _row(context, Icons.fingerprint, 'Plan ID', item.id),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// Rich visit item card
  Widget _visitCard(
    BuildContext context,
    PlanItemEntity visit,
    int index,
    int total,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = index == total - 1;
    final hasCustomer =
        visit.customerName != null && visit.customerName!.isNotEmpty;
    final hasDate = visit.plannedDate != null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index circle
          CircleAvatar(
            radius: 14,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer name or title
                Row(
                  children: [
                    Icon(
                      hasCustomer ? Icons.store_outlined : Icons.event_note,
                      size: 16,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        hasCustomer
                            ? visit.customerName!
                            : (visit.title ?? 'General Activity'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                // Customer ID label (small, for reference)
                if (hasCustomer && visit.customerId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${visit.customerId}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],

                // Planned date + time
                if (hasDate) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _fmtDate(visit.plannedDate!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (visit.plannedStartTime != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          visit.plannedEndTime != null
                              ? '${visit.plannedStartTime} – ${visit.plannedEndTime}'
                              : visit.plannedStartTime!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ],

                // Title (if customer is set, title is extra context)
                if (hasCustomer &&
                    visit.title != null &&
                    visit.title!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    visit.title!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                // Objective
                if (visit.objective != null && visit.objective!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.task_outlined,
                        size: 14,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          visit.objective!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],

                // Notes
                if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes, size: 14, color: scheme.tertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          visit.notes!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Status badge
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _visitStatusColor(
                      visit.status,
                      context,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    visit.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _visitStatusColor(visit.status, context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _visitStatusColor(String status, BuildContext context) {
    return switch (status) {
      'completed' => Colors.green,
      'cancelled' => Colors.red,
      'in_progress' => Colors.blue,
      _ => Colors.grey,
    };
  }

  Widget _actions(
    BuildContext context,
    WeeklyPlanEntity item,
    WeeklyPlanStatus st,
  ) {
    final actions = <Widget>[];
    if (st == WeeklyPlanStatus.submitted) {
      actions.add(
        _btn(
          context,
          Icons.check_circle_outline,
          'Approve',
          Colors.green,
          () => context.read<WeeklyPlanBloc>().add(
            WeeklyPlanApproveRequested(item.id),
          ),
        ),
      );
      actions.add(
        _btn(context, Icons.cancel_outlined, 'Reject', Colors.red, () async {
          final notesCtl = TextEditingController();
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Reject Plan'),
              content: TextField(
                controller: notesCtl,
                decoration: const InputDecoration(
                  labelText: 'Reason *',
                  hintText: 'Explain why this plan is rejected',
                ),
                maxLines: 3,
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Reject'),
                ),
              ],
            ),
          );
          if (confirmed == true && notesCtl.text.trim().isNotEmpty) {
            if (context.mounted) {
              context.read<WeeklyPlanBloc>().add(
                WeeklyPlanRejectRequested(item.id, notes: notesCtl.text.trim()),
              );
            }
          }
        }),
      );
    }
    if (st == WeeklyPlanStatus.rejected) {
      actions.add(
        _btn(
          context,
          Icons.replay,
          'Resubmit',
          Colors.blue,
          () => context.read<WeeklyPlanBloc>().add(
            WeeklyPlanResubmitRequested(item.id),
          ),
        ),
      );
    }
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

  Widget _row(BuildContext c, IconData icon, String label, String value) {
    final scheme = Theme.of(c).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
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
              style: Theme.of(
                c,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
