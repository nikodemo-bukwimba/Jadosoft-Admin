class DownloadExportResponse {
  final String fileUrl;
  final String fileName;
  final String contentType;
  final int fileSize;

  const DownloadExportResponse({
    required this.fileUrl,
    required this.fileName,
    required this.contentType,
    required this.fileSize,
  });

  factory DownloadExportResponse.fromJson(Map<String, dynamic> json) {
    return DownloadExportResponse(
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      contentType: json['content_type'] as String,
      fileSize: json['file_size'] as int,
    );
  }
}
