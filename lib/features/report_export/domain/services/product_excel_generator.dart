// lib/features/report_export/domain/services/product_excel_generator.dart
//
// On-device Excel (.xlsx) generator for the "Product List" report.
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
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../models/product_export_row.dart';

class ProductExcelGenerator {
  const ProductExcelGenerator();

  // ── Public entry point ─────────────────────────────────────────────────────

  Future<File> generate(List<ProductExportRow> rows) async {
    final excel = Excel.createExcel();
    final sheet = excel['Product List'];
    excel.delete('Sheet1'); // remove default empty sheet

    _buildSheet(sheet, rows);

    return _saveToFile(excel);
  }

  // ── Sheet builder ──────────────────────────────────────────────────────────

  void _buildSheet(Sheet sheet, List<ProductExportRow> rows) {
    // ── Styles ────────────────────────────────────────────────────────────────

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final headerStyle = CellStyle(
      bold: true,
      fontSize: 9,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1A6B4A'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Base data styles (even rows — white bg)
    final styleLeft = CellStyle(
      fontSize: 9,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final styleCenter = CellStyle(
      fontSize: 9,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final styleRight = CellStyle(
      fontSize: 9,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Alternating row (light grey bg)
    final altLeft = CellStyle(
      fontSize: 9,
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final altCenter = CellStyle(
      fontSize: 9,
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final altRight = CellStyle(
      fontSize: 9,
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Zero-qty warning style (red bold)
    final qtyZeroStyle = CellStyle(
      fontSize: 9,
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#D32F2F'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Summary row style
    final summaryLabelStyle = CellStyle(
      bold: true,
      fontSize: 9,
      horizontalAlign: HorizontalAlign.Right,
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      fontColorHex: ExcelColor.fromHexString('#1A6B4A'),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final summaryValStyle = CellStyle(
      bold: true,
      fontSize: 9,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      fontColorHex: ExcelColor.fromHexString('#1A6B4A'),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // ── Row 0: Title (merged A1:F1) ───────────────────────────────────────────
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('F1'),
    );
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('Product List');
    titleCell.cellStyle = titleStyle;
    sheet.setRowHeight(0, 28);

    // ── Row 1: Headers ────────────────────────────────────────────────────────
    const headers = [
      'No.',
      'Product Name',
      'Description',
      'Pack Size',
      'Pack Price',
      'Qty Available',
    ];

    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1),
      );
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
    }
    sheet.setRowHeight(1, 36);

    // ── Column widths ─────────────────────────────────────────────────────────
    sheet.setColumnWidth(0, 6);   // No.
    sheet.setColumnWidth(1, 28);  // Product Name
    sheet.setColumnWidth(2, 36);  // Description
    sheet.setColumnWidth(3, 14);  // Pack Size
    sheet.setColumnWidth(4, 16);  // Pack Price
    sheet.setColumnWidth(5, 14);  // Qty Available

    // ── Data rows ─────────────────────────────────────────────────────────────
    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      final rowIdx = i + 2; // rows start at index 2 (after title + header)
      final isAlt = i % 2 != 0;

      void setCell(int col, CellValue val, CellStyle style) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx),
        );
        cell.value = val;
        cell.cellStyle = style;
      }

      // Col 0: No.
      setCell(0, IntCellValue(r.no), isAlt ? altCenter : styleCenter);

      // Col 1: Product Name (bold via left-aligned style)
      final nameCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
      );
      nameCell.value = TextCellValue(r.name);
      nameCell.cellStyle = (isAlt ? altLeft : styleLeft).copyWith(
        boldVal: true,
      );

      // Col 2: Description (wrapped)
      setCell(
        2,
        TextCellValue(r.description.isNotEmpty ? r.description : '—'),
        isAlt ? altLeft : styleLeft,
      );

      // Col 3: Pack Size
      setCell(
        3,
        TextCellValue(r.packSize.isNotEmpty ? r.packSize : '—'),
        isAlt ? altCenter : styleCenter,
      );

      // Col 4: Pack Price (TZS formatted)
      setCell(
        4,
        TextCellValue('TZS ${_fmtNum(r.packPrice)}'),
        isAlt ? altRight : styleRight,
      );

      // Col 5: Qty Available — red if zero
      final qtyIsZero = r.quantityAvailable == 0;
      setCell(
        5,
        IntCellValue(r.quantityAvailable),
        qtyIsZero ? qtyZeroStyle : (isAlt ? altCenter : styleCenter),
      );

      // Row height: taller if description is long
      sheet.setRowHeight(
        rowIdx,
        r.description.length > 60 ? 40 : 20,
      );
    }

    // ── Summary row ───────────────────────────────────────────────────────────
    final summaryRowIdx = rows.length + 2;

    // Merge cols 0-4 for label
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRowIdx),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryRowIdx),
    );
    final summaryLabel = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRowIdx),
    );
    summaryLabel.value = TextCellValue('Total Available Units');
    summaryLabel.cellStyle = summaryLabelStyle;

    final totalQty = rows.fold<int>(0, (s, r) => s + r.quantityAvailable);
    final summaryVal = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: summaryRowIdx),
    );
    summaryVal.value = IntCellValue(totalQty);
    summaryVal.cellStyle = summaryValStyle;

    sheet.setRowHeight(summaryRowIdx, 22);
  }

  // ── File save ──────────────────────────────────────────────────────────────

  static Future<File> _saveToFile(Excel excel) async {
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/product_list_$stamp.xlsx');
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Excel encoding failed');
    await file.writeAsBytes(bytes);
    return file;
  }

  // ── Formatter ─────────────────────────────────────────────────────────────

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