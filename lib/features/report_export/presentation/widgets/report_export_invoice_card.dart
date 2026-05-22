// lib/features/report_export/presentation/widgets/report_export_invoice_card.dart
//
// StatefulWidget — listens to ctrl changes so the generate button
// enables reactively as the user types.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/report_export_cubit.dart';

class ReportExportInvoiceCard extends StatefulWidget {
  final TextEditingController ctrl;
  final bool isLoading;
  final String? error;

  const ReportExportInvoiceCard({
    super.key,
    required this.ctrl,
    required this.isLoading,
    this.error,
  });

  @override
  State<ReportExportInvoiceCard> createState() =>
      _ReportExportInvoiceCardState();
}

class _ReportExportInvoiceCardState extends State<ReportExportInvoiceCard> {
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasId  = widget.ctrl.text.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate Invoice',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'PDF invoice per order — includes items, total, payment status',
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
            TextField(
              controller: widget.ctrl,
              decoration: InputDecoration(
                labelText: 'Order ID',
                hintText: 'e.g. ord-001',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
                errorText: widget.error,
              ),
            ),
            const SizedBox(height: 10),
            if (widget.isLoading)
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: hasId
                      ? () => context.read<ReportExportCubit>().exportInvoice(
                            orderId: widget.ctrl.text.trim(),
                          )
                      : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('Generate Invoice PDF'),
                  style:
                      FilledButton.styleFrom(backgroundColor: Colors.purple),
                ),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Invoice is auto-created when an order is confirmed. '
                      'Enter order ID to download the PDF.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}