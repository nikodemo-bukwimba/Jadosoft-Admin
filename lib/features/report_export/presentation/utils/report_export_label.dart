// lib/features/report_export/presentation/utils/report_export_label.dart
//
// Pure helper — no Flutter dependency.
// Shared by ReportExportHistoryList and ReportExportPage.

String reportExportLabel(String type) => switch (type) {
  'marketing_summary'   => 'Marketing Summary',
  'sales_summary'       => 'Sales Summary',
  'customer_list'       => 'Customer List',
  'customer_individual' => 'Customer Profile',
  'product_list'        => 'Product List',
  'invoice'             => 'Invoice',
  _                     => type,
};