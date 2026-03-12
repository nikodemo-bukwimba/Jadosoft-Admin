import 'package:equatable/equatable.dart';
import '../../domain/models/get_export_status_response.dart';
import '../../domain/models/download_export_response.dart';

class ReportExportState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastSyncAt;
  final bool isRequestExportLoading;
  final String? requestExportError;
  final bool isGetExportStatusLoading;
  final String? getExportStatusError;
  final GetExportStatusResponse? getExportStatusResult;
  final bool isDownloadExportLoading;
  final String? downloadExportError;
  final DownloadExportResponse? downloadExportResult;

  const ReportExportState({
    this.isLoading = false,
    this.errorMessage,
    this.lastSyncAt,
    this.isRequestExportLoading = false,
    this.requestExportError,
    this.isGetExportStatusLoading = false,
    this.getExportStatusError,
    this.getExportStatusResult,
    this.isDownloadExportLoading = false,
    this.downloadExportError,
    this.downloadExportResult,
  });

  ReportExportState copyWith({
    bool? isLoading,
    String? errorMessage,
    DateTime? lastSyncAt,
    bool? isRequestExportLoading,
    String? requestExportError,
    bool? isGetExportStatusLoading,
    String? getExportStatusError,
    GetExportStatusResponse? getExportStatusResult,
    bool? isDownloadExportLoading,
    String? downloadExportError,
    DownloadExportResponse? downloadExportResult,
  }) {
    return ReportExportState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isRequestExportLoading: isRequestExportLoading ?? this.isRequestExportLoading,
      requestExportError: requestExportError ?? this.requestExportError,
      isGetExportStatusLoading: isGetExportStatusLoading ?? this.isGetExportStatusLoading,
      getExportStatusError: getExportStatusError ?? this.getExportStatusError,
      getExportStatusResult: getExportStatusResult ?? this.getExportStatusResult,
      isDownloadExportLoading: isDownloadExportLoading ?? this.isDownloadExportLoading,
      downloadExportError: downloadExportError ?? this.downloadExportError,
      downloadExportResult: downloadExportResult ?? this.downloadExportResult,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, lastSyncAt, isRequestExportLoading, requestExportError, isGetExportStatusLoading, getExportStatusError, getExportStatusResult, isDownloadExportLoading, downloadExportError, downloadExportResult];
}
