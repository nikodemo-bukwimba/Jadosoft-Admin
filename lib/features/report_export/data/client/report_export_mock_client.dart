// report_export_mock_client.dart
// ─────────────────────────────────────────────────────────────────────────────
// Development client that generates REAL PDF files on-device from mock data.
// Uses ReportPdfGenerator to produce actual formatted PDFs that can be opened.
//
// When the Laravel API is ready, swap this for ReportExportClientImpl —
// one line change in injection_container.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'report_export_client.dart';
import '../../domain/models/request_export_request.dart';
import '../../domain/models/request_export_response.dart';
import '../../domain/models/get_export_status_response.dart';
import '../../domain/models/download_export_response.dart';
import '../../domain/services/report_pdf_generator.dart';

class ReportExportMockClient implements ReportExportClient {
  final Map<String, _MockJob> _jobs = {};

  @override
  Future<RequestExportResponse> requestExport(
    RequestExportRequest request,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final id = 'exp-${DateTime.now().millisecondsSinceEpoch}';
    final job = _MockJob(
      reportType: request.reportType,
      format: request.format,
      referenceId: request.referenceId,
      dateFrom: request.dateRange?['from'],
      dateTo: request.dateRange?['to'],
      createdAt: DateTime.now(),
    );
    // Kick off real PDF generation immediately
    job.generateFuture =
        ReportPdfGenerator.generate(
              reportType: request.reportType,
              referenceId: request.referenceId,
              dateFrom: request.dateRange?['from'],
              dateTo: request.dateRange?['to'],
            )
            .then((file) {
              job.file = file;
              return file;
            })
            .catchError((e) {
              job.failed = true;
              job.error = e.toString();
            });
    _jobs[id] = job;
    return RequestExportResponse(
      exportId: id,
      status: 'pending',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<GetExportStatusResponse> getExportStatus(String exportId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final job = _jobs[exportId];
    if (job == null) {
      return GetExportStatusResponse(
        exportId: exportId,
        status: 'failed',
        progress: 0,
        error: 'Export job not found',
      );
    }
    if (job.file != null) {
      return GetExportStatusResponse(
        exportId: exportId,
        status: 'ready',
        progress: 100,
        downloadUrl: job.file!.path,
      );
    }
    if (job.failed) {
      return GetExportStatusResponse(
        exportId: exportId,
        status: 'failed',
        progress: 0,
        error: job.error ?? 'Generation failed',
      );
    }
    // Still generating — show progress
    final elapsed = DateTime.now().difference(job.createdAt).inMilliseconds;
    final progress = (elapsed / 3000 * 80).clamp(10, 80).toInt();
    return GetExportStatusResponse(
      exportId: exportId,
      status: 'processing',
      progress: progress,
    );
  }

  @override
  Future<DownloadExportResponse> downloadExport(String exportId) async {
    final job = _jobs[exportId];
    if (job == null || job.file == null) {
      throw Exception('Export not ready — poll getExportStatus first');
    }
    final n = DateTime.now();
    final stamp =
        '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
    final name = '${job.reportType}_barick_$stamp.pdf';
    final size = await job.file!.length();
    return DownloadExportResponse(
      fileUrl: job.file!.path,
      fileName: name,
      contentType: 'application/pdf',
      fileSize: size,
    );
  }
}

class _MockJob {
  final String reportType;
  final String format;
  final String? referenceId;
  final String? dateFrom;
  final String? dateTo;
  final DateTime createdAt;
  Future<dynamic>? generateFuture;
  dynamic file; // dart:io File once ready
  bool failed = false;
  String? error;

  _MockJob({
    required this.reportType,
    required this.format,
    this.referenceId,
    this.dateFrom,
    this.dateTo,
    required this.createdAt,
  });
}
