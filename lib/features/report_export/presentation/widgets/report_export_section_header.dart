// lib/features/report_export/presentation/widgets/report_export_section_header.dart

import 'package:flutter/material.dart';

class ReportExportSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const ReportExportSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}