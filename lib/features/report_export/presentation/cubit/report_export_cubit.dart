import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/services/report_export_service.dart';
import 'report_export_state.dart';
import '../../domain/models/request_export_request.dart';

class ReportExportCubit extends Cubit<ReportExportState> {
  final ReportExportService _service;

  ReportExportCubit({required ReportExportService service})
      : _service = service,
        super(const ReportExportState());

  Future<void> requestExport(RequestExportRequest request) async {
    emit(state.copyWith(isRequestExportLoading: true, requestExportError: null));
    final result = await _service.requestExport(request);
    result.fold(
      (failure) => emit(state.copyWith(isRequestExportLoading: false, requestExportError: failure.toString())),
      (result) {
        emit(state.copyWith(isRequestExportLoading: false, lastSyncAt: DateTime.now()));
      },
    );
  }
  Future<void> getExportStatus(String exportId) async {
    emit(state.copyWith(isGetExportStatusLoading: true, getExportStatusError: null));
    final result = await _service.getExportStatus(exportId);
    result.fold(
      (failure) => emit(state.copyWith(isGetExportStatusLoading: false, getExportStatusError: failure.toString())),
      (result) {
        emit(state.copyWith(isGetExportStatusLoading: false, getExportStatusResult: result, lastSyncAt: DateTime.now()));
      },
    );
  }
  Future<void> downloadExport(String exportId) async {
    emit(state.copyWith(isDownloadExportLoading: true, downloadExportError: null));
    final result = await _service.downloadExport(exportId);
    result.fold(
      (failure) => emit(state.copyWith(isDownloadExportLoading: false, downloadExportError: failure.toString())),
      (result) {
        emit(state.copyWith(isDownloadExportLoading: false, downloadExportResult: result, lastSyncAt: DateTime.now()));
      },
    );
  }
}
