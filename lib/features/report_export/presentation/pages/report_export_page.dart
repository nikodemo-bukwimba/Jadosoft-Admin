// lib/features/report_export/presentation/pages/report_export_page.dart
//
// Page is now a pure composition layer.
// All widget logic lives in presentation/widgets/.
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/report_export_cubit.dart';
import '../cubit/report_export_state.dart';
import '../widgets/report_export_card.dart';
import '../widgets/report_export_history_list.dart';
import '../widgets/report_export_individual_customer_card.dart';
import '../widgets/report_export_invoice_card.dart';
import '../widgets/report_export_period_selector.dart';
import '../widgets/report_export_polling_banner.dart';
import '../widgets/report_export_section_header.dart';
import '../widgets/report_export_visit_history_toggle.dart';
import '../widgets/report_export_weekly_plans_card.dart';
import '../utils/report_export_label.dart';

class ReportExportPage extends StatefulWidget {
  const ReportExportPage({super.key});

  @override
  State<ReportExportPage> createState() => _ReportExportPageState();
}

class _ReportExportPageState extends State<ReportExportPage> {
  String _period = 'this_month';
  DateTimeRange? _customRange;
  bool _includeVisits = false;

  final _invoiceCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _customerCtrl.dispose();
    super.dispose();
  }

  // ── Date helpers ───────────────────────────────────────────────────────────

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
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 840;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Export'), centerTitle: false),
      body: BlocConsumer<ReportExportCubit, ReportExportState>(
        listener: _onStateChange,
        builder: (ctx, state) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? (width - 960) / 2 : 16,
            vertical: 16,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportExportPeriodSelector(
                  selected: _period,
                  customRange: _customRange,
                  onChanged: (v) => setState(() => _period = v),
                  onPickCustom: _pickCustomRange,
                ),
                const SizedBox(height: 20),

                if (state.activeExportId != null) ...[
                  ReportExportPollingBanner(status: state.pollingStatus),
                  const SizedBox(height: 16),
                ],

                isWide
                    ? _WideLayout(
                        state: state,
                        resolvedRange: _resolvedDateRange,
                        invoiceCtrl: _invoiceCtrl,
                        customerCtrl: _customerCtrl,
                        includeVisits: _includeVisits,
                        onIncludeVisitsChanged: (v) =>
                            setState(() => _includeVisits = v),
                      )
                    : _NarrowLayout(
                        state: state,
                        resolvedRange: _resolvedDateRange,
                        invoiceCtrl: _invoiceCtrl,
                        customerCtrl: _customerCtrl,
                        includeVisits: _includeVisits,
                        onIncludeVisitsChanged: (v) =>
                            setState(() => _includeVisits = v),
                      ),

                const SizedBox(height: 24),

                if (state.exportHistory.isNotEmpty) ...[
                  Text(
                    'Export History',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ReportExportHistoryList(entries: state.exportHistory),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Listener ───────────────────────────────────────────────────────────────

  void _onStateChange(BuildContext ctx, ReportExportState state) {
    void snack(String msg, {Color? bg, SnackBarAction? action}) =>
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: bg,
            behavior: SnackBarBehavior.floating,
            action: action,
          ),
        );

    if (state.activeExportId != null &&
        state.exportHistory.isNotEmpty &&
        state.exportHistory.first.status == 'pending') {
      snack(
        'Export queued — '
        '${reportExportLabel(state.exportHistory.first.reportType)} '
        'will be ready shortly',
      );
    }
    if (state.lastDownloadedFileName != null) {
      snack('Opening ${state.lastDownloadedFileName}…');
    }
    if (state.lastSavedPath != null) {
      snack(
        'Saved to ${state.lastSavedPath}',
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => ctx.read<ReportExportCubit>().downloadExport(
            state.exportHistory.first.exportId,
          ),
        ),
      );
    }
    if (state.downloadExportError != null) {
      snack(
        'Download failed: ${state.downloadExportError}',
        bg: Theme.of(ctx).colorScheme.error,
      );
    }
    if (state.customerListError != null) {
      snack(
        'Customer export failed: ${state.customerListError}',
        bg: Theme.of(ctx).colorScheme.error,
      );
    }
    if (state.weeklyPlansError != null) {
      snack(
        'Weekly plans export failed: ${state.weeklyPlansError}',
        bg: Theme.of(ctx).colorScheme.error,
      );
    }
    if (state.productListError != null) {
      snack(
        'Product export failed: ${state.productListError}',
        bg: Theme.of(ctx).colorScheme.error,
      );
    }
  }
}

// ── Wide layout (≥840 px) ──────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final ReportExportState state;
  final (String, String) Function() resolvedRange;
  final TextEditingController invoiceCtrl;
  final TextEditingController customerCtrl;
  final bool includeVisits;
  final ValueChanged<bool> onIncludeVisitsChanged;

  const _WideLayout({
    required this.state,
    required this.resolvedRange,
    required this.invoiceCtrl,
    required this.customerCtrl,
    required this.includeVisits,
    required this.onIncludeVisitsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left ──────────────────────────────────────────────────
        Expanded(
          child: Column(
            children: [
              const ReportExportSectionHeader(
                title: 'Marketing Reports',
                icon: Icons.campaign_outlined,
              ),
              const SizedBox(height: 8),
              ReportExportCard(
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
              const ReportExportSectionHeader(
                title: 'Customer Reports',
                icon: Icons.people_outline,
              ),
              const SizedBox(height: 8),
              ReportExportCard(
                title: 'Customer List',
                description:
                    'All customer profiles — business, contact, address, GPS, officer',
                icon: Icons.list_alt,
                color: Colors.indigo,
                isLoading: state.isCustomerListLoading,
                supportsExcel: true,
                extra: ReportExportVisitHistoryToggle(
                  value: includeVisits,
                  onChanged: onIncludeVisitsChanged,
                ),
                onExport: (fmt) =>
                    context.read<ReportExportCubit>().exportCustomerList(
                      format: fmt,
                      includeVisits: includeVisits,
                    ),
              ),
              const SizedBox(height: 8),
              ReportExportIndividualCustomerCard(
                ctrl: customerCtrl,
                isLoading: state.isCustomerIndividualLoading,
                includeVisits: includeVisits,
                onIncludeVisitsChanged: onIncludeVisitsChanged,
              ),
              const SizedBox(height: 8),
              const ReportExportSectionHeader(
                title: 'Field Operations',
                icon: Icons.map_outlined,
              ),
              const SizedBox(height: 8),
              ReportExportWeeklyPlansCard(
                isLoading: state.isWeeklyPlansLoading,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // ── Right ─────────────────────────────────────────────────
        Expanded(
          child: Column(
            children: [
              const ReportExportSectionHeader(
                title: 'Sales Reports',
                icon: Icons.point_of_sale_outlined,
              ),
              const SizedBox(height: 8),
              ReportExportCard(
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
              ReportExportCard(
                title: 'Product List',
                description:
                    'All products — name, description, pack size, price, quantity',
                icon: Icons.medication_outlined,
                color: Colors.orange,
                isLoading: state.isProductListLoading,
                supportsExcel: true,
                onExport: (fmt) => context
                    .read<ReportExportCubit>()
                    .exportProductList(format: fmt),
              ),
              const SizedBox(height: 8),
              const ReportExportSectionHeader(
                title: 'Invoice',
                icon: Icons.receipt_long_outlined,
              ),
              const SizedBox(height: 8),
              ReportExportInvoiceCard(
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

// ── Narrow layout (<840 px) ────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final ReportExportState state;
  final (String, String) Function() resolvedRange;
  final TextEditingController invoiceCtrl;
  final TextEditingController customerCtrl;
  final bool includeVisits;
  final ValueChanged<bool> onIncludeVisitsChanged;

  const _NarrowLayout({
    required this.state,
    required this.resolvedRange,
    required this.invoiceCtrl,
    required this.customerCtrl,
    required this.includeVisits,
    required this.onIncludeVisitsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ReportExportSectionHeader(
          title: 'Marketing Reports',
          icon: Icons.campaign_outlined,
        ),
        const SizedBox(height: 8),
        ReportExportCard(
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
        const ReportExportSectionHeader(
          title: 'Sales Reports',
          icon: Icons.point_of_sale_outlined,
        ),
        const SizedBox(height: 8),
        ReportExportCard(
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
        ReportExportCard(
          title: 'Product List',
          description:
              'All products — name, description, pack size, price, quantity',
          icon: Icons.medication_outlined,
          color: Colors.orange,
          isLoading: state.isProductListLoading,
          supportsExcel: true,
          onExport: (fmt) =>
              context.read<ReportExportCubit>().exportProductList(format: fmt),
        ),
        const SizedBox(height: 16),
        const ReportExportSectionHeader(
          title: 'Customer Reports',
          icon: Icons.people_outline,
        ),
        const SizedBox(height: 8),
        ReportExportCard(
          title: 'Customer List',
          description:
              'All customer profiles — business, contact, address, GPS, officer',
          icon: Icons.list_alt,
          color: Colors.indigo,
          isLoading: state.isCustomerListLoading,
          supportsExcel: true,
          extra: ReportExportVisitHistoryToggle(
            value: includeVisits,
            onChanged: onIncludeVisitsChanged,
          ),
          onExport: (fmt) => context
              .read<ReportExportCubit>()
              .exportCustomerList(format: fmt, includeVisits: includeVisits),
        ),
        const SizedBox(height: 8),
        ReportExportIndividualCustomerCard(
          ctrl: customerCtrl,
          isLoading: state.isCustomerIndividualLoading,
          includeVisits: includeVisits,
          onIncludeVisitsChanged: onIncludeVisitsChanged,
        ),
        const SizedBox(height: 16),
        const ReportExportSectionHeader(
          title: 'Field Operations',
          icon: Icons.map_outlined,
        ),
        const SizedBox(height: 8),
        ReportExportWeeklyPlansCard(isLoading: state.isWeeklyPlansLoading),
        const SizedBox(height: 16),
        const ReportExportSectionHeader(
          title: 'Invoice',
          icon: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: 8),
        ReportExportInvoiceCard(
          ctrl: invoiceCtrl,
          isLoading: state.isInvoiceLoading,
          error: state.invoiceError,
        ),
      ],
    );
  }
}
