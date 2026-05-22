// lib/features/report_export/presentation/widgets/report_export_visit_history_toggle.dart

import 'package:flutter/material.dart';

/// Toggle chip that controls whether visit history is included in a
/// customer export. Tapping anywhere on the row or the switch itself
/// flips the value.
class ReportExportVisitHistoryToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ReportExportVisitHistoryToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

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
              ? scheme.primaryContainer.withValues(alpha: 0.6)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value
                ? scheme.primary.withValues(alpha: 0.5)
                : scheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.history_outlined,
              size: 16,
              color: value ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Include Visit History',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: value
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    value
                        ? 'Each customer will include their full visit log'
                        : 'Tap to append visit history to the export',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}