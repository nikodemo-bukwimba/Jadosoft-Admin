class RequestExportResponse {
  final String exportId;
  final String status;
  final DateTime createdAt;

  const RequestExportResponse({
    required this.exportId,
    required this.status,
    required this.createdAt,
  });

  factory RequestExportResponse.fromJson(Map<String, dynamic> json) {
    return RequestExportResponse(
      exportId: json['export_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
