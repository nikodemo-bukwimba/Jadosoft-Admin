// lib/features/report_export/domain/services/weekly_plan_excel_generator.dart
//
// On-device Excel for "Weekly Plans" report.
// Sheet 1 — "Weekly Plans"  : one row per plan, all key fields
// Sheet 2 — "Plan Items"    : one row per plan item across all plans
// ─────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../models/weekly_plan_export_row.dart';

class WeeklyPlanExcelGenerator {
  const WeeklyPlanExcelGenerator();

  Future<File> generate(
    List<WeeklyPlanExportRow> rows, {
    String? filterLabel,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _buildPlansSheet(excel, rows, filterLabel);
    _buildItemsSheet(excel, rows);

    return _save(excel, filterLabel);
  }

  // ══════════════════════════════════════════════════════════════
  // SHEET 1 — Weekly Plans summary
  // ══════════════════════════════════════════════════════════════

  void _buildPlansSheet(
    Excel excel,
    List<WeeklyPlanExportRow> rows,
    String? filterLabel,
  ) {
    final sheet = excel['Weekly Plans'];

    final headerStyle = CellStyle(
      bold: true, fontSize: 9,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1A6B4A'),
      horizontalAlign: HorizontalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final evenStyle = CellStyle(
      fontSize: 8,
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final altStyle = CellStyle(
      fontSize: 8,
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Column widths
    sheet.setColumnWidth(0, 6);   // No.
    sheet.setColumnWidth(1, 24);  // Officer
    sheet.setColumnWidth(2, 20);  // Week
    sheet.setColumnWidth(3, 12);  // Status
    sheet.setColumnWidth(4, 12);  // Submitted
    sheet.setColumnWidth(5, 12);  // Reviewed
    sheet.setColumnWidth(6, 10);  // Items
    sheet.setColumnWidth(7, 10);  // Customers
    sheet.setColumnWidth(8, 36);  // Activities
    sheet.setColumnWidth(9, 24);  // Review Notes

    // Title row
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('J1'),
    );
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue(
        'Weekly Plans Report — Barick Pharmacy'
        '${filterLabel != null ? " | $filterLabel" : ""}');
    titleCell.cellStyle = CellStyle(
      bold: true, fontSize: 13,
      horizontalAlign: HorizontalAlign.Center,
    );
    sheet.setRowHeight(0, 26);

    // Date row
    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('J2'),
    );
    final dateCell = sheet.cell(CellIndex.indexByString('A2'));
    dateCell.value = TextCellValue(
        'Generated: ${_fmtDate(DateTime.now())}  |  '
        'Total Plans: ${rows.length}  |  '
        'Officers: ${rows.map((r) => r.officerName).toSet().length}');
    dateCell.cellStyle = CellStyle(
      fontSize: 8, italic: true,
      horizontalAlign: HorizontalAlign.Center,
    );
    sheet.setRowHeight(1, 16);

    // Headers
    const headers = [
      'No.', 'Officer', 'Week', 'Status',
      'Submitted', 'Reviewed', 'Items', 'Customers',
      'Planned Activities', 'Review Notes',
    ];
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 2));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
    }
    sheet.setRowHeight(2, 20);

    // Data rows
    for (int i = 0; i < rows.length; i++) {
      final r   = rows[i];
      final row = i + 3;
      final alt = i % 2 != 0;
      final s   = alt ? altStyle : evenStyle;

      // Status color override
      final statusBg = _statusHex(r.status);
      final statusStyle = CellStyle(
        fontSize: 8, bold: true,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString(statusBg),
        horizontalAlign: HorizontalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
      );

      void set(int col, CellValue val, [CellStyle? style]) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.value = val;
        cell.cellStyle = style ?? s;
      }

      set(0, IntCellValue(r.no));
      set(1, TextCellValue(r.officerName));
      set(2, TextCellValue(r.weekRange));
      set(3, TextCellValue(r.status.toUpperCase()), statusStyle);
      set(4, TextCellValue(r.submittedAt ?? '—'));
      set(5, TextCellValue(r.reviewedAt ?? '—'));
      set(6, IntCellValue(r.items.length));
      set(7, IntCellValue(r.plannedCustomerIds.length));
      set(8, TextCellValue(r.plannedActivities ?? '—'));
      set(9, TextCellValue(r.reviewNotes ?? '—'));

      sheet.setRowHeight(row,
          (r.plannedActivities ?? '').length > 80 ? 36 : 20);
    }

    // Summary row
    final sumRow = rows.length + 3;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sumRow),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: sumRow),
    );
    final sumLabel = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sumRow));
    sumLabel.value = TextCellValue('Total Plans');
    sumLabel.cellStyle = CellStyle(
      bold: true, fontSize: 9,
      horizontalAlign: HorizontalAlign.Right,
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      fontColorHex: ExcelColor.fromHexString('#1A6B4A'),
    );

    final sumVal = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: sumRow));
    sumVal.value = IntCellValue(rows.length);
    sumVal.cellStyle = CellStyle(
      bold: true, fontSize: 9,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      fontColorHex: ExcelColor.fromHexString('#1A6B4A'),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SHEET 2 — Plan Items detail
  // ══════════════════════════════════════════════════════════════

  void _buildItemsSheet(Excel excel, List<WeeklyPlanExportRow> rows) {
    // Only build if any plan has items
    final hasItems = rows.any((r) => r.items.isNotEmpty);
    if (!hasItems) return;

    final sheet = excel['Plan Items'];

    final headerStyle = CellStyle(
      bold: true, fontSize: 9,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      horizontalAlign: HorizontalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final evenStyle = CellStyle(
      fontSize: 8,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final altStyle = CellStyle(
      fontSize: 8,
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    sheet.setColumnWidth(0, 6);   // No.
    sheet.setColumnWidth(1, 22);  // Officer
    sheet.setColumnWidth(2, 18);  // Week
    sheet.setColumnWidth(3, 14);  // Date
    sheet.setColumnWidth(4, 24);  // Customer
    sheet.setColumnWidth(5, 22);  // Title
    sheet.setColumnWidth(6, 30);  // Objective
    sheet.setColumnWidth(7, 14);  // Time
    sheet.setColumnWidth(8, 12);  // Status
    sheet.setColumnWidth(9, 28);  // Notes

    // Title
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('J1'),
    );
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value =
        TextCellValue('Plan Items Detail — Barick Pharmacy');
    titleCell.cellStyle = CellStyle(
      bold: true, fontSize: 13,
      horizontalAlign: HorizontalAlign.Center,
    );
    sheet.setRowHeight(0, 26);

    // Headers
    const headers = [
      'No.', 'Officer', 'Week', 'Date', 'Customer',
      'Title', 'Objective', 'Time', 'Status', 'Notes',
    ];
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
    }
    sheet.setRowHeight(1, 20);

    int rowIdx = 2;
    int no = 1;

    for (final r in rows) {
      for (final item in r.items) {
        final alt = rowIdx % 2 != 0;
        final s   = alt ? altStyle : evenStyle;
        final time = (item.startTime != null && item.endTime != null)
            ? '${item.startTime} – ${item.endTime}'
            : item.startTime ?? '—';

        void set(int col, CellValue val) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx));
          cell.value = val;
          cell.cellStyle = s;
        }

        set(0, IntCellValue(no));
        set(1, TextCellValue(r.officerName));
        set(2, TextCellValue(r.weekRange));
        set(3, TextCellValue(item.plannedDate ?? '—'));
        set(4, TextCellValue(
            item.customerName ?? item.customerId ?? '—'));
        set(5, TextCellValue(item.title ?? '—'));
        set(6, TextCellValue(item.objective ?? '—'));
        set(7, TextCellValue(time));
        set(8, TextCellValue(item.status));
        set(9, TextCellValue(item.notes ?? '—'));

        sheet.setRowHeight(rowIdx, 16);
        rowIdx++;
        no++;
      }
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  static Future<File> _save(Excel excel, String? filterLabel) async {
    final dir   = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final name  = filterLabel != null
        ? 'weekly_plans_filtered_$stamp.xlsx'
        : 'weekly_plans_$stamp.xlsx';
    final file = File('${dir.path}/$name');
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Excel encoding failed');
    await file.writeAsBytes(bytes);
    return file;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _statusHex(String s) => switch (s) {
    'approved'  => '4CAF50',
    'submitted' => 'F57F17',
    'rejected'  => 'D32F2F',
    _           => '757575',
  };

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}