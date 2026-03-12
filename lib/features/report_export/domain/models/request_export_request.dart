class RequestExportRequest {
  final String reportType;
  final String format;
  final Map<String, String>? dateRange;
  final Map<String, dynamic>? filters;

  const RequestExportRequest({
    required this.reportType,
    required this.format,
    this.dateRange,
    this.filters,
  });

  Map<String, dynamic> toJson() => {
      'report_type': reportType,
      'format': format,
      'date_range': dateRange,
      'filters': filters,
  };
}
