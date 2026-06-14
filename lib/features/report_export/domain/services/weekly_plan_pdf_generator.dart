// lib/features/report_export/domain/services/weekly_plan_pdf_generator.dart
//
// On-device PDF for "Weekly Plans" report.
// Supports: all plans OR filtered by one/multiple officers.
//
// LAYOUT per plan block:
//   Header band: No. | Officer | Week | Status
//   Activities + Notes
//   Plan items table (if any): Date | Customer | Title | Objective | Time | Status
//   Review section (if reviewed)
// ─────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/weekly_plan_export_row.dart';

const _primary   = PdfColor.fromInt(0xFF1A6B4A);
const _accent    = PdfColor.fromInt(0xFF4CAF50);
const _blue      = PdfColor.fromInt(0xFF1565C0);
const _amber     = PdfColor.fromInt(0xFFF57F17);
const _red       = PdfColor.fromInt(0xFFD32F2F);
const _grey      = PdfColor.fromInt(0xFF616161);
const _lightGrey = PdfColor.fromInt(0xFFF5F5F5);
const _midGrey   = PdfColor.fromInt(0xFFE0E0E0);
const _white     = PdfColors.white;
const _sectionBg = PdfColor.fromInt(0xFFE8F5E9);

class WeeklyPlanPdfGenerator {
  const WeeklyPlanPdfGenerator();

  Future<File> generate(
    List<WeeklyPlanExportRow> rows, {
    String? filterLabel, // e.g. "Officer: Martha Bukwimba"
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => _header(ctx, filterLabel),
        footer: _footer,
        build: (ctx) => [
          pw.SizedBox(height: 12),
          _summaryBadges(rows),
          pw.SizedBox(height: 16),
          ...rows.map(_planBlock),
        ],
      ),
    );
    return _save(pdf, filterLabel);
  }

  // ── Page header ────────────────────────────────────────────────────────────

  pw.Widget _header(pw.Context ctx, String? filterLabel) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 10),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _accent, width: 1.5)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('BARICK PHARMACY',
              style: pw.TextStyle(
                  color: _primary, fontSize: 15,
                  fontWeight: pw.FontWeight.bold)),
          pw.Text('Marketing Management System',
              style: pw.TextStyle(color: _grey, fontSize: 8)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('WEEKLY PLANS',
              style: pw.TextStyle(
                  color: _primary, fontSize: 13,
                  fontWeight: pw.FontWeight.bold)),
          if (filterLabel != null)
            pw.Text(filterLabel,
                style: pw.TextStyle(color: _blue, fontSize: 8,
                    fontWeight: pw.FontWeight.bold)),
          pw.Text('Generated: ${_fmtDate(DateTime.now())}',
              style: pw.TextStyle(color: _grey, fontSize: 8)),
        ]),
      ],
    ),
  );

  pw.Widget _footer(pw.Context ctx) => pw.Container(
    padding: const pw.EdgeInsets.only(top: 5),
    decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _midGrey))),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Barick Pharmacy — Confidential',
            style: pw.TextStyle(color: _grey, fontSize: 7)),
        pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(color: _grey, fontSize: 7)),
      ],
    ),
  );

  // ── Summary badges ─────────────────────────────────────────────────────────

  pw.Widget _summaryBadges(List<WeeklyPlanExportRow> rows) {
    final counts = <String, int>{};
    for (final r in rows) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }
    final officers = rows.map((r) => r.officerName).toSet().length;

    return pw.Row(children: [
      _badge('Total Plans', '${rows.length}', _primary),
      pw.SizedBox(width: 8),
      _badge('Officers', '$officers', _blue),
      pw.SizedBox(width: 8),
      if ((counts['approved'] ?? 0) > 0) ...[
        _badge('Approved', '${counts['approved']}', _accent),
        pw.SizedBox(width: 8),
      ],
      if ((counts['submitted'] ?? 0) > 0) ...[
        _badge('Submitted', '${counts['submitted']}', _amber),
        pw.SizedBox(width: 8),
      ],
      if ((counts['rejected'] ?? 0) > 0) ...[
        _badge('Rejected', '${counts['rejected']}', _red),
        pw.SizedBox(width: 8),
      ],
      if ((counts['draft'] ?? 0) > 0)
        _badge('Draft', '${counts['draft']}', _grey),
    ]);
  }

  pw.Widget _badge(String label, String val, PdfColor color) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(
          color: color, borderRadius: pw.BorderRadius.circular(5)),
        child: pw.Column(children: [
          pw.Text(val, style: pw.TextStyle(
              color: _white, fontSize: 13,
              fontWeight: pw.FontWeight.bold)),
          pw.Text(label, style: pw.TextStyle(color: _white, fontSize: 7)),
        ]),
      );

  // ── Plan block ─────────────────────────────────────────────────────────────

  pw.Widget _planBlock(WeeklyPlanExportRow r) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 14),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _midGrey, width: 0.5),
      borderRadius: pw.BorderRadius.circular(5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _planHeader(r),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Activities & Notes ──────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: _section('Planned Activities',
                      r.plannedActivities ?? 'Not specified')),
                  if (r.notes != null && r.notes!.isNotEmpty) ...[
                    pw.SizedBox(width: 10),
                    pw.Expanded(child: _section('Notes', r.notes!)),
                  ],
                ],
              ),
              // ── Plan items ──────────────────────────────────────────
              if (r.items.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                _sectionTitle('Visit Plan (${r.items.length} items)'),
                _itemsTable(r.items),
              ] else if (r.plannedCustomerIds.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                _sectionTitle(
                    'Planned Customers (${r.plannedCustomerIds.length})'),
                pw.Text(r.plannedCustomerIds.join(', '),
                    style: pw.TextStyle(fontSize: 8, color: _grey)),
              ],
              // ── Review ──────────────────────────────────────────────
              if (r.reviewedAt != null) ...[
                pw.SizedBox(height: 8),
                _reviewSection(r),
              ],
              // ── Timeline ────────────────────────────────────────────
              pw.SizedBox(height: 6),
              _timelineRow(r),
            ],
          ),
        ),
      ],
    ),
  );

  // ── Plan header band ───────────────────────────────────────────────────────

  pw.Widget _planHeader(WeeklyPlanExportRow r) {
    final statusColor = _statusColor(r.status);
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: const pw.BoxDecoration(
        color: _sectionBg,
        borderRadius: pw.BorderRadius.only(
          topLeft: pw.Radius.circular(5),
          topRight: pw.Radius.circular(5),
        ),
      ),
      child: pw.Row(children: [
        pw.Text('${r.no}. ',
            style: pw.TextStyle(fontSize: 9,
                fontWeight: pw.FontWeight.bold, color: _primary)),
        pw.Expanded(
          child: pw.Text(r.officerName,
              style: pw.TextStyle(fontSize: 10,
                  fontWeight: pw.FontWeight.bold, color: _primary)),
        ),
        pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: pw.BoxDecoration(
            color: _midGrey, borderRadius: pw.BorderRadius.circular(3)),
          child: pw.Text(r.weekRange,
              style: pw.TextStyle(fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold, color: _grey)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: pw.BoxDecoration(
            color: statusColor,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Text(r.status.toUpperCase(),
              style: pw.TextStyle(
                  color: _white, fontSize: 7,
                  fontWeight: pw.FontWeight.bold)),
        ),
      ]),
    );
  }

  // ── Items table ────────────────────────────────────────────────────────────

  pw.Widget _itemsTable(List<PlanItemExportRow> items) => pw.Table(
    columnWidths: {
      0: const pw.FlexColumnWidth(1.6),
      1: const pw.FlexColumnWidth(2.0),
      2: const pw.FlexColumnWidth(2.0),
      3: const pw.FlexColumnWidth(2.4),
      4: const pw.FlexColumnWidth(1.4),
      5: const pw.FlexColumnWidth(1.2),
    },
    border: pw.TableBorder.all(color: _midGrey, width: 0.4),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _blue),
        children: ['Date', 'Customer', 'Title', 'Objective', 'Time', 'Status']
            .map((h) => _th(h))
            .toList(),
      ),
      ...items.asMap().entries.map((e) {
        final i = e.key;
        final it = e.value;
        final alt = i % 2 != 0;
        final bg = alt ? _lightGrey : _white;
        final time = (it.startTime != null && it.endTime != null)
            ? '${it.startTime} – ${it.endTime}'
            : it.startTime ?? '—';
        return pw.TableRow(
          decoration: pw.BoxDecoration(color: bg),
          children: [
            _td(it.plannedDate ?? '—', bg: bg),
            _td(it.customerName ?? it.customerId ?? '—', bg: bg),
            _td(it.title ?? '—', bg: bg),
            _td(it.objective ?? '—', bg: bg, small: true),
            _td(time, bg: bg),
            _td(it.status, bg: bg,
                color: _itemStatusColor(it.status)),
          ],
        );
      }),
    ],
  );

  // ── Review section ─────────────────────────────────────────────────────────

  pw.Widget _reviewSection(WeeklyPlanExportRow r) => pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: r.status == 'approved'
          ? const PdfColor.fromInt(0xFFE8F5E9)
          : const PdfColor.fromInt(0xFFFFEBEE),
      borderRadius: pw.BorderRadius.circular(4),
      border: pw.Border.all(
        color: r.status == 'approved' ? _accent : _red, width: 0.5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Review',
            style: pw.TextStyle(fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: r.status == 'approved' ? _accent : _red)),
        pw.SizedBox(height: 3),
        pw.Row(children: [
          pw.Text('Reviewed: ',
              style: pw.TextStyle(fontSize: 7.5, color: _grey)),
          pw.Text(r.reviewedAt ?? '—',
              style: pw.TextStyle(fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold, color: _grey)),
        ]),
        if (r.reviewNotes != null && r.reviewNotes!.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(r.reviewNotes!,
              style: pw.TextStyle(fontSize: 7.5, color: _grey)),
        ],
      ],
    ),
  );

  // ── Timeline row ───────────────────────────────────────────────────────────

  pw.Widget _timelineRow(WeeklyPlanExportRow r) => pw.Row(children: [
    _timelineItem('Created', r.createdAt),
    if (r.submittedAt != null) ...[
      pw.SizedBox(width: 12),
      _timelineItem('Submitted', r.submittedAt!),
    ],
    if (r.reviewedAt != null) ...[
      pw.SizedBox(width: 12),
      _timelineItem('Reviewed', r.reviewedAt!),
    ],
  ]);

  pw.Widget _timelineItem(String label, String date) => pw.Row(children: [
    pw.Container(
      width: 5, height: 5,
      decoration: const pw.BoxDecoration(
        color: _accent, shape: pw.BoxShape.circle),
    ),
    pw.SizedBox(width: 4),
    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 6.5, color: _grey)),
      pw.Text(date, style: pw.TextStyle(
          fontSize: 7, fontWeight: pw.FontWeight.bold, color: _grey)),
    ]),
  ]);

  // ── Helpers ────────────────────────────────────────────────────────────────

  pw.Widget _section(String title, String content) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionTitle(title),
      pw.Text(content, style: pw.TextStyle(fontSize: 8, color: _grey)),
    ],
  );

  pw.Widget _sectionTitle(String t) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Text(t,
        style: pw.TextStyle(
            fontSize: 8, fontWeight: pw.FontWeight.bold, color: _primary)),
  );

  pw.Widget _th(String text) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    child: pw.Text(text,
        style: pw.TextStyle(
            color: _white, fontSize: 7.5,
            fontWeight: pw.FontWeight.bold)),
  );

  pw.Widget _td(String text,
      {required PdfColor bg, bool small = false, PdfColor? color}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: small ? 7 : 8,
                color: color ?? _grey)),
      );

  PdfColor _statusColor(String s) => switch (s) {
    'approved'  => _accent,
    'submitted' => _amber,
    'rejected'  => _red,
    'draft'     => _grey,
    _           => _grey,
  };

  PdfColor _itemStatusColor(String s) => switch (s) {
    'completed' => _accent,
    'planned'   => _blue,
    'skipped'   => _red,
    _           => _grey,
  };

  // ── Save ───────────────────────────────────────────────────────────────────

  static Future<File> _save(pw.Document pdf, String? filterLabel) async {
    final dir   = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final name  = filterLabel != null
        ? 'weekly_plans_filtered_$stamp.pdf'
        : 'weekly_plans_$stamp.pdf';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}