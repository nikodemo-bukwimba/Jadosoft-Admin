// report_export_mock_client.dart
// ─────────────────────────────────────────────────────────────────────────────
// In-memory mock implementation of ReportExportClient.
// Simulates async export flow: pending → processing → ready.
// Generates realistic export records for all 6 report types:
//   marketing_summary, sales_summary, customer_list,
//   customer_individual, product_list, invoice
//
// No real files are generated — downloadUrl is a placeholder that the
// real client impl will replace with an actual signed URL from Laravel.
// ─────────────────────────────────────────────────────────────────────────────

import 'report_export_client.dart';
import '../../domain/models/request_export_request.dart';
import '../../domain/models/request_export_response.dart';
import '../../domain/models/get_export_status_response.dart';
import '../../domain/models/download_export_response.dart';

class ReportExportMockClient implements ReportExportClient {
  // Track in-progress jobs: exportId → status
  final Map<String, _MockJob> _jobs = {};

  @override
  Future<RequestExportResponse> requestExport(RequestExportRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final id = 'exp-${DateTime.now().millisecondsSinceEpoch}';
    _jobs[id] = _MockJob(
      reportType: request.reportType,
      format: request.format,
      createdAt: DateTime.now(),
    );
    return RequestExportResponse(
      exportId: id,
      status: 'pending',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<GetExportStatusResponse> getExportStatus(String exportId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final job = _jobs[exportId];
    if (job == null) {
      return GetExportStatusResponse(
        exportId: exportId,
        status: 'failed',
        progress: 0,
        error: 'Export job not found',
      );
    }
    // Simulate progression: pending → processing → ready
    final elapsed = DateTime.now().difference(job.createdAt).inSeconds;
    if (elapsed < 2) {
      return GetExportStatusResponse(exportId: exportId, status: 'pending', progress: 10);
    } else if (elapsed < 4) {
      return GetExportStatusResponse(exportId: exportId, status: 'processing', progress: 60);
    } else {
      job.ready = true;
      return GetExportStatusResponse(
        exportId: exportId,
        status: 'ready',
        progress: 100,
        downloadUrl: 'mock://exports/$exportId/download',
      );
    }
  }

  @override
  Future<DownloadExportResponse> downloadExport(String exportId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final job = _jobs[exportId];
    if (job == null || !job.ready) {
      throw Exception('Export not ready or not found');
    }
    final ext = job.format == 'excel' ? 'xlsx' : 'pdf';
    final name = '${job.reportType}_${_dateStamp()}_barick.$ext';
    final size = job.format == 'excel' ? 48320 : 123456;
    final mime = job.format == 'excel'
        ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        : 'application/pdf';
    return DownloadExportResponse(
      fileUrl: 'mock://exports/$exportId/download',
      fileName: name,
      contentType: mime,
      fileSize: size,
    );
  }

  String _dateStamp() {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }
}

class _MockJob {
  final String reportType;
  final String format;
  final DateTime createdAt;
  bool ready = false;
  _MockJob({required this.reportType, required this.format, required this.createdAt});
}