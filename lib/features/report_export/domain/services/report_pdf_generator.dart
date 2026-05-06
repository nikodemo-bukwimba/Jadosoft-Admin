// // report_pdf_generator.dart
// // ─────────────────────────────────────────────────────────────────────────────
// // On-device PDF generator for all Barick Pharmacy report types.
// // Uses the 'pdf' package (dart PDF library) to generate real formatted PDFs.
// // Order data comes from OrderRemoteDataSource (real API).
// // All other datasources (customer, payment, product, visit, officer, plan)
// // remain on their existing datasource implementations.
// //
// // Report types supported:
// //   marketing_summary   — visits, officer performance, plan compliance
// //   sales_summary       — orders, revenue, payments, products
// //   customer_list       — all customer profiles
// //   customer_individual — single customer + visit history
// //   product_list        — all products with category + status
// //   invoice             — per-order invoice PDF
// // ─────────────────────────────────────────────────────────────────────────────

// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import '../../../customer/data/datasources/customer_mock_datasource.dart';
// import '../../../order/data/datasources/order_remote_datasource.dart';
// import '../../../payment/data/datasources/payment_mock_datasource.dart';
// import '../../../product/data/datasources/product_mock_datasource.dart';
// import '../../../visit/data/datasources/visit_mock_datasource.dart';
// import '../../../officer/data/datasources/officer_mock_datasource.dart';
// import '../../../weekly_plan/data/datasources/weekly_plan_mock_datasource.dart';
// import '../../../order/data/models/order_model.dart';

// // ── Colour palette ────────────────────────────────────────────────────────────
// const _primary = PdfColor.fromInt(0xFF1A6B4A);
// const _secondary = PdfColor.fromInt(0xFF2E7D32);
// const _accent = PdfColor.fromInt(0xFF4CAF50);
// const _grey = PdfColor.fromInt(0xFF757575);
// const _lightGrey = PdfColor.fromInt(0xFFF5F5F5);
// const _white = PdfColors.white;
// const _black = PdfColors.black;
// const _red = PdfColor.fromInt(0xFFD32F2F);
// const _orange = PdfColor.fromInt(0xFFF57C00);

// class ReportPdfGenerator {
//   final OrderRemoteDataSource _orderDataSource;

//   const ReportPdfGenerator({required OrderRemoteDataSource orderDataSource})
//       : _orderDataSource = orderDataSource;

//   // ── Public entry point ─────────────────────────────────────────────────────

//   Future<File> generate({
//     required String reportType,
//     String? referenceId,
//     String? dateFrom,
//     String? dateTo,
//   }) async {
//     final pdf = pw.Document();

//     switch (reportType) {
//       case 'marketing_summary':
//         await _buildMarketingSummary(pdf, dateFrom, dateTo);
//         break;
//       case 'sales_summary':
//         await _buildSalesSummary(pdf, dateFrom, dateTo);
//         break;
//       case 'customer_list':
//         await _buildCustomerList(pdf);
//         break;
//       case 'customer_individual':
//         await _buildCustomerIndividual(pdf, referenceId ?? '');
//         break;
//       case 'product_list':
//         await _buildProductList(pdf);
//         break;
//       case 'invoice':
//         await _buildInvoice(pdf, referenceId ?? '');
//         break;
//       default:
//         throw Exception('Unknown report type: $reportType');
//     }

//     return _saveToFile(pdf, reportType, referenceId);
//   }

//   // ── Save file ──────────────────────────────────────────────────────────────

//   static Future<File> _saveToFile(
//     pw.Document pdf,
//     String type,
//     String? refId,
//   ) async {
//     final dir = await getApplicationDocumentsDirectory();
//     final stamp = DateTime.now().millisecondsSinceEpoch;
//     final suffix = refId != null ? '_${refId.replaceAll('-', '')}' : '';
//     final file = File('${dir.path}/${type}${suffix}_$stamp.pdf');
//     await file.writeAsBytes(await pdf.save());
//     return file;
//   }

//   // ── Shared header ──────────────────────────────────────────────────────────

//   static pw.Widget _header(String title, String subtitle) {
//     return pw.Container(
//       width: double.infinity,
//       padding: const pw.EdgeInsets.all(20),
//       decoration: const pw.BoxDecoration(color: _primary),
//       child: pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Row(
//             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//             children: [
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(
//                     'BARICK PHARMACY',
//                     style: pw.TextStyle(
//                       color: _white,
//                       fontSize: 18,
//                       fontWeight: pw.FontWeight.bold,
//                     ),
//                   ),
//                   pw.SizedBox(height: 2),
//                   pw.Text(
//                     'Marketing Management System',
//                     style: pw.TextStyle(color: _accent, fontSize: 9),
//                   ),
//                 ],
//               ),
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.end,
//                 children: [
//                   pw.Text(
//                     _fmtDate(DateTime.now()),
//                     style: pw.TextStyle(color: _white, fontSize: 9),
//                   ),
//                   pw.Text(
//                     'Mbeya, Tanzania',
//                     style: pw.TextStyle(color: _accent, fontSize: 9),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           pw.SizedBox(height: 12),
//           pw.Container(height: 1, color: _accent),
//           pw.SizedBox(height: 10),
//           pw.Text(
//             title,
//             style: pw.TextStyle(
//               color: _white,
//               fontSize: 16,
//               fontWeight: pw.FontWeight.bold,
//             ),
//           ),
//           pw.SizedBox(height: 2),
//           pw.Text(subtitle, style: pw.TextStyle(color: _accent, fontSize: 10)),
//         ],
//       ),
//     );
//   }

//   static pw.Widget _footer(pw.Context ctx) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//       decoration: const pw.BoxDecoration(
//         border: pw.Border(top: pw.BorderSide(color: _lightGrey)),
//       ),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//         children: [
//           pw.Text(
//             'Barick Pharmacy — Confidential',
//             style: pw.TextStyle(color: _grey, fontSize: 8),
//           ),
//           pw.Text(
//             'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
//             style: pw.TextStyle(color: _grey, fontSize: 8),
//           ),
//           pw.Text(
//             'Generated ${_fmtDate(DateTime.now())}',
//             style: pw.TextStyle(color: _grey, fontSize: 8),
//           ),
//         ],
//       ),
//     );
//   }

//   static pw.Widget _sectionTitle(String title) {
//     return pw.Container(
//       margin: const pw.EdgeInsets.only(top: 16, bottom: 6),
//       padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       decoration: const pw.BoxDecoration(color: _lightGrey),
//       child: pw.Text(
//         title,
//         style: pw.TextStyle(
//           fontSize: 10,
//           fontWeight: pw.FontWeight.bold,
//           color: _primary,
//         ),
//       ),
//     );
//   }

//   static pw.Widget _kpiRow(List<Map<String, String>> kpis) {
//     return pw.Row(
//       children: kpis
//           .map(
//             (k) => pw.Expanded(
//               child: pw.Container(
//                 margin: const pw.EdgeInsets.symmetric(horizontal: 4),
//                 padding: const pw.EdgeInsets.all(10),
//                 decoration: pw.BoxDecoration(
//                   border: pw.Border.all(color: _accent),
//                   borderRadius: pw.BorderRadius.circular(4),
//                 ),
//                 child: pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text(
//                       k['value']!,
//                       style: pw.TextStyle(
//                         fontSize: 18,
//                         fontWeight: pw.FontWeight.bold,
//                         color: _primary,
//                       ),
//                     ),
//                     pw.SizedBox(height: 2),
//                     pw.Text(
//                       k['label']!,
//                       style: pw.TextStyle(fontSize: 8, color: _grey),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           )
//           .toList(),
//     );
//   }

//   static pw.Widget _table({
//     required List<String> headers,
//     required List<List<String>> rows,
//     List<pw.FlexColumnWidth>? widths,
//   }) {
//     final cols =
//         widths ??
//         List.generate(headers.length, (_) => const pw.FlexColumnWidth(1));
//     return pw.Table(
//       columnWidths: {for (int i = 0; i < cols.length; i++) i: cols[i]},
//       border: pw.TableBorder.all(color: _lightGrey),
//       children: [
//         pw.TableRow(
//           decoration: const pw.BoxDecoration(color: _primary),
//           children: headers
//               .map(
//                 (h) => pw.Padding(
//                   padding: const pw.EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 5,
//                   ),
//                   child: pw.Text(
//                     h,
//                     style: pw.TextStyle(
//                       color: _white,
//                       fontSize: 8,
//                       fontWeight: pw.FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               )
//               .toList(),
//         ),
//         ...rows.asMap().entries.map((e) {
//           final isEven = e.key % 2 == 0;
//           return pw.TableRow(
//             decoration: pw.BoxDecoration(color: isEven ? _white : _lightGrey),
//             children: e.value
//                 .map(
//                   (cell) => pw.Padding(
//                     padding: const pw.EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     child: pw.Text(
//                       cell,
//                       style: pw.TextStyle(fontSize: 8, color: _black),
//                     ),
//                   ),
//                 )
//                 .toList(),
//           );
//         }),
//       ],
//     );
//   }

//   // ── Marketing Summary ──────────────────────────────────────────────────────

//   Future<void> _buildMarketingSummary(
//     pw.Document pdf,
//     String? from,
//     String? to,
//   ) async {
//     final visitDs = VisitMockDataSource();
//     final officerDs = OfficerMockDataSource();
//     final planDs = WeeklyPlanMockDataSource();

//     final visits = await visitDs.getAll();
//     final officers = (await officerDs.getAll()).items;
//     final plans = await planDs.getAll();

//     final reviewed = visits.where((v) => v.status == 'reviewed').length;
//     final approved = plans.where((p) => p.status == 'approved').length;
//     final compliance = plans.isEmpty ? 0.0 : (approved / plans.length * 100);
//     final activeOfficers = officers.where((o) => o.isActive).length;

//     final visitsByOfficer = <String, int>{};
//     for (final v in visits) {
//       visitsByOfficer[v.officerId] = (visitsByOfficer[v.officerId] ?? 0) + 1;
//     }

//     final period = (from != null && to != null) ? '$from to $to' : 'All time';

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: pw.EdgeInsets.zero,
//         header: (_) =>
//             _header('Marketing Performance Report', 'Period: $period'),
//         footer: _footer,
//         build: (ctx) => [
//           pw.Padding(
//             padding: const pw.EdgeInsets.all(24),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 _sectionTitle('KEY PERFORMANCE INDICATORS'),
//                 pw.SizedBox(height: 8),
//                 _kpiRow([
//                   {'value': '${visits.length}', 'label': 'Total Visits'},
//                   {'value': '$activeOfficers', 'label': 'Active Officers'},
//                   {
//                     'value': '${compliance.toStringAsFixed(1)}%',
//                     'label': 'Plan Compliance',
//                   },
//                   {'value': '$reviewed', 'label': 'Reviewed Visits'},
//                 ]),
//                 _sectionTitle('VISITS BY OFFICER'),
//                 pw.SizedBox(height: 4),
//                 _table(
//                   headers: ['Officer ID', 'Officer Name', 'Visits', 'Status'],
//                   widths: [
//                     const pw.FlexColumnWidth(1.5),
//                     const pw.FlexColumnWidth(2.5),
//                     const pw.FlexColumnWidth(1),
//                     const pw.FlexColumnWidth(1),
//                   ],
//                   rows: officers.map((o) {
//                     final count = visitsByOfficer[o.userId] ?? 0;
//                     return [
//                       o.userId,
//                       o.displayName,
//                       '$count',
//                       o.effectiveStatus.toUpperCase(),
//                     ];
//                   }).toList(),
//                 ),
//                 _sectionTitle('WEEKLY PLAN STATUS'),
//                 pw.SizedBox(height: 4),
//                 _table(
//                   headers: [
//                     'Plan ID',
//                     'Officer ID',
//                     'Week Start',
//                     'Week End',
//                     'Status',
//                   ],
//                   rows: plans
//                       .map(
//                         (p) => [
//                           p.id,
//                           p.officerId,
//                           _fmtDate(p.weekStart),
//                           _fmtDate(p.weekEnd),
//                           p.status.toUpperCase(),
//                         ],
//                       )
//                       .toList(),
//                 ),
//                 _sectionTitle('RECENT VISITS'),
//                 pw.SizedBox(height: 4),
//                 _table(
//                   headers: [
//                     'Visit ID',
//                     'Business',
//                     'Officer',
//                     'Date',
//                     'Status',
//                   ],
//                   widths: [
//                     const pw.FlexColumnWidth(1.2),
//                     const pw.FlexColumnWidth(2),
//                     const pw.FlexColumnWidth(1.2),
//                     const pw.FlexColumnWidth(1.5),
//                     const pw.FlexColumnWidth(1),
//                   ],
//                   rows: visits
//                       .take(10)
//                       .map(
//                         (v) => [
//                           v.id,
//                           v.businessName,
//                           v.officerId,
//                           _fmtDate(v.visitDate),
//                           v.status.toUpperCase(),
//                         ].map((e) => e ?? '—').toList(),
//                       )
//                       .toList(),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Sales Summary ──────────────────────────────────────────────────────────

//   Future<void> _buildSalesSummary(
//     pw.Document pdf,
//     String? from,
//     String? to,
//   ) async {
//     // ── Real order data from API ───────────────────────────
//     final orders = await _orderDataSource.getAll();

//     final paymentDs = PaymentMockDataSource();
//     final productDs = ProductMockDataSource();

//     final payments = await paymentDs.getAll();
//     final products = await productDs.getAll();

//     final totalRevenue = orders.fold<double>(0, (s, o) => s + o.total);
//     final avgOrder = orders.isEmpty ? 0.0 : totalRevenue / orders.length;
//     final confirmed = payments.where((p) => p.status == 'confirmed').length;
//     final byStatus = <String, int>{};
//     for (final o in orders) {
//       byStatus[o.status] = (byStatus[o.status] ?? 0) + 1;
//     }
//     final period = (from != null && to != null) ? '$from to $to' : 'All time';

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: pw.EdgeInsets.zero,
//         header: (_) => _header('Sales Performance Report', 'Period: $period'),
//         footer: _footer,
//         build: (ctx) => [
//           pw.Padding(
//             padding: const pw.EdgeInsets.all(24),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 _sectionTitle('KEY SALES INDICATORS'),
//                 pw.SizedBox(height: 8),
//                 _kpiRow([
//                   {'value': '${orders.length}', 'label': 'Total Orders'},
//                   {
//                     'value': 'TZS ${_fmtNum(totalRevenue)}',
//                     'label': 'Total Revenue',
//                   },
//                   {
//                     'value': 'TZS ${_fmtNum(avgOrder)}',
//                     'label': 'Avg Order Value',
//                   },
//                   {'value': '$confirmed', 'label': 'Confirmed Payments'},
//                 ]),
//                 _sectionTitle('ORDERS BY STATUS'),
//                 pw.SizedBox(height: 4),
//                 _table(
//                   headers: ['Status', 'Count', 'Percentage'],
//                   rows: byStatus.entries.map((e) {
//                     final pct =
//                         (e.value / orders.length * 100).toStringAsFixed(1);
//                     return [e.key.toUpperCase(), '${e.value}', '$pct%'];
//                   }).toList(),
//                 ),
//                 _sectionTitle('ALL ORDERS'),
//                 pw.SizedBox(height: 4),
//                 _table(
//                   headers: [
//                     'Order ID',
//                     'Customer',
//                     'Placed By',
//                     'Total (TZS)',
//                     'Payment Ref',
//                     'Status',
//                   ],
//                   widths: [
//                     const pw.FlexColumnWidth(1.2),
//                     const pw.FlexColumnWidth(1.5),
//                     const pw.FlexColumnWidth(1.5),
//                     const pw.FlexColumnWidth(1.2),
//                     const pw.FlexColumnWidth(1.8),
//                     const pw.FlexColumnWidth(1.2),
//                   ],
//                   rows: orders
//                       .map(
//                         (o) => [
//                           o.id,
//                           o.customerId,
//                           o.createdByName ?? '—',
//                           _fmtNum(o.total),
//                           o.paymentRef ?? '—',
//                           o.status.toUpperCase(),
//                         ],
//                       )
//                       .toList(),
//                 ),
//                 _sectionTitle('PAYMENT RECORDS'),
//                 pw.SizedBox(height: 4),
//                 _table(
//                   headers: [
//                     'Pay ID',
//                     'Order',
//                     'Amount (TZS)',
//                     'Provider',
//                     'Ref',
//                     'Status',
//                   ],
//                   widths: [
//                     const pw.FlexColumnWidth(1),
//                     const pw.FlexColumnWidth(1),
//                     const pw.FlexColumnWidth(1.5),
//                     const pw.FlexColumnWidth(1.5),
//                     const pw.FlexColumnWidth(2),
//                     const pw.FlexColumnWidth(1.2),
//                   ],
//                   rows: payments
//                       .map(
//                         (p) => [
//                           p.id,
//                           p.orderId,
//                           _fmtNum(p.amount),
//                           p.provider,
//                           p.transactionRef,
//                           p.status.toUpperCase(),
//                         ].map((e) => e ?? '—').toList(),
//                       )
//                       .toList(),
//                 ),
//                 _sectionTitle('PRODUCT CATALOGUE SUMMARY'),
//                 pw.SizedBox(height: 4),
//                 _table(
//                   headers: [
//                     'Product ID',
//                     'Name',
//                     'Price (TZS)',
//                     'Status',
//                     'Featured',
//                   ],
//                   widths: [
//                     const pw.FlexColumnWidth(1.2),
//                     const pw.FlexColumnWidth(2.5),
//                     const pw.FlexColumnWidth(1.5),
//                     const pw.FlexColumnWidth(1.2),
//                     const pw.FlexColumnWidth(1),
//                   ],
//                   rows: products
//                       .map(
//                         (p) => [
//                           p.id,
//                           p.name,
//                           _fmtNum(p.price),
//                           p.status.toUpperCase(),
//                           p.isFeatured ? 'YES' : 'No',
//                         ],
//                       )
//                       .toList(),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Customer List ──────────────────────────────────────────────────────────

//   Future<void> _buildCustomerList(pw.Document pdf) async {
//     final ds = CustomerMockDataSource();
//     final customers = (await ds.getAll()).items;

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: pw.EdgeInsets.zero,
//         header: (_) =>
//             _header('Customer Directory', 'All registered customers'),
//         footer: _footer,
//         build: (ctx) => [
//           pw.Padding(
//             padding: const pw.EdgeInsets.all(24),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 _sectionTitle('SUMMARY'),
//                 pw.SizedBox(height: 8),
//                 _kpiRow([
//                   {'value': '${customers.length}', 'label': 'Total Customers'},
//                   {
//                     'value':
//                         '${customers.where((c) => c.primaryContact != null).length}',
//                     'label': 'With Contact Person',
//                   },
//                   {
//                     'value': '${customers.where((c) => c.hasGps).length}',
//                     'label': 'GPS Captured',
//                   },
//                 ]),
//                 _sectionTitle('CUSTOMER PROFILES'),
//                 pw.SizedBox(height: 4),
//                 _table(
//                   headers: [
//                     'ID',
//                     'Name',
//                     'Type',
//                     'Phone',
//                     'City',
//                     'Officer ID',
//                   ],
//                   widths: [
//                     const pw.FlexColumnWidth(0.8),
//                     const pw.FlexColumnWidth(2),
//                     const pw.FlexColumnWidth(1),
//                     const pw.FlexColumnWidth(1.5),
//                     const pw.FlexColumnWidth(1.5),
//                     const pw.FlexColumnWidth(1),
//                   ],
//                   rows: customers
//                       .map(
//                         (c) => [
//                           c.id,
//                           c.name,
//                           c.customerType.toUpperCase(),
//                           c.phone ?? '—',
//                           c.city ?? '—',
//                           c.assignedOfficerId ?? '—',
//                         ],
//                       )
//                       .toList(),
//                 ),
//                 pw.SizedBox(height: 16),
//                 _sectionTitle('CONTACT PERSONS'),
//                 pw.SizedBox(height: 4),
//                 _table(
//                   headers: ['Customer Name', 'Contact Person', 'Contact Phone'],
//                   widths: [
//                     const pw.FlexColumnWidth(2.5),
//                     const pw.FlexColumnWidth(2),
//                     const pw.FlexColumnWidth(1.5),
//                   ],
//                   rows: customers
//                       .where((c) => c.primaryContact != null)
//                       .map(
//                         (c) => [
//                           c.name,
//                           c.primaryContact!.name,
//                           c.primaryContact!.phone ?? '—',
//                         ],
//                       )
//                       .toList(),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Individual Customer ────────────────────────────────────────────────────

//   Future<void> _buildCustomerIndividual(
//     pw.Document pdf,
//     String customerId,
//   ) async {
//     final customerDs = CustomerMockDataSource();
//     final visitDs = VisitMockDataSource();

//     final customers = (await customerDs.getAll()).items;
//     final customer = customers.firstWhere(
//       (c) => c.id == customerId,
//       orElse: () => customers.first,
//     );
//     final visits = (await visitDs.getAll())
//         .where((v) => v.customerId == customerId)
//         .toList();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: pw.EdgeInsets.zero,
//         header: (_) => _header('Customer Profile', customer.name),
//         footer: _footer,
//         build: (ctx) => [
//           pw.Padding(
//             padding: const pw.EdgeInsets.all(24),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 _sectionTitle('CUSTOMER INFORMATION'),
//                 pw.SizedBox(height: 8),
//                 _infoGrid([
//                   ['Name', customer.name],
//                   ['Customer Type', customer.customerType.toUpperCase()],
//                   ['Tier', customer.tier],
//                   ['Status', customer.status.toUpperCase()],
//                   ['Phone', customer.phone ?? '—'],
//                   ['Alt Phone', customer.altPhone ?? '—'],
//                   ['Email', customer.email ?? '—'],
//                   ['WhatsApp', customer.whatsappNumber ?? '—'],
//                   ['Address', customer.address ?? '—'],
//                   ['City', customer.city ?? '—'],
//                   ['County', customer.county ?? '—'],
//                   ['Assigned Officer', customer.assignedOfficerId ?? '—'],
//                   [
//                     'GPS Coordinates',
//                     customer.hasGps
//                         ? '${customer.latitude}, ${customer.longitude}'
//                         : '—',
//                   ],
//                   [
//                     'Created',
//                     customer.createdAt != null
//                         ? _fmtDate(customer.createdAt!)
//                         : '—',
//                   ],
//                 ]),
//                 if (customer.primaryContact != null) ...[
//                   _sectionTitle('PRIMARY CONTACT'),
//                   pw.SizedBox(height: 4),
//                   _infoGrid([
//                     ['Name', customer.primaryContact!.name],
//                     ['Role', customer.primaryContact!.role ?? '—'],
//                     ['Phone', customer.primaryContact!.phone ?? '—'],
//                     ['Email', customer.primaryContact!.email ?? '—'],
//                   ]),
//                 ],
//                 _sectionTitle('VISIT HISTORY (${visits.length} visits)'),
//                 pw.SizedBox(height: 4),
//                 if (visits.isEmpty)
//                   pw.Text(
//                     'No visits recorded for this customer.',
//                     style: pw.TextStyle(color: _grey, fontSize: 9),
//                   )
//                 else
//                   _table(
//                     headers: [
//                       'Visit ID',
//                       'Date',
//                       'Officer',
//                       'Summary',
//                       'Status',
//                     ],
//                     widths: [
//                       const pw.FlexColumnWidth(1),
//                       const pw.FlexColumnWidth(1.5),
//                       const pw.FlexColumnWidth(1.2),
//                       const pw.FlexColumnWidth(3),
//                       const pw.FlexColumnWidth(1),
//                     ],
//                     rows: visits
//                         .map(
//                           (v) => [
//                             v.id,
//                             _fmtDate(v.visitDate),
//                             v.officerId,
//                             v.discussionSummary ?? v.notes ?? '—',
//                             v.status.toUpperCase(),
//                           ],
//                         )
//                         .toList(),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Product List ───────────────────────────────────────────────────────────

//   Future<void> _buildProductList(pw.Document pdf) async {
//     final ds = ProductMockDataSource();
//     final products = await ds.getAll();

//     final active = products.where((p) => p.status == 'active').length;
//     final featured = products.where((p) => p.isFeatured).length;
//     final archived = products.where((p) => p.status == 'archived').length;
//     final totalQty = products.fold<int>(
//       0,
//       (s, p) => s + (p.quantityAvailable ?? 0),
//     );

//     final available = products.where((p) => p.isAvailable).toList();
//     final unavailable = products.where((p) => !p.isAvailable).toList();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: pw.EdgeInsets.zero,
//         header: (_) => _header(
//           'Product Catalogue',
//           'Pharmaceutical stock register with batch & expiry data',
//         ),
//         footer: _footer,
//         build: (ctx) => [
//           pw.Padding(
//             padding: const pw.EdgeInsets.fromLTRB(24, 24, 24, 0),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 _sectionTitle('CATALOGUE OVERVIEW'),
//                 pw.SizedBox(height: 8),
//                 _kpiRow([
//                   {'value': '${products.length}', 'label': 'Total SKUs'},
//                   {'value': '$active', 'label': 'Active'},
//                   {'value': '$featured', 'label': 'Featured'},
//                   {'value': '$archived', 'label': 'Archived'},
//                   {'value': '$totalQty', 'label': 'Total Units'},
//                 ]),
//                 pw.SizedBox(height: 20),
//                 _sectionTitle('AVAILABLE STOCK (${available.length})'),
//                 pw.SizedBox(height: 6),
//                 _productTable(available),
//                 pw.SizedBox(height: 20),
//                 if (unavailable.isNotEmpty) ...[
//                   _sectionTitle(
//                     'UNAVAILABLE / OUT OF STOCK (${unavailable.length})',
//                   ),
//                   pw.SizedBox(height: 6),
//                   _productTable(unavailable),
//                   pw.SizedBox(height: 20),
//                 ],
//                 () {
//                   final now = DateTime.now();
//                   final soon = products
//                       .where(
//                         (p) =>
//                             p.expiryDate != null &&
//                             p.expiryDate!.difference(now).inDays <= 365,
//                       )
//                       .toList()
//                     ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
//                   if (soon.isEmpty) return pw.SizedBox();
//                   return pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       _sectionTitle(
//                         '⚠  EXPIRY ALERT — WITHIN 12 MONTHS (${soon.length})',
//                       ),
//                       pw.SizedBox(height: 6),
//                       _productTable(soon),
//                       pw.SizedBox(height: 20),
//                     ],
//                   );
//                 }(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   static pw.Widget _productTable(List<dynamic> products) {
//     return _table(
//       headers: [
//         '#',
//         'Product Name',
//         'Pack Size',
//         'Batch No.',
//         'Expiry Date',
//         'Price (TZS)',
//         'Qty',
//         'Status',
//       ],
//       widths: [
//         const pw.FlexColumnWidth(0.4),
//         const pw.FlexColumnWidth(2.6),
//         const pw.FlexColumnWidth(1.2),
//         const pw.FlexColumnWidth(1.2),
//         const pw.FlexColumnWidth(1.0),
//         const pw.FlexColumnWidth(1.1),
//         const pw.FlexColumnWidth(0.6),
//         const pw.FlexColumnWidth(0.9),
//       ],
//       rows: products.asMap().entries.map((e) {
//         final i = e.key;
//         final p = e.value;
//         final expiry = p.expiryDate;
//         final expiryStr = expiry != null
//             ? '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}'
//             : '—';
//         final isExpiringSoon =
//             expiry != null && expiry.difference(DateTime.now()).inDays <= 180;
//         return <String>[
//           '${i + 1}',
//           p.name,
//           p.packSize ?? '—',
//           p.batchNumber ?? '—',
//           isExpiringSoon ? '⚠ $expiryStr' : expiryStr,
//           _fmtNum(p.price),
//           p.quantityAvailable?.toString() ?? '—',
//           p.status.toUpperCase(),
//         ];
//       }).toList(),
//     );
//   }

//   // ── Invoice ────────────────────────────────────────────────────────────────

//   Future<void> _buildInvoice(pw.Document pdf, String orderId) async {
//     // ── Real order data from API ───────────────────────────
//     OrderModel order;
//     try {
//       order = await _orderDataSource.getById(orderId);
//     } catch (_) {
//       // Fallback: fetch all and find by id
//       final all = await _orderDataSource.getAll();
//       final match = all.where((o) => o.id == orderId).toList();
//       if (match.isEmpty) throw Exception('Order $orderId not found');
//       order = match.first;
//     }

//     final customerDs = CustomerMockDataSource();
//     final customers = (await customerDs.getAll()).items;
//     final customer = customers.firstWhere(
//       (c) => c.id == order.customerId,
//       orElse: () => customers.first,
//     );

//     final invoiceNumber =
//         'INV-${order.id.toUpperCase().replaceAll('-', '')}-${DateTime.now().year}';
//     final isPaid = order.paymentRef != null;

//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         margin: pw.EdgeInsets.zero,
//         build: (ctx) => pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Container(
//               width: double.infinity,
//               padding: const pw.EdgeInsets.all(24),
//               decoration: const pw.BoxDecoration(color: _primary),
//               child: pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text(
//                         'BARICK PHARMACY',
//                         style: pw.TextStyle(
//                           color: _white,
//                           fontSize: 20,
//                           fontWeight: pw.FontWeight.bold,
//                         ),
//                       ),
//                       pw.SizedBox(height: 4),
//                       pw.Text(
//                         'Marketing Management System',
//                         style: pw.TextStyle(color: _accent, fontSize: 9),
//                       ),
//                       pw.SizedBox(height: 4),
//                       pw.Text(
//                         'Mbeya, Tanzania',
//                         style: pw.TextStyle(color: _white, fontSize: 9),
//                       ),
//                       pw.Text(
//                         '+255 700 000 000',
//                         style: pw.TextStyle(color: _white, fontSize: 9),
//                       ),
//                     ],
//                   ),
//                   pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.end,
//                     children: [
//                       pw.Text(
//                         'INVOICE',
//                         style: pw.TextStyle(
//                           color: _white,
//                           fontSize: 28,
//                           fontWeight: pw.FontWeight.bold,
//                         ),
//                       ),
//                       pw.SizedBox(height: 4),
//                       pw.Text(
//                         invoiceNumber,
//                         style: pw.TextStyle(color: _accent, fontSize: 11),
//                       ),
//                       pw.SizedBox(height: 4),
//                       pw.Container(
//                         padding: const pw.EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 4,
//                         ),
//                         decoration: pw.BoxDecoration(
//                           color: isPaid ? _accent : _orange,
//                           borderRadius: pw.BorderRadius.circular(4),
//                         ),
//                         child: pw.Text(
//                           isPaid ? 'PAID' : 'UNPAID',
//                           style: pw.TextStyle(
//                             color: _white,
//                             fontSize: 11,
//                             fontWeight: pw.FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             pw.Padding(
//               padding: const pw.EdgeInsets.all(24),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Row(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Expanded(
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.start,
//                           children: [
//                             pw.Text(
//                               'BILL TO',
//                               style: pw.TextStyle(
//                                 fontSize: 8,
//                                 fontWeight: pw.FontWeight.bold,
//                                 color: _grey,
//                               ),
//                             ),
//                             pw.SizedBox(height: 4),
//                             pw.Text(
//                               customer.name,
//                               style: pw.TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: pw.FontWeight.bold,
//                               ),
//                             ),
//                             if (customer.primaryContact != null)
//                               pw.Text(
//                                 customer.primaryContact!.name,
//                                 style: pw.TextStyle(fontSize: 9),
//                               ),
//                             pw.Text(
//                               customer.phone ?? '—',
//                               style: pw.TextStyle(fontSize: 9),
//                             ),
//                             if (customer.address != null)
//                               pw.Text(
//                                 customer.address!,
//                                 style: pw.TextStyle(fontSize: 9),
//                               ),
//                           ],
//                         ),
//                       ),
//                       pw.Expanded(
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.end,
//                           children: [
//                             _invoiceMetaRow('Invoice No', invoiceNumber),
//                             _invoiceMetaRow(
//                               'Order ID',
//                               '#${order.id.toUpperCase()}',
//                             ),
//                             _invoiceMetaRow('Date', _fmtDate(order.createdAt)),
//                             if (order.createdByName != null &&
//                                 order.createdByName!.isNotEmpty)
//                               _invoiceMetaRow('Placed by', order.createdByName!),
//                             _invoiceMetaRow(
//                               'Payment Method',
//                               order.paymentRef != null
//                                   ? order.paymentRef!.split('-').first
//                                   : '—',
//                             ),
//                             if (order.paymentRef != null)
//                               _invoiceMetaRow('Payment Ref', order.paymentRef!),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),

//                   pw.SizedBox(height: 20),

//                   pw.Table(
//                     columnWidths: {
//                       0: const pw.FlexColumnWidth(3),
//                       1: const pw.FlexColumnWidth(1),
//                       2: const pw.FlexColumnWidth(1.5),
//                       3: const pw.FlexColumnWidth(1.5),
//                     },
//                     border: pw.TableBorder.all(color: _lightGrey),
//                     children: [
//                       pw.TableRow(
//                         decoration: const pw.BoxDecoration(color: _primary),
//                         children:
//                             ['PRODUCT', 'QTY', 'UNIT PRICE', 'SUBTOTAL']
//                                 .map(
//                                   (h) => pw.Padding(
//                                     padding: const pw.EdgeInsets.symmetric(
//                                       horizontal: 8,
//                                       vertical: 6,
//                                     ),
//                                     child: pw.Text(
//                                       h,
//                                       style: pw.TextStyle(
//                                         color: _white,
//                                         fontSize: 8,
//                                         fontWeight: pw.FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                                 .toList(),
//                       ),
//                       ...order.items.asMap().entries.map((e) {
//                         final isEven = e.key % 2 == 0;
//                         final item = e.value;
//                         return pw.TableRow(
//                           decoration: pw.BoxDecoration(
//                             color: isEven ? _white : _lightGrey,
//                           ),
//                           children: [
//                             pw.Padding(
//                               padding: const pw.EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 5,
//                               ),
//                               child: pw.Text(
//                                 item['name']?.toString() ?? '—',
//                                 style: pw.TextStyle(fontSize: 9),
//                               ),
//                             ),
//                             pw.Padding(
//                               padding: const pw.EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 5,
//                               ),
//                               child: pw.Text(
//                                 '${item['qty'] ?? 0}',
//                                 style: pw.TextStyle(fontSize: 9),
//                               ),
//                             ),
//                             pw.Padding(
//                               padding: const pw.EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 5,
//                               ),
//                               child: pw.Text(
//                                 'TZS ${_fmtNum((item['unitPrice'] as num?)?.toDouble() ?? 0)}',
//                                 style: pw.TextStyle(fontSize: 9),
//                               ),
//                             ),
//                             pw.Padding(
//                               padding: const pw.EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 5,
//                               ),
//                               child: pw.Text(
//                                 'TZS ${_fmtNum((item['subtotal'] as num?)?.toDouble() ?? 0)}',
//                                 style: pw.TextStyle(
//                                   fontSize: 9,
//                                   fontWeight: pw.FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         );
//                       }),
//                     ],
//                   ),

//                   pw.SizedBox(height: 8),

//                   pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.end,
//                     children: [
//                       pw.Container(
//                         width: 240,
//                         padding: const pw.EdgeInsets.all(12),
//                         decoration: const pw.BoxDecoration(color: _lightGrey),
//                         child: pw.Column(
//                           children: [
//                             _totalRow('Subtotal', _fmtNum(order.total)),
//                             _totalRow('Tax (0%)', '0.00'),
//                             pw.Divider(),
//                             _totalRow(
//                               'TOTAL',
//                               'TZS ${_fmtNum(order.total)}',
//                               bold: true,
//                               big: true,
//                             ),
//                             if (isPaid) ...[
//                               pw.SizedBox(height: 4),
//                               _totalRow(
//                                 'Amount Paid',
//                                 'TZS ${_fmtNum(order.total)}',
//                                 color: _secondary,
//                               ),
//                               _totalRow(
//                                 'Balance Due',
//                                 'TZS 0.00',
//                                 bold: true,
//                                 color: _secondary,
//                               ),
//                             ] else ...[
//                               pw.SizedBox(height: 4),
//                               _totalRow(
//                                 'Balance Due',
//                                 'TZS ${_fmtNum(order.total)}',
//                                 bold: true,
//                                 color: _red,
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),

//                   pw.SizedBox(height: 24),

//                   pw.Container(
//                     width: double.infinity,
//                     padding: const pw.EdgeInsets.all(12),
//                     decoration: pw.BoxDecoration(
//                       border: pw.Border.all(color: _accent),
//                       borderRadius: pw.BorderRadius.circular(4),
//                     ),
//                     child: pw.Text(
//                       isPaid
//                           ? 'Payment confirmed via ${order.paymentRef}. Thank you for your business!'
//                           : 'Payment pending. Please complete payment via M-Pesa or Airtel Money.',
//                       style: pw.TextStyle(fontSize: 9, color: _grey),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             pw.Expanded(child: pw.SizedBox()),
//             _footer(ctx),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Shared small widgets ───────────────────────────────────────────────────

//   static pw.Widget _infoGrid(List<List<String>> rows) {
//     return pw.Table(
//       columnWidths: {
//         0: const pw.FlexColumnWidth(1.5),
//         1: const pw.FlexColumnWidth(3),
//       },
//       children: rows
//           .map(
//             (r) => pw.TableRow(
//               children: [
//                 pw.Padding(
//                   padding: const pw.EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 3,
//                   ),
//                   child: pw.Text(
//                     r[0],
//                     style: pw.TextStyle(
//                       fontSize: 9,
//                       fontWeight: pw.FontWeight.bold,
//                       color: _grey,
//                     ),
//                   ),
//                 ),
//                 pw.Padding(
//                   padding: const pw.EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 3,
//                   ),
//                   child: pw.Text(r[1], style: pw.TextStyle(fontSize: 9)),
//                 ),
//               ],
//             ),
//           )
//           .toList(),
//     );
//   }

//   static pw.Widget _invoiceMetaRow(String label, String value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.only(bottom: 3),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.end,
//         children: [
//           pw.Text('$label: ', style: pw.TextStyle(fontSize: 9, color: _grey)),
//           pw.Text(
//             value,
//             style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }

//   static pw.Widget _totalRow(
//     String label,
//     String value, {
//     bool bold = false,
//     bool big = false,
//     PdfColor? color,
//   }) {
//     final style = pw.TextStyle(
//       fontSize: big ? 11 : 9,
//       fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
//       color: color ?? _black,
//     );
//     return pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//       children: [
//         pw.Text(label, style: style),
//         pw.Text(value, style: style),
//       ],
//     );
//   }

//   // ── Formatters ─────────────────────────────────────────────────────────────

//   static String _fmtDate(DateTime d) =>
//       '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

//   static String _fmtNum(double n) {
//     final parts = n.toStringAsFixed(2).split('.');
//     final intPart = parts[0].replaceAllMapped(
//       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
//       (m) => '${m[1]},',
//     );
//     return '$intPart.${parts[1]}';
//   }
// }