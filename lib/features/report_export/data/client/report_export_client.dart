// report_export_client.dart
// ─────────────────────────────────────────────────────────────────────────────
// Abstract client interface for the Report Export feature.
// Two implementations exist:
//   • ReportExportMockClient  — in-memory, used during development
//   • ReportExportClientImpl  — real Dio HTTP client, used in production
//
// To switch to production:
//   In injection_container.dart replace:
//     sl.registerLazySingleton<ReportExportClient>(() => ReportExportMockClient())
//   with:
//     sl.registerLazySingleton<ReportExportClient>(
//       () => ReportExportClientImpl(dio: sl()))
// ─────────────────────────────────────────────────────────────────────────────

import '../../domain/models/request_export_request.dart';
import '../../domain/models/request_export_response.dart';
import '../../domain/models/get_export_status_response.dart';
import '../../domain/models/download_export_response.dart';

abstract class ReportExportClient {
  /// Request an async export job. Returns exportId + initial status.
  Future<RequestExportResponse> requestExport(RequestExportRequest request);

  /// Poll export job status. Poll until status == 'ready' or 'failed'.
  Future<GetExportStatusResponse> getExportStatus(String exportId);

  /// Download the completed export. Returns download URL + metadata.
  Future<DownloadExportResponse> downloadExport(String exportId);
}