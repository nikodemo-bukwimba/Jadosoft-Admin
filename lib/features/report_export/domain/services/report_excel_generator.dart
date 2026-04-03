// report_excel_generator.dart
// ─────────────────────────────────────────────────────────────────────────────
// Generates real .xlsx files from mock data.
// Product list format matches the required layout:
//   No | Product Description | Batch number | Expiry date |
//   Pack size | Pack price | Available quantity
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../../../product/data/datasources/product_mock_datasource.dart';

class ReportExcelGenerator {
  // ── Public entry point ─────────────────────────────────────────────────────

  static Future<File> generate({
    required String reportType,
    String? referenceId,
    String? dateFrom,
    String? dateTo,
  }) async {
    switch (reportType) {
      case 'product_list':
        return _buildProductList();
      default:
        throw Exception('Excel export not supported for: $reportType');
    }
  }

  // ── Product List ───────────────────────────────────────────────────────────

  static Future<File> _buildProductList() async {
    final excel = Excel.createExcel();
    final sheet = excel['Product list'];

    // Remove default Sheet1
    excel.delete('Sheet1');

    // ── Styles ────────────────────────────────────────────────────────────────

    // Title style — merged, bold, centred
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Header style — bold, white text, dark green background, wrapped, centred
    final headerStyle = CellStyle(
      bold: true,
      fontSize: 10,
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

    // Data style — normal, bordered, vertically centred
    final dataStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final dataCenterStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final dataNumStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Expiry warning — red text for near-expiry
    final expiryWarnStyle = CellStyle(
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#D32F2F'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bold: true,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Alternating row background
    final altRowStyle = CellStyle(
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final altRowCenterStyle = CellStyle(
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final altRowNumStyle = CellStyle(
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // ── Row 1: Title (merged A1:G1) ───────────────────────────────────────────
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('G1'));
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('Product list');
    titleCell.cellStyle = titleStyle;
    sheet.setRowHeight(0, 28);

    // ── Row 2: Headers ────────────────────────────────────────────────────────
    const headers = [
      'No',
      'Product Description',
      'Batch number',
      'Expiry date',
      'Pack size',
      'Pack price',
      'Available quantity',
    ];
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
    }
    sheet.setRowHeight(1, 40);

    // ── Column widths ─────────────────────────────────────────────────────────
    sheet.setColumnWidth(0, 6);   // No
    sheet.setColumnWidth(1, 34);  // Product Description
    sheet.setColumnWidth(2, 18);  // Batch number
    sheet.setColumnWidth(3, 14);  // Expiry date
    sheet.setColumnWidth(4, 16);  // Pack size
    sheet.setColumnWidth(5, 14);  // Pack price
    sheet.setColumnWidth(6, 16);  // Available quantity

    // ── Data rows ─────────────────────────────────────────────────────────────
    final ds = ProductMockDataSource();
    final products = await ds.getAll();
    final now = DateTime.now();

    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      final rowIdx = i + 2; // row 3 onward (0-indexed: 2)
      final isAlt = i % 2 != 0;

      final expiry = p.expiryDate;
      final expiryStr = expiry != null
          ? '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}'
          : '—';
      final isExpiringSoon = expiry != null &&
          expiry.difference(now).inDays <= 180;

      // Resolve styles for this row
      final stC     = isAlt ? altRowCenterStyle : dataCenterStyle;
      final stN     = isAlt ? altRowNumStyle    : dataNumStyle;

      void setCell(int col, CellValue val, CellStyle style) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx));
        cell.value = val;
        cell.cellStyle = style;
      }

      // Col A: No
      setCell(0, IntCellValue(i + 1), stC);

      // Col B: Product Description (name + description as wrapped text)
      final desc = p.description != null && p.description!.isNotEmpty
          ? '${p.name}\n${p.description}'
          : p.name;
      final descCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx));
      descCell.value = TextCellValue(desc);
      descCell.cellStyle = (isAlt ? altRowStyle : dataStyle).copyWith(
        textWrappingVal: TextWrapping.WrapText,
      );

      // Col C: Batch number
      setCell(2, TextCellValue(p.batchNumber ?? '—'), stC);

      // Col D: Expiry date (red if expiring soon)
      final expiryCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx));
      expiryCell.value = TextCellValue(expiryStr);
      expiryCell.cellStyle = isExpiringSoon
          ? expiryWarnStyle
          : stC;

      // Col E: Pack size
      setCell(4, TextCellValue(p.packSize ?? '—'), stC);

      // Col F: Pack price (TZS formatted)
      setCell(5, TextCellValue('TZS ${_fmtNum(p.price)}'), stN);

      // Col G: Available quantity
      final qty = p.quantityAvailable;
      final qtyVal = qty != null ? '$qty' : '—';
      final qtyStyle = qty != null && qty == 0
          ? (isAlt ? altRowCenterStyle : dataCenterStyle).copyWith(
              fontColorHexVal: ExcelColor.fromHexString('#D32F2F'),
              boldVal: true,
            )
          : stC;
      setCell(6, TextCellValue(qtyVal), qtyStyle);

      sheet.setRowHeight(rowIdx, p.description != null ? 36 : 20);
    }

    // ── Summary row at bottom ─────────────────────────────────────────────────
    final summaryRowIdx = products.length + 2;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRowIdx),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: summaryRowIdx),
    );
    final summaryLabel = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRowIdx));
    summaryLabel.value = TextCellValue('Total Available Units');
    summaryLabel.cellStyle = CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Right,
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final totalQty = products.fold<int>(0, (s, p) => s + (p.quantityAvailable ?? 0));
    final summaryVal = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: summaryRowIdx));
    summaryVal.value = IntCellValue(totalQty);
    summaryVal.cellStyle = CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // ── Save ──────────────────────────────────────────────────────────────────
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/product_list_$stamp.xlsx');
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Excel encoding failed');
    await file.writeAsBytes(bytes);
    return file;
  }

  static String _fmtNum(double v) {
    final parts = v.toStringAsFixed(0).split('');
    final result = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.write(',');
      result.write(parts[i]);
    }
    return result.toString();
  }
}