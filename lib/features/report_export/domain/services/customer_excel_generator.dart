// lib/features/report_export/domain/services/customer_excel_generator.dart
//
// On-device Excel generator for the "Customer List" report.
// Each customer occupies a group of rows.
// A separate "Visit History" sheet is appended when includeVisits = true.
// ─────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../models/customer_export_row.dart';

class CustomerExcelGenerator {
  const CustomerExcelGenerator();

  Future<File> generate(
    List<CustomerExportRow> rows, {
    bool includeVisits = false,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _buildMainSheet(excel, rows);
    if (includeVisits) _buildVisitsSheet(excel, rows);

    return _save(excel);
  }

  // ══════════════════════════════════════════════════════════════
  // MAIN SHEET — Customer Directory
  // ══════════════════════════════════════════════════════════════

  void _buildMainSheet(Excel excel, List<CustomerExportRow> rows) {
    final sheet = excel['Customer Directory'];

    // ── Styles ────────────────────────────────────────────────────

    final titleStyle = CellStyle(
      bold: true, fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final sectionHeaderStyle = CellStyle(
      bold: true, fontSize: 9,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1A6B4A'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final labelStyle = CellStyle(
      bold: true, fontSize: 8,
      fontColorHex: ExcelColor.fromHexString('#1A6B4A'),
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final valueStyle = CellStyle(
      fontSize: 8,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final contactHeaderStyle = CellStyle(
      bold: true, fontSize: 8,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      horizontalAlign: HorizontalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Column widths
    sheet.setColumnWidth(0, 20);  // A: Label
    sheet.setColumnWidth(1, 30);  // B: Value 1
    sheet.setColumnWidth(2, 20);  // C: Label 2
    sheet.setColumnWidth(3, 30);  // D: Value 2
    sheet.setColumnWidth(4, 16);  // E: extra

    // ── Title row ─────────────────────────────────────────────────
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('E1'),
    );
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('Customer Directory — Barick Pharmacy');
    titleCell.cellStyle = titleStyle;
    sheet.setRowHeight(0, 28);

    // ── Generated date ────────────────────────────────────────────
    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('E2'),
    );
    final dateCell = sheet.cell(CellIndex.indexByString('A2'));
    dateCell.value = TextCellValue(
        'Generated: ${_fmtDate(DateTime.now())}  |  Total Customers: ${rows.length}');
    dateCell.cellStyle = CellStyle(
      fontSize: 8, italic: true,
      horizontalAlign: HorizontalAlign.Center,
    );
    sheet.setRowHeight(1, 16);

    int rowIdx = 2; // 0-based

    for (final r in rows) {
      // ── Customer header band ──────────────────────────────────────
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx),
      );
      final custHeader = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
      );
      custHeader.value = TextCellValue(
        '${r.no}. ${r.name}'
        '${r.code != null ? "  [${r.code}]" : ""}'
        '  —  ${r.customerType.toUpperCase()}'
        '${r.category != null ? " · ${r.category}" : ""}'
        '  |  ${r.tier.toUpperCase()}'
        '  |  ${r.status.toUpperCase()}',
      );
      custHeader.cellStyle = sectionHeaderStyle;
      sheet.setRowHeight(rowIdx, 20);
      rowIdx++;

      // ── Contact & Communication ───────────────────────────────────
      rowIdx = _sectionHeader(sheet, rowIdx, 'Contact & Communication',
          sectionHeaderStyle, color: '1A6B4A');
      rowIdx = _twoColRow(sheet, rowIdx, 'Phone', r.phone ?? '—',
          'Alt Phone', r.altPhone ?? '—', labelStyle, valueStyle);
      rowIdx = _twoColRow(sheet, rowIdx, 'Email', r.email ?? '—',
          'WhatsApp', r.whatsappNumber ?? '—', labelStyle, valueStyle);
      rowIdx = _twoColRow(sheet, rowIdx,
          'Channels',
          '${r.receivesWhatsapp ? "WhatsApp " : ""}${r.receivesSms ? "SMS " : ""}${r.receivesInApp ? "In-App" : ""}'.trim(),
          '', '', labelStyle, valueStyle);

      // ── Location ──────────────────────────────────────────────────
      rowIdx = _sectionHeader(sheet, rowIdx, 'Location',
          sectionHeaderStyle, color: '1565C0');
      rowIdx = _twoColRow(sheet, rowIdx, 'Address', r.address ?? '—',
          'City', r.city ?? '—', labelStyle, valueStyle);
      rowIdx = _twoColRow(sheet, rowIdx, 'County', r.county ?? '—',
          'Country', r.country ?? '—', labelStyle, valueStyle);
      rowIdx = _twoColRow(sheet, rowIdx,
          'GPS',
          r.latitude != null
              ? '${r.latitude!.toStringAsFixed(5)}, ${r.longitude!.toStringAsFixed(5)}'
              : 'Not captured',
          '', '', labelStyle, valueStyle);

      // ── Business ──────────────────────────────────────────────────
      rowIdx = _sectionHeader(sheet, rowIdx, 'Business',
          sectionHeaderStyle, color: '37474F');
      rowIdx = _twoColRow(sheet, rowIdx,
          'Reg. No.', r.businessRegistration ?? '—',
          'Tax PIN', r.taxPin ?? '—', labelStyle, valueStyle);
      rowIdx = _twoColRow(sheet, rowIdx,
          'Credit Limit',
          r.creditLimit != null
              ? '${r.currency ?? "TZS"} ${_fmtNum(r.creditLimit!)}'
              : 'Not set',
          'Officer', r.assignedOfficerName ?? 'Not assigned',
          labelStyle, valueStyle);
      rowIdx = _twoColRow(sheet, rowIdx,
          'Registered', r.registeredAt ?? '—',
          '', '', labelStyle, valueStyle);

      // ── Notes ─────────────────────────────────────────────────────
      if (r.notes != null && r.notes!.isNotEmpty) {
        rowIdx = _sectionHeader(sheet, rowIdx, 'Notes',
            sectionHeaderStyle, color: '546E7A');
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx),
        );
        final notesCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
        );
        notesCell.value = TextCellValue(r.notes!);
        notesCell.cellStyle = valueStyle.copyWith(
          textWrappingVal: TextWrapping.WrapText,
        );
        sheet.setRowHeight(rowIdx,
            (r.notes!.length / 80).ceil().clamp(1, 6) * 16.0);
        rowIdx++;
      }

      // ── Contact persons table ─────────────────────────────────────
      if (r.contacts.isNotEmpty) {
        rowIdx = _sectionHeader(sheet, rowIdx, 'Contact Persons',
            sectionHeaderStyle, color: '283593');
        // Sub-header
        for (int c = 0;
            c < ['Name', 'Role', 'Phone', 'Email', 'WhatsApp'].length;
            c++) {
          final hCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx),
          );
          hCell.value = TextCellValue(
              ['Name', 'Role', 'Phone', 'Email', 'WhatsApp'][c]);
          hCell.cellStyle = contactHeaderStyle;
        }
        sheet.setRowHeight(rowIdx, 18);
        rowIdx++;

        for (final contact in r.contacts) {
          final isPrimary = contact.isPrimary;
          final bg = isPrimary ? '#E8F5E9' : '#FFFFFF';
          for (int c = 0; c < 5; c++) {
            final cCell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx),
            );
            cCell.value = TextCellValue([
              '${contact.name}${isPrimary ? " ★" : ""}',
              contact.role ?? '—',
              contact.phone ?? '—',
              contact.email ?? '—',
              contact.whatsapp ?? '—',
            ][c]);
            cCell.cellStyle = CellStyle(
              fontSize: 8,
              bold: isPrimary,
              backgroundColorHex: ExcelColor.fromHexString(bg),
              leftBorder: Border(borderStyle: BorderStyle.Thin),
              rightBorder: Border(borderStyle: BorderStyle.Thin),
              topBorder: Border(borderStyle: BorderStyle.Thin),
              bottomBorder: Border(borderStyle: BorderStyle.Thin),
            );
          }
          sheet.setRowHeight(rowIdx, 16);
          rowIdx++;
        }
      }

      // ── Spacer row ────────────────────────────────────────────────
      sheet.setRowHeight(rowIdx, 8);
      rowIdx++;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // VISITS SHEET — Full Visit History
  // ══════════════════════════════════════════════════════════════

  void _buildVisitsSheet(Excel excel, List<CustomerExportRow> rows) {
    final sheet = excel['Visit History'];

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
    sheet.setColumnWidth(1, 28);  // Customer
    sheet.setColumnWidth(2, 16);  // Visit Date
    sheet.setColumnWidth(3, 14);  // Status
    sheet.setColumnWidth(4, 22);  // Officer
    sheet.setColumnWidth(5, 24);  // Purpose
    sheet.setColumnWidth(6, 30);  // Outcome
    sheet.setColumnWidth(7, 30);  // Notes

    // Title
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('H1'),
    );
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('Customer Visit History — Barick Pharmacy');
    titleCell.cellStyle = CellStyle(
      bold: true, fontSize: 13,
      horizontalAlign: HorizontalAlign.Center,
    );
    sheet.setRowHeight(0, 26);

    // Headers
    const headers = [
      'No.', 'Customer', 'Visit Date', 'Status',
      'Officer', 'Purpose', 'Outcome', 'Notes',
    ];
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1),
      );
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
    }
    sheet.setRowHeight(1, 20);

    int rowIdx = 2;
    int globalNo = 1;

    for (final r in rows) {
      if (r.visits.isEmpty) continue;

      for (final v in r.visits) {
        final isAlt = rowIdx % 2 != 0;
        final style = isAlt ? altStyle : evenStyle;

        void setCell(int col, String val) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx),
          );
          cell.value = TextCellValue(val);
          cell.cellStyle = style;
        }

        setCell(0, '$globalNo');
        setCell(1, r.name);
        setCell(2, v.visitDate);
        setCell(3, v.status);
        setCell(4, v.officerName ?? '—');
        setCell(5, v.purpose ?? '—');
        setCell(6, v.outcome ?? '—');
        setCell(7, v.notes ?? '—');

        sheet.setRowHeight(rowIdx, 16);
        rowIdx++;
        globalNo++;
      }
    }

    // Summary
    sheet.setRowHeight(rowIdx, 8);
    rowIdx++;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIdx),
    );
    final summaryCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
    );
    final totalVisits = rows.fold<int>(0, (s, r) => s + r.visits.length);
    summaryCell.value = TextCellValue(
        'Total visits recorded: $totalVisits  |  '
        'Customers with visits: ${rows.where((r) => r.visits.isNotEmpty).length}');
    summaryCell.cellStyle = CellStyle(
      bold: true, fontSize: 9,
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      fontColorHex: ExcelColor.fromHexString('#1A6B4A'),
    );
  }

  // ── Sheet helpers ─────────────────────────────────────────────────────────

  int _sectionHeader(
    Sheet sheet,
    int rowIdx,
    String title,
    CellStyle baseStyle, {
    String color = '1A6B4A',
  }) {
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx),
    );
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
    );
    cell.value = TextCellValue(title);
    cell.cellStyle = CellStyle(
      bold: true, fontSize: 8,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#$color'),
      horizontalAlign: HorizontalAlign.Left,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
    sheet.setRowHeight(rowIdx, 16);
    return rowIdx + 1;
  }

  int _twoColRow(
    Sheet sheet,
    int rowIdx,
    String label1,
    String val1,
    String label2,
    String val2,
    CellStyle labelStyle,
    CellStyle valueStyle,
  ) {
    void set(int col, String v, CellStyle s) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx),
      );
      cell.value = TextCellValue(v);
      cell.cellStyle = s;
    }

    set(0, label1, labelStyle);
    set(1, val1, valueStyle);
    if (label2.isNotEmpty) {
      set(2, label2, labelStyle);
      set(3, val2, valueStyle);
    } else {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx),
      );
    }
    sheet.setRowHeight(rowIdx, 16);
    return rowIdx + 1;
  }

  // ── File save ─────────────────────────────────────────────────────────────

  static Future<File> _save(Excel excel) async {
    final dir   = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file  = File('${dir.path}/customer_list_$stamp.xlsx');
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Excel encoding failed');
    await file.writeAsBytes(bytes);
    return file;
  }

  // ── Formatters ────────────────────────────────────────────────────────────

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

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