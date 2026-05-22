// lib/features/report_export/domain/services/customer_pdf_generator.dart
//
// On-device PDF generator for the "Customer List" report.
//
// ARCHITECTURE RULES
// ─────────────────────────────────────────────────────────────────
// • Receives List<CustomerExportRow> pre-built by the cubit.
// • Never owns a datasource, mock, or UseCase reference.
// • includeVisits flag: when true, each customer gets a visit
//   history sub-section rendered below their detail block.
//
// SECTIONS per customer (in order):
//   Header card: No. | Name | Code | Type | Category | Tier | Status
//   Contact:     Phone | Alt Phone | Email | WhatsApp
//   Preferences: WhatsApp✓ | SMS✓ | In-App✓
//   Location:    Address | City | County | Country | GPS
//   Business:    Reg No. | Tax PIN | Credit Limit
//   Assignment:  Officer | Registered
//   Contacts:    all contact persons (role, phone, email)
//   Notes:       full text
//   Visits:      date | status | officer | purpose | outcome (if any)
// ─────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/customer_export_row.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _primary    = PdfColor.fromInt(0xFF1A6B4A);
const _accent     = PdfColor.fromInt(0xFF4CAF50);
const _grey       = PdfColor.fromInt(0xFF616161);
const _lightGrey  = PdfColor.fromInt(0xFFF5F5F5);
const _midGrey    = PdfColor.fromInt(0xFFE0E0E0);
const _white      = PdfColors.white;
const _red        = PdfColor.fromInt(0xFFD32F2F);
const _amber      = PdfColor.fromInt(0xFFF57F17);
const _blue       = PdfColor.fromInt(0xFF1565C0);
const _sectionBg  = PdfColor.fromInt(0xFFE8F5E9);

class CustomerPdfGenerator {
  const CustomerPdfGenerator();

  Future<File> generate(
    List<CustomerExportRow> rows, {
    bool includeVisits = false,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: _header,
        footer: _footer,
        build: (ctx) => [
          pw.SizedBox(height: 14),
          // ── Summary badge row ──────────────────────────────────
          _summaryBadges(rows),
          pw.SizedBox(height: 16),
          // ── Customer blocks ────────────────────────────────────
          ...rows.map((r) => _customerBlock(r, includeVisits: includeVisits)),
        ],
      ),
    );
    return _save(pdf);
  }

  // ── Page header ───────────────────────────────────────────────────────────

  pw.Widget _header(pw.Context ctx) => pw.Container(
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
                  color: _primary,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text('Marketing Management System',
              style: pw.TextStyle(color: _grey, fontSize: 8)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('CUSTOMER LIST',
              style: pw.TextStyle(
                  color: _primary,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text('Generated: ${_fmtDate(DateTime.now())}',
              style: pw.TextStyle(color: _grey, fontSize: 8)),
        ]),
      ],
    ),
  );

  // ── Page footer ───────────────────────────────────────────────────────────

  pw.Widget _footer(pw.Context ctx) => pw.Container(
    padding: const pw.EdgeInsets.only(top: 5),
    decoration:
        const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _midGrey))),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text('Barick Pharmacy — Confidential',
          style: pw.TextStyle(color: _grey, fontSize: 7)),
      pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: pw.TextStyle(color: _grey, fontSize: 7)),
    ]),
  );

  // ── Summary badges ────────────────────────────────────────────────────────

  pw.Widget _summaryBadges(List<CustomerExportRow> rows) {
    final total    = rows.length;
    final active   = rows.where((r) => r.status == 'active').length;
    final b2b      = rows.where((r) => r.customerType == 'b2b').length;
    final withGps  = rows.where((r) => r.latitude != null).length;

    return pw.Row(children: [
      _badge('Total Customers', '$total', _primary),
      pw.SizedBox(width: 8),
      _badge('Active', '$active', _accent),
      pw.SizedBox(width: 8),
      _badge('B2B', '$b2b', _blue),
      pw.SizedBox(width: 8),
      _badge('With GPS', '$withGps', _amber),
    ]);
  }

  pw.Widget _badge(String label, String val, PdfColor color) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(children: [
          pw.Text(val,
              style: pw.TextStyle(
                  color: _white,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold)),
          pw.Text(label,
              style: pw.TextStyle(color: _white, fontSize: 7)),
        ]),
      );

  // ── Per-customer block ────────────────────────────────────────────────────

  pw.Widget _customerBlock(CustomerExportRow r, {required bool includeVisits}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _midGrey, width: 0.5),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Header band ────────────────────────────────────────
          _blockHeader(r),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Two-column layout for main fields ─────────────
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: _leftColumn(r)),
                    pw.SizedBox(width: 10),
                    pw.Expanded(child: _rightColumn(r)),
                  ],
                ),
                // ── Contacts persons ───────────────────────────────
                if (r.contacts.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  _sectionTitle('Contact Persons'),
                  _contactsTable(r.contacts),
                ],
                // ── Notes ─────────────────────────────────────────
                if (r.notes != null && r.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  _sectionTitle('Notes'),
                  pw.Text(r.notes!,
                      style: pw.TextStyle(fontSize: 8, color: _grey)),
                ],
                // ── Visit history ──────────────────────────────────
                if (includeVisits && r.visits.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  _sectionTitle('Visit History (${r.visits.length})'),
                  _visitsTable(r.visits),
                ],
                if (includeVisits && r.visits.isEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('No visits recorded.',
                      style: pw.TextStyle(fontSize: 7.5, color: _grey)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Block header band ─────────────────────────────────────────────────────

  pw.Widget _blockHeader(CustomerExportRow r) {
    final statusColor = r.status == 'active'
        ? _accent
        : r.status == 'blacklisted'
            ? _red
            : _grey;

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
      child: pw.Row(
        children: [
          pw.Text('${r.no}. ',
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary)),
          pw.Expanded(
            child: pw.Text(r.name,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _primary)),
          ),
          if (r.code != null)
            pw.Container(
              margin: const pw.EdgeInsets.only(right: 6),
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: pw.BoxDecoration(
                color: _midGrey,
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(r.code!,
                  style: pw.TextStyle(fontSize: 7, color: _grey)),
            ),
          _pill(r.customerType.toUpperCase(), _blue),
          pw.SizedBox(width: 4),
          if (r.category != null) ...[
            _pill(r.category!, _primary),
            pw.SizedBox(width: 4),
          ],
          _pill(r.tier, _tierColor(r.tier)),
          pw.SizedBox(width: 4),
          _pill(r.status, statusColor),
        ],
      ),
    );
  }

  pw.Widget _pill(String text, PdfColor color) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: pw.BoxDecoration(
      color: color,
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Text(text,
        style: pw.TextStyle(
            color: _white, fontSize: 7, fontWeight: pw.FontWeight.bold)),
  );

  // ── Left/Right columns ────────────────────────────────────────────────────

  pw.Widget _leftColumn(CustomerExportRow r) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionTitle('Contact & Communication'),
      if (r.phone != null)     _field('Phone',     r.phone!),
      if (r.altPhone != null)  _field('Alt Phone', r.altPhone!),
      if (r.email != null)     _field('Email',     r.email!),
      if (r.whatsappNumber != null) _field('WhatsApp', r.whatsappNumber!),
      _field('Channels',
        '${r.receivesWhatsapp ? "WhatsApp " : ""}${r.receivesSms ? "SMS " : ""}${r.receivesInApp ? "In-App" : ""}'.trim(),
        muted: true,
      ),
      pw.SizedBox(height: 6),
      _sectionTitle('Location'),
      if (r.address != null) _field('Address', r.address!),
      if (r.city != null)    _field('City',    r.city!),
      if (r.county != null)  _field('County',  r.county!),
      if (r.country != null) _field('Country', r.country!),
      if (r.latitude != null && r.longitude != null)
        _field('GPS',
          '${r.latitude!.toStringAsFixed(5)}, ${r.longitude!.toStringAsFixed(5)}'),
      if (r.latitude == null) _field('GPS', 'Not captured', muted: true),
    ],
  );

  pw.Widget _rightColumn(CustomerExportRow r) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionTitle('Business'),
      if (r.businessRegistration != null)
        _field('Reg. No.',    r.businessRegistration!),
      if (r.taxPin != null)
        _field('Tax PIN',     r.taxPin!),
      if (r.creditLimit != null)
        _field('Credit Limit',
            '${r.currency ?? "TZS"} ${_fmtNum(r.creditLimit!)}'),
      if (r.creditLimit == null) _field('Credit Limit', 'Not set', muted: true),
      pw.SizedBox(height: 6),
      _sectionTitle('Assignment'),
      _field('Officer',
          r.assignedOfficerName ?? 'Not assigned',
          muted: r.assignedOfficerName == null),
      if (r.registeredAt != null)
        _field('Registered', r.registeredAt!),
    ],
  );

  // ── Contacts table ────────────────────────────────────────────────────────

  pw.Widget _contactsTable(List<CustomerContactRow> contacts) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2.0),
        3: const pw.FlexColumnWidth(2.0),
      },
      border: pw.TableBorder.all(color: _midGrey, width: 0.4),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: ['Name', 'Role', 'Phone', 'Email']
              .map((h) => _th(h))
              .toList(),
        ),
        ...contacts.map((c) => pw.TableRow(
          decoration: pw.BoxDecoration(
            color: c.isPrimary
                ? const PdfColor.fromInt(0xFFE8F5E9)
                : _white,
          ),
          children: [
            _td('${c.name}${c.isPrimary ? " ★" : ""}',
                bold: c.isPrimary),
            _td(c.role ?? '—'),
            _td(c.phone ?? '—'),
            _td(c.email ?? '—'),
          ],
        )),
      ],
    );
  }

  // ── Visits table ──────────────────────────────────────────────────────────

  pw.Widget _visitsTable(List<CustomerVisitRow> visits) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(1.8),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(2.0),
        3: const pw.FlexColumnWidth(2.0),
        4: const pw.FlexColumnWidth(2.0),
      },
      border: pw.TableBorder.all(color: _midGrey, width: 0.4),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _blue),
          children: ['Date', 'Status', 'Officer', 'Purpose', 'Outcome']
              .map((h) => _th(h))
              .toList(),
        ),
        ...visits.asMap().entries.map((e) {
          final i = e.key;
          final v = e.value;
          final isAlt = i % 2 != 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isAlt ? _lightGrey : _white,
            ),
            children: [
              _td(v.visitDate),
              _td(v.status, color: _visitStatusColor(v.status)),
              _td(v.officerName ?? '—'),
              _td(v.purpose ?? '—'),
              _td(v.outcome ?? '—'),
            ],
          );
        }),
      ],
    );
  }

  // ── Field helpers ─────────────────────────────────────────────────────────

  pw.Widget _sectionTitle(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Text(title,
        style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _primary)),
  );

  pw.Widget _field(String label, String value, {bool muted = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(label,
                style: pw.TextStyle(fontSize: 7.5, color: _grey)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 7.5,
                    color: muted ? _midGrey : null,
                    fontWeight: muted ? null : pw.FontWeight.bold)),
          ),
        ]),
      );

  pw.Widget _th(String text) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    child: pw.Text(text,
        style: pw.TextStyle(
            color: _white,
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold)),
  );

  pw.Widget _td(String text,
      {bool bold = false, PdfColor? color}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color ?? _grey)),
      );

  // ── Colour helpers ────────────────────────────────────────────────────────

  PdfColor _tierColor(String tier) => switch (tier) {
    'platinum' => const PdfColor.fromInt(0xFF6A1B9A),
    'gold'     => const PdfColor.fromInt(0xFFF57F17),
    'silver'   => const PdfColor.fromInt(0xFF546E7A),
    _          => _grey,
  };

  PdfColor _visitStatusColor(String s) => switch (s) {
    'completed' => _accent,
    'pending'   => _amber,
    'missed'    => _red,
    'flagged'   => const PdfColor.fromInt(0xFFE65100),
    _           => _grey,
  };

  // ── Save ──────────────────────────────────────────────────────────────────

  static Future<File> _save(pw.Document pdf) async {
    final dir   = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file  = File('${dir.path}/customer_list_$stamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ── Formatters ────────────────────────────────────────────────────────────

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  static String _fmtNum(double v) {
    final s = v.toStringAsFixed(0).split('');
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}