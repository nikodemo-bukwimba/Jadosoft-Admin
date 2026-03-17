// request_export_request.dart
// ─────────────────────────────────────────────────────────────────────────────
// Request model for POST /exports
//
// reportType values:
//   marketing_summary   — visits, officers, plan compliance, daily reports
//   sales_summary       — orders, revenue, payments, products
//   customer_list       — all customer profiles
//   customer_individual — single customer profile + visit history
//   product_list        — all products with category + status
//   invoice             — per-order invoice PDF
//
// format values: pdf | excel  (invoice only supports pdf)
// ─────────────────────────────────────────────────────────────────────────────

class RequestExportRequest {
  final String reportType;
  final String format;
  final Map<String, String>? dateRange; // { from: 'YYYY-MM-DD', to: 'YYYY-MM-DD' }
  final Map<String, dynamic>? filters;  // e.g. { customer_id: 'cust-001' } for individual
  final String? referenceId;            // orderId for invoice, customerId for individual

  const RequestExportRequest({
    required this.reportType,
    required this.format,
    this.dateRange,
    this.filters,
    this.referenceId,
  });

  Map<String, dynamic> toJson() => {
    'report_type': reportType,
    'format': format,
    if (dateRange != null) 'date_range': dateRange,
    if (filters != null) 'filters': filters,
    if (referenceId != null) 'reference_id': referenceId,
  };
}