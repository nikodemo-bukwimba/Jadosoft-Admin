//Admin app
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/daily_report_entity.dart';
import '../../domain/value_objects/daily_report_status.dart';
import '../bloc/daily_report_bloc.dart';
import '../bloc/daily_report_event.dart';
import '../bloc/daily_report_state.dart';
import '../widgets/daily_report_status_badge.dart';

class DailyReportDetailPage extends StatelessWidget {
  const DailyReportDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DailyReportBloc, DailyReportState>(
      listener: (context, state) {
        if (state is DailyReportOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          // Pop immediately — list page will reload itself in initState
          context.pop();
        }
        if (state is DailyReportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is DailyReportLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Daily Report')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is DailyReportDetailLoaded) {
          return _DetailView(item: state.item);
        }
        if (state is DailyReportFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Daily Report')),
            body: Center(child: Text(state.message)),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Daily Report')),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

// ─── Detail View ───────────────────────────────────────────────────────────

class _DetailView extends StatelessWidget {
  final DailyReportEntity item;
  const _DetailView({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = DailyReportStatusX.fromString(item.status);
    final isWide = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.reportNumber ?? 'Daily Report'),
        centerTitle: false,
        actions: [
          DailyReportStatusBadge(status: status),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 48 : 16,
          vertical: 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionCard(
                  title: 'Officer Details',
                  icon: Icons.person_outline,
                  child: Wrap(
                    spacing: 32,
                    runSpacing: 12,
                    children: [
                      _InfoBlock(label: 'Name', value: item.officerName),
                      _InfoBlock(label: 'Email', value: item.officerEmail),
                      _InfoBlock(label: 'Phone', value: item.officerPhone),
                      _InfoBlock(label: 'Role', value: item.officerRole),
                      _InfoBlock(label: 'Status', value: item.officerStatus),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Report Metadata',
                  icon: Icons.info_outline,
                  child: Wrap(
                    spacing: 32,
                    runSpacing: 12,
                    children: [
                      _InfoBlock(
                        label: 'Report Number',
                        value: item.reportNumber,
                      ),
                      _InfoBlock(
                        label: 'Report Date',
                        value: _formatDate(item.reportDate),
                      ),
                      _InfoBlock(
                        label: 'Submitted At',
                        value: item.submittedAt != null
                            ? _formatDateTime(item.submittedAt!)
                            : '—',
                      ),
                      _InfoBlock(
                        label: 'Customized',
                        value: item.isCustomized ? 'Yes' : 'No',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title:
                      'Visited Customers (${item.visitedCustomers?.length ?? 0})',
                  icon: Icons.store_outlined,
                  child:
                      item.visitedCustomers == null ||
                          item.visitedCustomers!.isEmpty
                      ? Text(
                          'No visits recorded for this report.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Column(
                          children: item.visitedCustomers!
                              .asMap()
                              .entries
                              .map(
                                (entry) => _CustomerVisitCard(
                                  index: entry.key + 1,
                                  data: entry.value,
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Report Body',
                  icon: Icons.article_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReportBodyField(
                        label: 'Key Outcomes',
                        value: item.keyOutcomes,
                      ),
                      const SizedBox(height: 12),
                      _ReportBodyField(
                        label: 'Challenges Faced',
                        value: item.challengesFaced,
                      ),
                      const SizedBox(height: 12),
                      _ReportBodyField(
                        label: 'Next Day Plan',
                        value: item.nextDayPlan,
                      ),
                      if (item.isCustomized && item.customBody != null) ...[
                        const SizedBox(height: 12),
                        _ReportBodyField(
                          label: 'Additional Notes (Officer Customized)',
                          value: item.customBody,
                          highlight: true,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (item.adminFeedback != null) ...[
                  _SectionCard(
                    title: 'Admin Review',
                    icon: Icons.rate_review_outlined,
                    accentColor: status == DailyReportStatus.approved
                        ? Colors.green
                        : Colors.red,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 32,
                          runSpacing: 12,
                          children: [
                            _InfoBlock(
                              label: 'Reviewed By',
                              value: item.reviewedByName,
                            ),
                            _InfoBlock(
                              label: 'Role',
                              value: item.reviewedByRole,
                            ),
                            _InfoBlock(
                              label: 'Decision',
                              value: (item.reviewDecision ?? '').toUpperCase(),
                            ),
                            _InfoBlock(
                              label: 'Reviewed At',
                              value: item.reviewedAt != null
                                  ? _formatDateTime(item.reviewedAt!)
                                  : '—',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: status == DailyReportStatus.approved
                                ? Colors.green.withOpacity(0.08)
                                : Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: status == DailyReportStatus.approved
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Feedback',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.adminFeedback!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (status == DailyReportStatus.submitted)
                  _ActionButtons(item: item),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatDateTime(DateTime d) {
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${_formatDate(d)} $hour:$min';
  }
}

// ─── Action Buttons ────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final DailyReportEntity item;
  const _ActionButtons({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Actions',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        _openFeedbackDialog(context, approve: true),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Approve Report'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        _openFeedbackDialog(context, approve: false),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Reject Report'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openFeedbackDialog(BuildContext context, {required bool approve}) {
    final bloc = context.read<DailyReportBloc>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FeedbackDialog(
        approve: approve,
        onConfirmed: (feedback) {
          if (approve) {
            bloc.add(DailyReportApproveRequested(item.id, feedback: feedback));
          } else {
            bloc.add(DailyReportRejectRequested(item.id, feedback: feedback));
          }
        },
      ),
    );
  }
}

// ─── Feedback Dialog ───────────────────────────────────────────────────────

class _FeedbackDialog extends StatefulWidget {
  final bool approve;
  final void Function(String feedback) onConfirmed;
  const _FeedbackDialog({required this.approve, required this.onConfirmed});

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.approve ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: widget.approve ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(widget.approve ? 'Approve Report' : 'Reject Report'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.approve
                    ? 'Approving this report will notify the officer. Please provide feedback.'
                    : 'Rejecting this report will notify the officer. Please provide a reason.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Feedback *',
                  hintText: widget.approve
                      ? 'e.g. Excellent work! The supply agreement follow-up is noted.'
                      : 'e.g. Please provide more detail on customer discussions.',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Feedback is required';
                  }
                  if (v.trim().length < 10) {
                    return 'Please provide more detailed feedback';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: widget.approve ? Colors.green : Colors.red,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final feedback = _controller.text.trim();
              Navigator.pop(context);
              widget.onConfirmed(feedback);
            }
          },
          child: Text(widget.approve ? 'Approve' : 'Reject'),
        ),
      ],
    );
  }
}

// ─── Customer Visit Card ───────────────────────────────────────────────────

class _CustomerVisitCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;
  const _CustomerVisitCard({required this.index, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = (data['promotedProducts'] as List?)?.cast<String>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data['customerBusinessName'] ?? '—',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (data['visitTime'] != null)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 13,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data['visitTime'],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 32,
                  runSpacing: 12,
                  children: [
                    _InfoBlock(
                      label: 'Owner',
                      value: data['customerOwnerName'],
                    ),
                    _InfoBlock(label: 'Phone', value: data['customerPhone']),
                    _InfoBlock(
                      label: 'Contact Person',
                      value: data['customerContactPerson'],
                    ),
                    _InfoBlock(
                      label: 'Contact Phone',
                      value: data['customerContactPhone'],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _InfoBlock(label: 'Address', value: data['customerAddress']),
                if (data['customerGpsLat'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${data['customerGpsLat']}, ${data['customerGpsLng']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (products.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Promoted Products',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: products
                        .map(
                          (p) => Chip(
                            label: Text(
                              p,
                              style: const TextStyle(fontSize: 11),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (data['discussionSummary'] != null) ...[
                  const SizedBox(height: 10),
                  _ReportBodyField(
                    label: 'Discussion Summary',
                    value: data['discussionSummary'],
                  ),
                ],
                if (data['visitNotes'] != null) ...[
                  const SizedBox(height: 8),
                  _ReportBodyField(label: 'Notes', value: data['visitNotes']),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? accentColor;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String? value;
  const _InfoBlock({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(value ?? '—', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ReportBodyField extends StatelessWidget {
  final String label;
  final String? value;
  final bool highlight;

  const _ReportBodyField({
    required this.label,
    this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: highlight
                ? theme.colorScheme.tertiary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlight
                ? theme.colorScheme.tertiaryContainer.withOpacity(0.3)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value ?? '—',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: value == null ? theme.colorScheme.onSurfaceVariant : null,
              fontStyle: value == null ? FontStyle.italic : null,
            ),
          ),
        ),
      ],
    );
  }
}
