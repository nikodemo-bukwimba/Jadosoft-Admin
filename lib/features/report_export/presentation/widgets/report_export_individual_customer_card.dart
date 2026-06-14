// lib/features/report_export/presentation/widgets/report_export_individual_customer_card.dart
//
// StatefulWidget — listens to ctrl changes so PDF/Excel buttons
// enable reactively as the user types (fixes the always-disabled bug).
// Also exposes the visit-history toggle.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/report_export_cubit.dart';
import 'report_export_visit_history_toggle.dart';

class ReportExportIndividualCustomerCard extends StatefulWidget {
  final TextEditingController ctrl;
  final bool isLoading;
  final bool includeVisits;
  final ValueChanged<bool> onIncludeVisitsChanged;

  const ReportExportIndividualCustomerCard({
    super.key,
    required this.ctrl,
    required this.isLoading,
    required this.includeVisits,
    required this.onIncludeVisitsChanged,
  });

  @override
  State<ReportExportIndividualCustomerCard> createState() =>
      _ReportExportIndividualCustomerCardState();
}

class _ReportExportIndividualCustomerCardState
    extends State<ReportExportIndividualCustomerCard> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  // Customer IDs are ULIDs — exactly 26 uppercase alphanumeric characters.
  // e.g. 01KRB6PPBY78P1NH0GA4Q3WVP4
  bool get _isValidId {
    final v = widget.ctrl.text.trim();
    return v.length == 26 && RegExp(r'^[0-9A-Z]+$').hasMatch(v);
  }

  String? get _idError {
    final v = widget.ctrl.text.trim();
    if (v.isEmpty) return null; // no error shown when blank
    if (v.length < 26) return 'ID too short (${v.length}/26 characters)';
    if (v.length > 26) return 'ID too long (${v.length}/26 characters)';
    if (!RegExp(r'^[0-9A-Z]+$').hasMatch(v))
      return 'ID contains invalid characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasId = _isValidId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.indigo,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Individual Customer Profile',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Full profile + optional visit history for one customer',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Customer ID field ────────────────────────────────────
            TextField(
              controller: widget.ctrl,
              maxLength: 26,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Customer ID',
                hintText: 'e.g. 01KRB6PPBY78P1NH0GA4Q3WVP4',
                helperText: '26-character ULID — copy from the customer list',
                errorText: _idError,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
                counterText: '', // hide the maxLength counter
              ),
            ),
            const SizedBox(height: 10),

            // ── Visit history toggle ─────────────────────────────────
            ReportExportVisitHistoryToggle(
              value: widget.includeVisits,
              onChanged: widget.onIncludeVisitsChanged,
            ),
            const SizedBox(height: 10),

            // ── Export buttons ───────────────────────────────────────
            if (widget.isLoading)
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: hasId
                          ? () => context
                                .read<ReportExportCubit>()
                                .exportCustomerIndividual(
                                  customerId: widget.ctrl.text.trim(),
                                  format: 'pdf',
                                  includeVisits: widget.includeVisits,
                                )
                          : null,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('PDF'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: hasId
                          ? () => context
                                .read<ReportExportCubit>()
                                .exportCustomerIndividual(
                                  customerId: widget.ctrl.text.trim(),
                                  format: 'excel',
                                  includeVisits: widget.includeVisits,
                                )
                          : null,
                      icon: const Icon(Icons.table_chart_outlined, size: 16),
                      label: const Text('Excel'),
                    ),
                  ),
                ],
              ),

            // ── Hint when no ID entered ──────────────────────────────
            if (!hasId) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Enter a Customer ID to enable export.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
