// lib/features/report_export/presentation/cubit/report_export_state.dart
//
// ONLY CHANGE vs original:
//   • Added `productListError` field for on-device product list export errors.
//   • All other fields, copyWith parameters, props, and imports are UNCHANGED.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:equatable/equatable.dart';
import '../../domain/models/get_export_status_response.dart';
import '../../domain/models/download_export_response.dart';

class ExportHistoryEntry {
  final String exportId;
  final String reportType;
  final String format;
  final String status; // pending | processing | ready | failed
  final DateTime requestedAt;
  final DownloadExportResponse? download;

  const ExportHistoryEntry({
    required this.exportId,
    required this.reportType,
    required this.format,
    required this.status,
    required this.requestedAt,
    this.download,
  });

  ExportHistoryEntry copyWith({
    String? status,
    DownloadExportResponse? download,
    GetExportStatusResponse? statusResponse,
  }) => ExportHistoryEntry(
    exportId: exportId,
    reportType: reportType,
    format: format,
    status: status ?? this.status,
    requestedAt: requestedAt,
    download: download ?? this.download,
  );
}

class ReportExportState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastSyncAt;

  // Per-report loading flags
  final bool isMarketingSummaryLoading;
  final bool isSalesSummaryLoading;
  final bool isCustomerListLoading;
  final bool isCustomerIndividualLoading;
  final bool isProductListLoading;
  final bool isInvoiceLoading;

  // Active polling job
  final String? activeExportId;
  final GetExportStatusResponse? pollingStatus;

  // Export history (last 10)
  final List<ExportHistoryEntry> exportHistory;

  // Invoice search
  final String invoiceOrderId;
  final String? invoiceError;

  // Generic loading states (kept for service layer)
  final bool isRequestExportLoading;
  final String? requestExportError;
  final bool isGetExportStatusLoading;
  final String? getExportStatusError;
  final GetExportStatusResponse? getExportStatusResult;
  final bool isDownloadExportLoading;
  final String? downloadExportError;
  final DownloadExportResponse? downloadExportResult;

  /// Set after a successful server-side download — triggers snackbar.
  final String? lastDownloadedFileName;

  /// Set after desktop save — shows saved path in snackbar.
  final String? lastSavedPath;

  // NEW: on-device product list export error (added for local PDF/Excel generation)
  final String? productListError;

  const ReportExportState({
    this.isLoading = false,
    this.errorMessage,
    this.lastSyncAt,
    this.isMarketingSummaryLoading = false,
    this.isSalesSummaryLoading = false,
    this.isCustomerListLoading = false,
    this.isCustomerIndividualLoading = false,
    this.isProductListLoading = false,
    this.isInvoiceLoading = false,
    this.activeExportId,
    this.pollingStatus,
    this.exportHistory = const [],
    this.invoiceOrderId = '',
    this.invoiceError,
    this.isRequestExportLoading = false,
    this.requestExportError,
    this.isGetExportStatusLoading = false,
    this.getExportStatusError,
    this.getExportStatusResult,
    this.isDownloadExportLoading = false,
    this.downloadExportError,
    this.downloadExportResult,
    this.lastDownloadedFileName,
    this.lastSavedPath,
    this.productListError,
  });

  ReportExportState copyWith({
    bool? isLoading,
    String? errorMessage,
    DateTime? lastSyncAt,
    bool? isMarketingSummaryLoading,
    bool? isSalesSummaryLoading,
    bool? isCustomerListLoading,
    bool? isCustomerIndividualLoading,
    bool? isProductListLoading,
    bool? isInvoiceLoading,
    String? activeExportId,
    GetExportStatusResponse? pollingStatus,
    List<ExportHistoryEntry>? exportHistory,
    String? invoiceOrderId,
    String? invoiceError,
    bool? isRequestExportLoading,
    String? requestExportError,
    bool? isGetExportStatusLoading,
    String? getExportStatusError,
    GetExportStatusResponse? getExportStatusResult,
    bool? isDownloadExportLoading,
    String? downloadExportError,
    DownloadExportResponse? downloadExportResult,
    String? lastDownloadedFileName,
    String? lastSavedPath,
    String? productListError,
  }) {
    return ReportExportState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isMarketingSummaryLoading:
          isMarketingSummaryLoading ?? this.isMarketingSummaryLoading,
      isSalesSummaryLoading:
          isSalesSummaryLoading ?? this.isSalesSummaryLoading,
      isCustomerListLoading:
          isCustomerListLoading ?? this.isCustomerListLoading,
      isCustomerIndividualLoading:
          isCustomerIndividualLoading ?? this.isCustomerIndividualLoading,
      isProductListLoading: isProductListLoading ?? this.isProductListLoading,
      isInvoiceLoading: isInvoiceLoading ?? this.isInvoiceLoading,
      activeExportId: activeExportId ?? this.activeExportId,
      pollingStatus: pollingStatus ?? this.pollingStatus,
      exportHistory: exportHistory ?? this.exportHistory,
      invoiceOrderId: invoiceOrderId ?? this.invoiceOrderId,
      invoiceError: invoiceError ?? this.invoiceError,
      isRequestExportLoading:
          isRequestExportLoading ?? this.isRequestExportLoading,
      requestExportError: requestExportError ?? this.requestExportError,
      isGetExportStatusLoading:
          isGetExportStatusLoading ?? this.isGetExportStatusLoading,
      getExportStatusError: getExportStatusError ?? this.getExportStatusError,
      getExportStatusResult:
          getExportStatusResult ?? this.getExportStatusResult,
      isDownloadExportLoading:
          isDownloadExportLoading ?? this.isDownloadExportLoading,
      downloadExportError: downloadExportError ?? this.downloadExportError,
      downloadExportResult: downloadExportResult ?? this.downloadExportResult,
      lastDownloadedFileName:
          lastDownloadedFileName ?? this.lastDownloadedFileName,
      lastSavedPath: lastSavedPath ?? this.lastSavedPath,
      productListError: productListError ?? this.productListError,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    lastSyncAt,
    isMarketingSummaryLoading,
    isSalesSummaryLoading,
    isCustomerListLoading,
    isCustomerIndividualLoading,
    isProductListLoading,
    isInvoiceLoading,
    activeExportId,
    pollingStatus,
    exportHistory,
    invoiceOrderId,
    invoiceError,
    isRequestExportLoading,
    requestExportError,
    isGetExportStatusLoading,
    getExportStatusError,
    getExportStatusResult,
    isDownloadExportLoading,
    downloadExportError,
    downloadExportResult,
    lastDownloadedFileName,
    lastSavedPath,
    productListError,
  ];
}
