// lib/features/report_export/presentation/widgets/report_export_weekly_plans_card.dart
//
// StatefulWidget — lets user pick:
//   • "All officers" (default)
//   • One or several officers by ULID, entered as comma-separated IDs
//     OR selected from a chip list if officer names are pre-loaded.
//
// The card exposes two callbacks:
//   onExportAll(format)
//   onExportFiltered(format, officerIds)
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/report_export_cubit.dart';

/// A single selectable officer chip item.
class OfficerChipItem {
  final String officerId;
  final String displayName;
  bool selected;

  OfficerChipItem({
    required this.officerId,
    required this.displayName,
    this.selected = false,
  });
}

class ReportExportWeeklyPlansCard extends StatefulWidget {
  final bool isLoading;

  /// Pre-loaded officer list for chip selection.
  /// When null or empty, falls back to manual ID entry.
  final List<OfficerChipItem>? officers;

  const ReportExportWeeklyPlansCard({
    super.key,
    required this.isLoading,
    this.officers,
  });

  @override
  State<ReportExportWeeklyPlansCard> createState() =>
      _ReportExportWeeklyPlansCardState();
}

class _ReportExportWeeklyPlansCardState
    extends State<ReportExportWeeklyPlansCard> {
  // false = all officers; true = specific officers
  bool _filterByOfficer = false;

  // Chip selection state (copy so mutations don't alter the input list)
  late List<OfficerChipItem> _chips;

  // Manual ID entry fallback
  final _idCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chips = (widget.officers ?? [])
        .map((o) => OfficerChipItem(
              officerId: o.officerId,
              displayName: o.displayName,
            ))
        .toList();
    _idCtrl.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(ReportExportWeeklyPlansCard old) {
    super.didUpdateWidget(old);
    // Refresh chips if officer list changes
    if (widget.officers != old.officers) {
      final prev = {for (final c in _chips) c.officerId: c.selected};
      _chips = (widget.officers ?? [])
          .map((o) => OfficerChipItem(
                officerId: o.officerId,
                displayName: o.displayName,
                selected: prev[o.officerId] ?? false,
              ))
          .toList();
    }
  }

  @override
  void dispose() {
    _idCtrl.removeListener(_rebuild);
    _idCtrl.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  // ── Derived state ──────────────────────────────────────────────────────────

  bool get _hasChips => _chips.isNotEmpty;
  Set<String> get _selectedIds =>
      _chips.where((c) => c.selected).map((c) => c.officerId).toSet();

  // Parse comma/newline-separated ULIDs from the manual text field
  Set<String> get _manualIds => _idCtrl.text
      .split(RegExp(r'[,\n]'))
      .map((s) => s.trim().toUpperCase())
      .where((s) => s.length == 26)
      .toSet();

  Set<String> get _effectiveOfficerIds =>
      _hasChips ? _selectedIds : _manualIds;

  bool get _canExportFiltered =>
      !_filterByOfficer || _effectiveOfficerIds.isNotEmpty;

  // ── Export triggers ────────────────────────────────────────────────────────

  void _export(BuildContext ctx, String format) {
    final cubit = ctx.read<ReportExportCubit>();
    if (!_filterByOfficer) {
      cubit.exportWeeklyPlans(format: format);
    } else {
      cubit.exportWeeklyPlansByOfficers(
        format: format,
        officerIds: _effectiveOfficerIds,
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedCount =
        _filterByOfficer ? _effectiveOfficerIds.length : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_month_outlined,
                    color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Plans',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      selectedCount != null
                          ? '$selectedCount officer${selectedCount != 1 ? "s" : ""} selected'
                          : 'All officers — plans, items, review notes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 12),

            // ── Filter toggle ──────────────────────────────────────
            _FilterToggle(
              value: _filterByOfficer,
              onChanged: (v) => setState(() => _filterByOfficer = v),
            ),

            // ── Officer selector (only when filter is on) ──────────
            if (_filterByOfficer) ...[
              const SizedBox(height: 10),
              _hasChips
                  ? _ChipSelector(
                      chips: _chips,
                      onToggle: (id) => setState(() {
                        final chip =
                            _chips.firstWhere((c) => c.officerId == id);
                        chip.selected = !chip.selected;
                      }),
                    )
                  : _ManualIdField(ctrl: _idCtrl),
            ],

            const SizedBox(height: 14),

            // ── Export buttons ─────────────────────────────────────
            if (widget.isLoading)
              const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _canExportFiltered
                        ? () => _export(context, 'pdf')
                        : null,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text('PDF'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _canExportFiltered
                        ? () => _export(context, 'excel')
                        : null,
                    icon: const Icon(Icons.table_chart_outlined, size: 16),
                    label: const Text('Excel'),
                  ),
                ),
              ]),

            // ── Hint when filter active but no selection ───────────
            if (_filterByOfficer && !_canExportFiltered) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.info_outline,
                    size: 13, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _hasChips
                        ? 'Tap at least one officer chip to enable export.'
                        : 'Enter at least one valid 26-character Officer ID.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Filter toggle ──────────────────────────────────────────────────────────

class _FilterToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _FilterToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value
              ? scheme.primaryContainer.withValues(alpha: 0.5)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value
                ? scheme.primary.withValues(alpha: 0.5)
                : scheme.outlineVariant,
          ),
        ),
        child: Row(children: [
          Icon(Icons.person_search_outlined,
              size: 16,
              color: value ? scheme.primary : scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value
                  ? 'Filtering by specific officer(s)'
                  : 'Export all officers',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: value ? scheme.primary : scheme.onSurfaceVariant,
                  ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ]),
      ),
    );
  }
}

// ── Chip selector (when officer list is pre-loaded) ────────────────────────

class _ChipSelector extends StatelessWidget {
  final List<OfficerChipItem> chips;
  final void Function(String officerId) onToggle;
  const _ChipSelector({required this.chips, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select officers:',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: chips.map((c) => FilterChip(
            label: Text(c.displayName),
            selected: c.selected,
            onSelected: (_) => onToggle(c.officerId),
            visualDensity: VisualDensity.compact,
          )).toList(),
        ),
      ],
    );
  }
}

// ── Manual ID entry (fallback when no officer list provided) ───────────────

class _ManualIdField extends StatelessWidget {
  final TextEditingController ctrl;
  const _ManualIdField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: 3,
      textCapitalization: TextCapitalization.characters,
      decoration: const InputDecoration(
        labelText: 'Officer ID(s)',
        hintText:
            '01KRDX1BAY6RKRWRRFHV7BBHVV\n01KRDB2TZ55WW8BZN5698G06TQ',
        helperText: 'One 26-character Officer ID per line, or comma-separated',
        prefixIcon: Icon(Icons.person_outline),
        isDense: true,
        border: OutlineInputBorder(),
      ),
    );
  }
}