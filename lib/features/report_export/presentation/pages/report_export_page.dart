// report_export_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/report_export_cubit.dart';
import '../cubit/report_export_state.dart';

class ReportExportPage extends StatefulWidget {
  const ReportExportPage({super.key});

  @override
  State<ReportExportPage> createState() => _ReportExportPageState();
}

class _ReportExportPageState extends State<ReportExportPage> {
  // Date range
  String _period = 'this_month';
  DateTimeRange? _customRange;

  // Invoice order ID controller
  final _invoiceCtrl = TextEditingController();

  // Customer individual ID controller
  final _customerCtrl = TextEditingController();

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _customerCtrl.dispose();
    super.dispose();
  }

  // ── Date helpers ────────────────────────────────────────────────────────

  (String, String) _resolvedDateRange() {
    final now = DateTime.now();
    switch (_period) {
      case 'today':
        final d = _fmt(now);
        return (d, d);
      case 'this_week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (_fmt(start), _fmt(now));
      case 'this_month':
        return (_fmt(DateTime(now.year, now.month, 1)), _fmt(now));
      case 'custom':
        if (_customRange != null) {
          return (_fmt(_customRange!.start), _fmt(_customRange!.end));
        }
        return (_fmt(DateTime(now.year, now.month, 1)), _fmt(now));
      default:
        return (_fmt(DateTime(now.year, now.month, 1)), _fmt(now));
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange:
          _customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = 'custom';
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 840;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Export'), centerTitle: false),
      body: BlocConsumer<ReportExportCubit, ReportExportState>(
        listener: (ctx, state) {
          // New export queued
          if (state.activeExportId != null &&
              state.exportHistory.isNotEmpty &&
              state.exportHistory.first.status == 'pending') {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(
                  'Export queued — ${_labelType(state.exportHistory.first.reportType)} will be ready shortly',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          // Download completed — show snackbar (especially useful for mock:// URLs
          // which can't be launched, so user knows it would download in production)
          if (state.lastDownloadedFileName != null) {
            final isMock =
                state.downloadExportResult?.fileUrl.startsWith('mock') ?? false;
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(
                  isMock
                      ? 'Mock mode — in production "${state.lastDownloadedFileName}" would download automatically'
                      : 'Downloading ${state.lastDownloadedFileName}…',
                ),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: isMock ? 4 : 2),
              ),
            );
          }
          // Download error
          if (state.downloadExportError != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text('Download failed: ${state.downloadExportError}'),
                backgroundColor: Theme.of(ctx).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (ctx, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? (width - 960) / 2 : 16,
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Period filter ──────────────────────────────────────
                  _PeriodSelector(
                    selected: _period,
                    customRange: _customRange,
                    onChanged: (v) => setState(() => _period = v),
                    onPickCustom: _pickCustomRange,
                  ),
                  const SizedBox(height: 20),

                  // ── Polling banner ─────────────────────────────────────
                  if (state.activeExportId != null) ...[
                    _PollingBanner(status: state.pollingStatus),
                    const SizedBox(height: 16),
                  ],

                  // ── Main grid ─────────────────────────────────────────
                  if (isWide)
                    _WideLayout(
                      state: state,
                      period: _period,
                      resolvedRange: _resolvedDateRange,
                      invoiceCtrl: _invoiceCtrl,
                      customerCtrl: _customerCtrl,
                    )
                  else
                    _NarrowLayout(
                      state: state,
                      period: _period,
                      resolvedRange: _resolvedDateRange,
                      invoiceCtrl: _invoiceCtrl,
                      customerCtrl: _customerCtrl,
                    ),

                  const SizedBox(height: 24),

                  // ── Export history ─────────────────────────────────────
                  if (state.exportHistory.isNotEmpty) ...[
                    Text(
                      'Export History',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _ExportHistoryList(entries: state.exportHistory),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Period selector ─────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final String selected;
  final DateTimeRange? customRange;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickCustom;

  const _PeriodSelector({
    required this.selected,
    required this.customRange,
    required this.onChanged,
    required this.onPickCustom,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
      children: [
        ...periods.map(
          (p) => ChoiceChip(
            label: Text(p.$2),
            selected: selected == p.$1,
            onSelected: (_) {
              if (p.$1 == 'custom') {
                onPickCustom();
              } else {
                onChanged(p.$1);
              }
            },
          ),
        ),
      ],
    );
  }

  String _d(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

// ── Wide layout (2 columns) ─────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final ReportExportState state;
  final String period;
  final (String, String) Function() resolvedRange;
  final TextEditingController invoiceCtrl;
  final TextEditingController customerCtrl;

  const _WideLayout({
    required this.state,
    required this.period,
    required this.resolvedRange,
    required this.invoiceCtrl,
    required this.customerCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _SectionHeader(
                title: 'Marketing Reports',
                icon: Icons.campaign_outlined,
              ),
              const SizedBox(height: 8),
              _ExportCard(
                title: 'Marketing Summary',
                description:
                    'Visits, officer performance, plan compliance, daily reports',
                icon: Icons.bar_chart,
                color: Colors.teal,
                isLoading: state.isMarketingSummaryLoading,
                supportsExcel: true,
                onExport: (fmt) {
                  final r = resolvedRange();
                  context.read<ReportExportCubit>().exportMarketingSummary(
                    format: fmt,
                    dateFrom: r.$1,
                    dateTo: r.$2,
                  );
                },
              ),
              const SizedBox(height: 8),
              _SectionHeader(
                title: 'Customer Reports',
                icon: Icons.people_outline,
              ),
              const SizedBox(height: 8),
              _ExportCard(
                title: 'Customer List',
                description:
                    'All customer profiles — business, owner, contact, address, GPS, assigned officer',
                icon: Icons.list_alt,
                color: Colors.indigo,
                isLoading: state.isCustomerListLoading,
                supportsExcel: true,
                onExport: (fmt) => context
                    .read<ReportExportCubit>()
                    .exportCustomerList(format: fmt),
              ),
              const SizedBox(height: 8),
              _IndividualCustomerCard(
                ctrl: customerCtrl,
                isLoading: state.isCustomerIndividualLoading,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _SectionHeader(
                title: 'Sales Reports',
                icon: Icons.point_of_sale_outlined,
              ),
              const SizedBox(height: 8),
              _ExportCard(
                title: 'Sales Summary',
                description:
                    'Orders by status, revenue, average order value, payments',
                icon: Icons.attach_money,
                color: Colors.green,
                isLoading: state.isSalesSummaryLoading,
                supportsExcel: true,
                onExport: (fmt) {
                  final r = resolvedRange();
                  context.read<ReportExportCubit>().exportSalesSummary(
                    format: fmt,
                    dateFrom: r.$1,
                    dateTo: r.$2,
                  );
                },
              ),
              const SizedBox(height: 8),
              _ExportCard(
                title: 'Product List',
                description:
                    'All products with name, category, price, availability and status',
                icon: Icons.medication_outlined,
                color: Colors.orange,
                isLoading: state.isProductListLoading,
                supportsExcel: true,
                onExport: (fmt) => context
                    .read<ReportExportCubit>()
                    .exportProductList(format: fmt),
              ),
              const SizedBox(height: 8),
              _SectionHeader(
                title: 'Invoice',
                icon: Icons.receipt_long_outlined,
              ),
              const SizedBox(height: 8),
              _InvoiceCard(
                ctrl: invoiceCtrl,
                isLoading: state.isInvoiceLoading,
                error: state.invoiceError,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Narrow layout (single column) ──────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final ReportExportState state;
  final String period;
  final (String, String) Function() resolvedRange;
  final TextEditingController invoiceCtrl;
  final TextEditingController customerCtrl;

  const _NarrowLayout({
    required this.state,
    required this.period,
    required this.resolvedRange,
    required this.invoiceCtrl,
    required this.customerCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Marketing Reports',
          icon: Icons.campaign_outlined,
        ),
        const SizedBox(height: 8),
        _ExportCard(
          title: 'Marketing Summary',
          description:
              'Visits, officer performance, plan compliance, daily reports',
          icon: Icons.bar_chart,
          color: Colors.teal,
          isLoading: state.isMarketingSummaryLoading,
          supportsExcel: true,
          onExport: (fmt) {
            final r = resolvedRange();
            context.read<ReportExportCubit>().exportMarketingSummary(
              format: fmt,
              dateFrom: r.$1,
              dateTo: r.$2,
            );
          },
        ),
        const SizedBox(height: 16),
        _SectionHeader(
          title: 'Sales Reports',
          icon: Icons.point_of_sale_outlined,
        ),
        const SizedBox(height: 8),
        _ExportCard(
          title: 'Sales Summary',
          description:
              'Orders by status, revenue, average order value, payments',
          icon: Icons.attach_money,
          color: Colors.green,
          isLoading: state.isSalesSummaryLoading,
          supportsExcel: true,
          onExport: (fmt) {
            final r = resolvedRange();
            context.read<ReportExportCubit>().exportSalesSummary(
              format: fmt,
              dateFrom: r.$1,
              dateTo: r.$2,
            );
          },
        ),
        const SizedBox(height: 8),
        _ExportCard(
          title: 'Product List',
          description:
              'All products with name, category, price, availability and status',
          icon: Icons.medication_outlined,
          color: Colors.orange,
          isLoading: state.isProductListLoading,
          supportsExcel: true,
          onExport: (fmt) =>
              context.read<ReportExportCubit>().exportProductList(format: fmt),
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Customer Reports', icon: Icons.people_outline),
        const SizedBox(height: 8),
        _ExportCard(
          title: 'Customer List',
          description:
              'All customer profiles — business, owner, contact, address, GPS, assigned officer',
          icon: Icons.list_alt,
          color: Colors.indigo,
          isLoading: state.isCustomerListLoading,
          supportsExcel: true,
          onExport: (fmt) =>
              context.read<ReportExportCubit>().exportCustomerList(format: fmt),
        ),
        const SizedBox(height: 8),
        _IndividualCustomerCard(
          ctrl: customerCtrl,
          isLoading: state.isCustomerIndividualLoading,
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Invoice', icon: Icons.receipt_long_outlined),
        const SizedBox(height: 8),
        _InvoiceCard(
          ctrl: invoiceCtrl,
          isLoading: state.isInvoiceLoading,
          error: state.invoiceError,
        ),
      ],
    );
  }
}

// ── Section header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

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

// ── Export card ─────────────────────────────────────────────────────────────

class _ExportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool supportsExcel;
  final void Function(String format) onExport;

  const _ExportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.supportsExcel,
    required this.onExport,
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
            const SizedBox(height: 14),
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
                        icon: const Icon(Icons.table_chart_outlined, size: 16),
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

// ── Individual customer card ────────────────────────────────────────────────

class _IndividualCustomerCard extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isLoading;
  const _IndividualCustomerCard({required this.ctrl, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                        'Full profile + visit history for one customer',
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
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Customer ID',
                hintText: 'e.g. cust-001',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
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
                      onPressed: ctrl.text.trim().isEmpty
                          ? null
                          : () => context
                                .read<ReportExportCubit>()
                                .exportCustomerIndividual(
                                  customerId: ctrl.text.trim(),
                                  format: 'pdf',
                                ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('PDF'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: ctrl.text.trim().isEmpty
                          ? null
                          : () => context
                                .read<ReportExportCubit>()
                                .exportCustomerIndividual(
                                  customerId: ctrl.text.trim(),
                                  format: 'excel',
                                ),
                      icon: const Icon(Icons.table_chart_outlined, size: 16),
                      label: const Text('Excel'),
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

// ── Invoice card ─────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isLoading;
  final String? error;
  const _InvoiceCard({required this.ctrl, required this.isLoading, this.error});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
              controller: ctrl,
              decoration: InputDecoration(
                labelText: 'Order ID',
                hintText: 'e.g. ord-001',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
                errorText: error,
              ),
            ),
            const SizedBox(height: 10),
            if (isLoading)
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
                  onPressed: ctrl.text.trim().isEmpty
                      ? null
                      : () => context.read<ReportExportCubit>().exportInvoice(
                          orderId: ctrl.text.trim(),
                        ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('Generate Invoice PDF'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.purple),
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
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
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

// ── Polling banner ──────────────────────────────────────────────────────────

class _PollingBanner extends StatelessWidget {
  final dynamic status;
  const _PollingBanner({this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (status?.progress as int?) ?? 0;
    final label = status?.status == 'processing'
        ? 'Preparing export… $progress%'
        : 'Export queued…';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (status?.status == 'processing')
            SizedBox(
              width: 80,
              child: LinearProgressIndicator(value: progress / 100),
            ),
        ],
      ),
    );
  }
}

// ── Export history list ─────────────────────────────────────────────────────

class _ExportHistoryList extends StatelessWidget {
  final List<ExportHistoryEntry> entries;
  const _ExportHistoryList({required this.entries});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: entries.map((e) {
          final isReady = e.status == 'ready';
          final isFailed = e.status == 'failed';
          return ListTile(
            leading: Icon(
              isReady
                  ? Icons.check_circle_outline
                  : isFailed
                  ? Icons.error_outline
                  : Icons.hourglass_empty,
              color: isReady
                  ? Colors.green
                  : isFailed
                  ? scheme.error
                  : scheme.onSurfaceVariant,
            ),
            title: Text(_labelType(e.reportType)),
            subtitle: Text(
              '${e.format.toUpperCase()} · ${_timeAgo(e.requestedAt)}',
            ),
            trailing: isReady
                ? TextButton.icon(
                    onPressed: () => context
                        .read<ReportExportCubit>()
                        .downloadExport(e.exportId),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                  )
                : isFailed
                ? Text(
                    'Failed',
                    style: TextStyle(color: scheme.error, fontSize: 12),
                  )
                : const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
          );
        }).toList(),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

String _labelType(String type) {
  switch (type) {
    case 'marketing_summary':
      return 'Marketing Summary';
    case 'sales_summary':
      return 'Sales Summary';
    case 'customer_list':
      return 'Customer List';
    case 'customer_individual':
      return 'Customer Profile';
    case 'product_list':
      return 'Product List';
    case 'invoice':
      return 'Invoice';
    default:
      return type;
  }
}
