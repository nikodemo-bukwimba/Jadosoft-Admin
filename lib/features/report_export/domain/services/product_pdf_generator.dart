// lib/features/report_export/domain/services/product_pdf_generator.dart
//
// On-device PDF generator for the "Product List" report.
//
// ARCHITECTURE RULES
// ─────────────────────────────────────────────────────────────────
// • Receives List<ProductExportRow> — pre-built by the cubit from
//   GetProductsWithPromotionsUseCase output.
// • Never owns a datasource, mock, or UseCase reference.
// • Never recomputes prices or stock — consumes entity values as-is.
//
// COLUMNS (in order)
//   No. | Product Name | Description | Pack Size | Pack Price | Qty Available
// ─────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/product_export_row.dart';

// ── Colour palette ────────────────────────────────────────────────────────────
const _primary   = PdfColor.fromInt(0xFF1A6B4A);
const _accent    = PdfColor.fromInt(0xFF4CAF50);
const _grey      = PdfColor.fromInt(0xFF757575);
const _lightGrey = PdfColor.fromInt(0xFFF5F5F5);
const _white     = PdfColors.white;
const _red       = PdfColor.fromInt(0xFFD32F2F);

class ProductPdfGenerator {
  const ProductPdfGenerator();

  // ── Public entry point ─────────────────────────────────────────────────────

  Future<File> generate(List<ProductExportRow> rows) async {
    final pdf = pw.Document();
    _buildPage(pdf, rows);
    return _saveToFile(pdf);
  }

  // ── Page builder ───────────────────────────────────────────────────────────

  void _buildPage(pw.Document pdf, List<ProductExportRow> rows) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _header(ctx),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          _table(rows),
          pw.SizedBox(height: 8),
          _summaryRow(rows),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  pw.Widget _header(pw.Context ctx) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 0, vertical: 14),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _accent, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BARIKI PHARMACY',
                style: pw.TextStyle(
                  color: _primary,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Marketing Management System',
                style: pw.TextStyle(color: _grey, fontSize: 8),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'PRODUCT LIST',
                style: pw.TextStyle(
                  color: _primary,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Generated: ${_fmtDate(DateTime.now())}',
                style: pw.TextStyle(color: _grey, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _lightGrey)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Bariki Pharmacy - Confidential',
            style: pw.TextStyle(color: _grey, fontSize: 7),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(color: _grey, fontSize: 7),
          ),
        ],
      ),
    );
  }

  // ── Table ──────────────────────────────────────────────────────────────────

  pw.Widget _table(List<ProductExportRow> rows) {
    // Column flex widths: No(0.4) | Name(2.2) | Description(2.8) | PackSize(1.2) | Price(1.4) | Qty(1.0)
    const colWidths = {
      0: pw.FlexColumnWidth(0.4),
      1: pw.FlexColumnWidth(2.2),
      2: pw.FlexColumnWidth(2.8),
      3: pw.FlexColumnWidth(1.2),
      4: pw.FlexColumnWidth(1.4),
      5: pw.FlexColumnWidth(1.0),
    };

    final headers = [
      'No.',
      'Product Name',
      'Description',
      'Pack Size',
      'Pack Price',
      'Qty Available',
    ];

    return pw.Table(
      columnWidths: colWidths,
      border: pw.TableBorder.all(color: _lightGrey, width: 0.5),
      children: [
        // ── Header row ───────────────────────────────────────────
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: headers.map((h) => _headerCell(h)).toList(),
        ),
        // ── Data rows ────────────────────────────────────────────
        ...rows.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          final isAlt = i % 2 != 0;
          final bg = isAlt ? _lightGrey : _white;
          final qtyZero = r.quantityAvailable == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _dataCell(
                '${r.no}',
                bg: bg,
                align: pw.TextAlign.center,
              ),
              _dataCell(r.name, bg: bg, bold: true),
              _dataCell(
                r.description.isNotEmpty ? r.description : '—',
                bg: bg,
                small: true,
              ),
              _dataCell(
                r.packSize.isNotEmpty ? r.packSize : '—',
                bg: bg,
                align: pw.TextAlign.center,
              ),
              _dataCell(
                'TZS ${_fmtNum(r.packPrice)}',
                bg: bg,
                align: pw.TextAlign.right,
              ),
              _dataCell(
                r.quantityAvailable > 0 ? '${r.quantityAvailable}' : '0',
                bg: bg,
                align: pw.TextAlign.center,
                color: qtyZero ? _red : null,
                bold: qtyZero,
              ),
            ],
          );
        }),
      ],
    );
  }

  // ── Summary row ────────────────────────────────────────────────────────────

  pw.Widget _summaryRow(List<ProductExportRow> rows) {
    final totalQty = rows.fold<int>(0, (s, r) => s + r.quantityAvailable);
    final totalProducts = rows.length;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFE8F5E9),
        border: pw.Border.all(color: _accent, width: 0.5),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Total Products: $totalProducts',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
          pw.Text(
            'Total Available Units: $totalQty',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Cell helpers ───────────────────────────────────────────────────────────

  pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: _white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _dataCell(
    String text, {
    required PdfColor bg,
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    bool small = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: small ? 7.5 : 8.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? _grey,
        ),
        textAlign: align,
      ),
    );
  }

  // ── File save ──────────────────────────────────────────────────────────────

  static Future<File> _saveToFile(pw.Document pdf) async {
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/product_list_$stamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ── Formatters ─────────────────────────────────────────────────────────────

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  static String _fmtNum(double v) {
    final parts = v.toStringAsFixed(0).split('');
    final buf = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }
}