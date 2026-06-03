// lib/features/visit/presentation/pages/visit_detail_page.dart
//
// CHANGE vs previous version (single fix):
//   Converted to StatefulWidget so _lastItem can be cached.
//   The builder now keeps showing the last known detail while
//   VisitOperationSuccess / VisitLoading are in flight, instead of
//   falling through to SizedBox.shrink() (black screen).
//
// Everything else — _body, _actions, _AcceptSheet, _FlagSheet,
// _gpsRow, _row, _btn — is identical to the previous version.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/visit_entity.dart';
import '../../domain/value_objects/visit_status.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';
import '../../../../core/widgets/rich_text_field.dart';
import '../../../../core/utils/map_launcher.dart';

class VisitDetailPage extends StatefulWidget {
  final String visitId;
  const VisitDetailPage({super.key, required this.visitId});

  @override
  State<VisitDetailPage> createState() => _VisitDetailPageState();
}

class _VisitDetailPageState extends State<VisitDetailPage> {
  // Cache the last successfully loaded item so the builder can keep
  // showing it while VisitLoading / VisitOperationSuccess are in flight.
  VisitEntity? _lastItem;

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
            if (s.updatedItem != null) {
              c.read<VisitBloc>().add(VisitLoadOneRequested(s.updatedItem!.id));
            } else {
              c.pop();
            }
          }
          if (s is VisitFailure) {
            ScaffoldMessenger.of(c).showSnackBar(
              SnackBar(content: Text(s.message), backgroundColor: scheme.error),
            );
          }
        },
        builder: (c, s) {
          // ── Update cache whenever a fresh detail arrives ──────────
          if (s is VisitDetailLoaded) {
            _lastItem = s.item;
          }

          // ── Loading: show spinner only on first load (no cached item)
          if (s is VisitLoading || s is VisitInitial) {
            if (_lastItem != null) {
              // Keep showing the current detail while reloading —
              // no black screen between VisitOperationSuccess and
              // the next VisitDetailLoaded.
              return _body(context, _lastItem!);
            }
            return const Center(child: CircularProgressIndicator());
          }

          // ── Operation success: keep showing the detail while the
          //    listener's VisitLoadOneRequested is in flight.
          if (s is VisitOperationSuccess && _lastItem != null) {
            return _body(context, _lastItem!);
          }

          // ── Error ─────────────────────────────────────────────────
          if (s is VisitFailure) {
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

          // ── Detail loaded ─────────────────────────────────────────
          if (s is VisitDetailLoaded) {
            return _body(context, s.item);
          }

          // ── Fallback: if we have a cached item use it, else spinner
          if (_lastItem != null) return _body(context, _lastItem!);
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _body(BuildContext context, VisitEntity item) {
    final scheme = Theme.of(context).colorScheme;
    final st = VisitStatusX.fromString(item.status);
    final isWide = MediaQuery.of(context).size.width >= 600;
    final hasGps = item.gpsLat != null && item.gpsLng != null;
    final displayName =
        item.businessName ?? item.customerName ?? 'Unknown Business';
    final officerDisplay = item.officerName ?? item.officerId;

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
                            displayName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Visited by $officerDisplay',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (item.visitType != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.visitType!
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
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

            // ── Flag Reason ──────────────────────────────────────────
            if (item.flagReason != null && item.flagReason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.red.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.flag, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Flag Reason',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.flagReason!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Admin Comments ───────────────────────────────────────
            if (item.adminComments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Comments',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Divider(height: 20),
                      ...item.adminComments.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: 16,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c.authorName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: scheme.primary,
                                              ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year} ${c.createdAt.hour.toString().padLeft(2, '0')}:${c.createdAt.minute.toString().padLeft(2, '0')}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant
                                                    .withValues(alpha: 0.6),
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c.comment,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(height: 1.4),
                                    ),
                                  ],
                                ),
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

            // ── Outcome ──────────────────────────────────────────────
            if (item.outcome != null || item.outcomeStatus != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outcome',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Divider(height: 20),
                      if (item.outcome != null)
                        _row(
                          context,
                          Icons.check_circle_outline,
                          'Result',
                          item.outcome!,
                        ),
                      if (item.outcomeStatus != null)
                        _row(
                          context,
                          Icons.mood,
                          'Status',
                          item.outcomeStatus!.replaceAll('_', ' '),
                        ),
                      if (item.durationMinutes != null)
                        _row(
                          context,
                          Icons.timer_outlined,
                          'Duration',
                          '${item.durationMinutes} min',
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
                    _row(context, Icons.store, 'Customer', displayName),
                    _row(context, Icons.badge, 'Officer', officerDisplay),
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

    if (st == VisitStatus.pending) {
      actions.add(
        _btn(
          context,
          Icons.check_circle_outline,
          'Accept',
          Colors.green,
          () => _showAcceptDialog(context, item, existingComment: null),
        ),
      );
    }

    if (st == VisitStatus.reviewed) {
      actions.add(
        _btn(
          context,
          Icons.edit_outlined,
          'Edit Review',
          Colors.green,
          () => _showAcceptDialog(
            context,
            item,
            existingComment: item.adminComments.isNotEmpty
                ? item.adminComments.last.comment
                : null,
          ),
        ),
      );
    }

    if (st == VisitStatus.pending || st == VisitStatus.reviewed) {
      actions.add(
        _btn(
          context,
          Icons.flag_outlined,
          'Flag Visit',
          Colors.red,
          () => _showFlagDialog(context, item, existingReason: null),
        ),
      );
    }

    if (st == VisitStatus.flagged) {
      actions.add(
        _btn(
          context,
          Icons.edit_outlined,
          'Edit Flag',
          Colors.orange,
          () => _showFlagDialog(context, item, existingReason: item.flagReason),
        ),
      );
      actions.add(
        _btn(
          context,
          Icons.flag,
          'Remove Flag',
          Colors.green,
          () => context.read<VisitBloc>().add(VisitUnflagRequested(item.id)),
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

  void _showAcceptDialog(
    BuildContext context,
    VisitEntity item, {
    required String? existingComment,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AcceptSheet(
        existingComment: existingComment,
        isEdit: existingComment != null,
        onSubmit: (comment) {
          context.read<VisitBloc>().add(
            VisitReviewRequested(
              item.id,
              comment: comment.isNotEmpty ? comment : null,
            ),
          );
        },
      ),
    );
  }

  void _showFlagDialog(
    BuildContext context,
    VisitEntity item, {
    required String? existingReason,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FlagSheet(
        existingReason: existingReason,
        isEdit: existingReason != null,
        onSubmit: (reason) {
          context.read<VisitBloc>().add(
            VisitFlagRequested(item.id, comment: reason),
          );
        },
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

// ── Accept sheet ──────────────────────────────────────────────────────────────

class _AcceptSheet extends StatefulWidget {
  final String? existingComment;
  final bool isEdit;
  final void Function(String comment) onSubmit;

  const _AcceptSheet({
    required this.onSubmit,
    this.existingComment,
    this.isEdit = false,
  });

  @override
  State<_AcceptSheet> createState() => _AcceptSheetState();
}

class _AcceptSheetState extends State<_AcceptSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.existingComment ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.isEdit ? 'Edit Review' : 'Accept Visit',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isEdit
                  ? 'Update your comment. The visit will remain accepted.'
                  : 'Confirm you have reviewed this visit\'s GPS, photos, and discussion.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            RichTextField(
              controller: _ctrl,
              label: 'Comment (optional)',
              hint: 'Feedback for the officer...',
              minLines: 3,
              maxLines: 8,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onSubmit(_ctrl.text.trim());
                    },
                    icon: Icon(
                      widget.isEdit
                          ? Icons.save_outlined
                          : Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: Text(widget.isEdit ? 'Save' : 'Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Flag sheet ────────────────────────────────────────────────────────────────

class _FlagSheet extends StatefulWidget {
  final String? existingReason;
  final bool isEdit;
  final void Function(String reason) onSubmit;

  const _FlagSheet({
    required this.onSubmit,
    this.existingReason,
    this.isEdit = false,
  });

  @override
  State<_FlagSheet> createState() => _FlagSheetState();
}

class _FlagSheetState extends State<_FlagSheet> {
  late final TextEditingController _ctrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.existingReason ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    widget.isEdit ? Icons.edit_outlined : Icons.flag,
                    color: scheme.error,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isEdit ? 'Edit Flag Reason' : 'Flag Visit',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.isEdit
                    ? 'Update the reason for flagging this visit.'
                    : 'Provide a clear reason. This will be visible to the officer.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FormField<String>(
                validator: (_) => _ctrl.text.trim().isEmpty
                    ? 'A reason is required when flagging'
                    : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichTextField(
                      controller: _ctrl,
                      label: 'Reason for flagging *',
                      hint:
                          'e.g. GPS mismatch, missing photos, incorrect report...',
                      minLines: 3,
                      maxLines: 8,
                      highlight: true,
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 12),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(color: scheme.error, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                      ),
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        Navigator.pop(context);
                        widget.onSubmit(_ctrl.text.trim());
                      },
                      icon: Icon(
                        widget.isEdit ? Icons.save_outlined : Icons.flag,
                        size: 18,
                      ),
                      label: Text(widget.isEdit ? 'Save' : 'Flag Visit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
