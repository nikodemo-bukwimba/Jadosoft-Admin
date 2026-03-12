class GetExportStatusResponse {
  final String exportId;
  final String status;
  final int? progress;
  final String? downloadUrl;
  final String? error;

  const GetExportStatusResponse({
    required this.exportId,
    required this.status,
    this.progress,
    this.downloadUrl,
    this.error,
  });

  factory GetExportStatusResponse.fromJson(Map<String, dynamic> json) {
    return GetExportStatusResponse(
      exportId: json['export_id'] as String,
      status: json['status'] as String,
      progress: json['progress'] as int?,
      downloadUrl: json['download_url'] as String?,
      error: json['error'] as String?,
    );
  }
}
