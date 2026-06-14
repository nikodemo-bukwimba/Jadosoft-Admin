// lib/features/report_export/presentation/widgets/report_export_period_selector.dart

import 'package:flutter/material.dart';

class ReportExportPeriodSelector extends StatelessWidget {
  final String selected;
  final DateTimeRange? customRange;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickCustom;

  const ReportExportPeriodSelector({
    super.key,
    required this.selected,
    required this.customRange,
    required this.onChanged,
    required this.onPickCustom,
  });

  @override
  Widget build(BuildContext context) {
    final periods = [
      ('today', 'Today'),
      ('this_week', 'This Week'),
      ('this_month', 'This Month'),
      (
        'custom',
        customRange != null
            ? '${_d(customRange!.start)} – ${_d(customRange!.end)}'
            : 'Custom Range',
      ),
    ];

    return Wrap(
      spacing: 8,
      children: periods
          .map((p) => ChoiceChip(
                label: Text(p.$2),
                selected: selected == p.$1,
                onSelected: (_) {
                  if (p.$1 == 'custom') {
                    onPickCustom();
                  } else {
                    onChanged(p.$1);
                  }
                },
              ))
          .toList(),
    );
  }

  String _d(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}