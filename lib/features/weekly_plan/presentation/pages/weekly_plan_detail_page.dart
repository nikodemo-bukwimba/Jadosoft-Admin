import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/weekly_plan_entity.dart';
import '../../domain/value_objects/weekly_plan_status.dart';
import '../bloc/weekly_plan_bloc.dart';
import '../bloc/weekly_plan_event.dart';
import '../bloc/weekly_plan_state.dart';
import '../../../officer/data/datasources/officer_mock_datasource.dart';
import '../../../customer/data/datasources/customer_mock_datasource.dart';

class WeeklyPlanDetailPage extends StatelessWidget {
  const WeeklyPlanDetailPage({super.key});

  Future<String> _officerName(String id) async {
    try {
      return (await OfficerMockDataSource().getById(id)).displayName;
    } catch (_) {
      return id;
    }
  }

  Future<String> _customerName(String id) async {
    try {
      return (await CustomerMockDataSource().getById(id)).name;
    } catch (_) {
      return id;
    }
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Detail')),
      body: BlocConsumer<WeeklyPlanBloc, WeeklyPlanState>(
        listener: (c, s) {
          if (s is WeeklyPlanOperationSuccess) {
            ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s.message)));
            if (s.updatedItem != null) {
              c.read<WeeklyPlanBloc>().add(WeeklyPlanLoadOneRequested(s.updatedItem!.id));
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
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: st.color.withValues(alpha: 0.15),
                      child: Icon(Icons.calendar_month, color: st.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_fmtDate(item.weekStart)} – ${_fmtDate(item.weekEnd)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<String>(
                            future: _officerName(item.officerId),
                            builder: (_, s) => Text(
                              s.data ?? '...',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: st.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: st.color.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              st.displayName,
                              style: TextStyle(color: st.color, fontSize: 12, fontWeight: FontWeight.w600),
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

            // Admin Actions
            _actions(context, item, st),

            // Planned Activities
            if (item.plannedActivities != null && item.plannedActivities!.isNotEmpty) ...[
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Target Customers
            if (item.plannedCustomerIds != null && item.plannedCustomerIds!.isNotEmpty) ...[
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
                          child: FutureBuilder<String>(
                            future: _customerName(cId),
                            builder: (_, s) => Row(
                              children: [
                                Icon(Icons.store, size: 18, color: scheme.onSurfaceVariant),
                                const SizedBox(width: 10),
                                Text(s.data ?? '...', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Details
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
                      _row(context, Icons.upload, 'Submitted', _fmtDate(item.submittedAt!)),
                    if (item.reviewedAt != null)
                      _row(context, Icons.rate_review, 'Reviewed', _fmtDate(item.reviewedAt!)),
                    _row(context, Icons.calendar_today, 'Created', _fmtDate(item.createdAt)),
                    _row(context, Icons.fingerprint, 'ID', item.id),
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

  Widget _actions(BuildContext context, WeeklyPlanEntity item, WeeklyPlanStatus st) {
    final actions = <Widget>[];
    if (st == WeeklyPlanStatus.submitted) {
      actions.add(
        _btn(
          context,
          Icons.check_circle_outline,
          'Approve',
          Colors.green,
          () => context.read<WeeklyPlanBloc>().add(WeeklyPlanApproveRequested(item.id)),
        ),
      );
      actions.add(
        _btn(
          context,
          Icons.cancel_outlined,
          'Reject',
          Colors.red,
          () async {
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
          },
        ),
      );
    }
    if (st == WeeklyPlanStatus.rejected) {
      actions.add(
        _btn(
          context,
          Icons.replay,
          'Resubmit',
          Colors.blue,
          () => context.read<WeeklyPlanBloc>().add(WeeklyPlanResubmitRequested(item.id)),
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

  Widget _btn(BuildContext c, IconData icon, String label, Color color, VoidCallback onPressed) =>
      FilledButton.tonalIcon(
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
              style: Theme.of(c).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(c).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}