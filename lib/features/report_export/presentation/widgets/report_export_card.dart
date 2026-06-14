// lib/features/report_export/presentation/widgets/report_export_card.dart
//
// Generic export card: icon, title, description, optional extra widget,
// loading spinner, PDF + optional Excel buttons.
// Replaces the old _ExportCard private class in the page.

import 'package:flutter/material.dart';

class ReportExportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool supportsExcel;
  final void Function(String format) onExport;

  /// Optional widget rendered between the description and the export
  /// buttons — used for the visit-history toggle on customer cards.
  final Widget? extra;

  const ReportExportCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.supportsExcel,
    required this.onExport,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon + title / description ──────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Optional extra widget (e.g. visit toggle) ────────────
            if (extra != null) ...[
              const SizedBox(height: 10),
              extra!,
            ],

            const SizedBox(height: 14),

            // ── Buttons ──────────────────────────────────────────────
            if (isLoading)
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
                      onPressed: () => onExport('pdf'),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('PDF'),
                    ),
                  ),
                  if (supportsExcel) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => onExport('excel'),
                        icon:
                            const Icon(Icons.table_chart_outlined, size: 16),
                        label: const Text('Excel'),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}