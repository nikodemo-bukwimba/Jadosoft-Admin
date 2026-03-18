// report_export_cubit.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/services/report_export_service.dart';
import '../../domain/models/request_export_request.dart';
import 'report_export_state.dart';

class ReportExportCubit extends Cubit<ReportExportState> {
  final ReportExportService _service;
  Timer? _pollTimer;

  ReportExportCubit({required ReportExportService service})
      : _service = service,
        super(const ReportExportState());

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  // ── Public export triggers ─────────────────────────────────────────────────

  Future<void> exportMarketingSummary(
          {required String format, String? dateFrom, String? dateTo}) =>
      _startExport(
        reportType: 'marketing_summary',
        format: format,
        loadingFlag: 'marketing',
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

  Future<void> exportSalesSummary(
          {required String format, String? dateFrom, String? dateTo}) =>
      _startExport(
        reportType: 'sales_summary',
        format: format,
        loadingFlag: 'sales',
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

  Future<void> exportCustomerList({required String format}) =>
      _startExport(
          reportType: 'customer_list',
          format: format,
          loadingFlag: 'customer_list');

  Future<void> exportCustomerIndividual(
          {required String customerId, required String format}) =>
      _startExport(
        reportType: 'customer_individual',
        format: format,
        loadingFlag: 'customer_individual',
        referenceId: customerId,
      );

  Future<void> exportProductList({required String format}) =>
      _startExport(
          reportType: 'product_list',
          format: format,
          loadingFlag: 'product_list');

  Future<void> exportInvoice({required String orderId}) =>
      _startExport(
        reportType: 'invoice',
        format: 'pdf',
        loadingFlag: 'invoice',
        referenceId: orderId,
      );

  void setInvoiceOrderId(String value) =>
      emit(state.copyWith(invoiceOrderId: value, invoiceError: null));

  // ── Core export flow ───────────────────────────────────────────────────────

  Future<void> _startExport({
    required String reportType,
    required String format,
    required String loadingFlag,
    String? dateFrom,
    String? dateTo,
    String? referenceId,
  }) async {
    _setLoadingFlag(loadingFlag, true);

    final request = RequestExportRequest(
      reportType: reportType,
      format: format,
      dateRange: (dateFrom != null && dateTo != null)
          ? {'from': dateFrom, 'to': dateTo}
          : null,
      referenceId: referenceId,
    );

    final result = await _service.requestExport(request);
    result.fold(
      (failure) {
        _setLoadingFlag(loadingFlag, false);
        if (loadingFlag == 'invoice') {
          emit(state.copyWith(invoiceError: failure.message));
        }
      },
      (response) {
        final entry = ExportHistoryEntry(
          exportId: response.exportId,
          reportType: reportType,
          format: format,
          status: 'pending',
          requestedAt: response.createdAt,
        );
        final history = [entry, ...state.exportHistory].take(10).toList();
        emit(state.copyWith(
          activeExportId: response.exportId,
          exportHistory: history,
          lastSyncAt: DateTime.now(),
          // Clear any previous polling status so banner resets cleanly
          pollingStatus: null,
        ));
        _setLoadingFlag(loadingFlag, false);
        _startPolling(response.exportId);
      },
    );
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  void _startPolling(String exportId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final result = await _service.getExportStatus(exportId);
      result.fold(
        (_) {
          _pollTimer?.cancel();
          // Mark failed in history
          final history = state.exportHistory.map((e) {
            if (e.exportId == exportId) return e.copyWith(status: 'failed');
            return e;
          }).toList();
          emit(state.copyWith(
            activeExportId: null,
            pollingStatus: null,    // ← clear banner
            exportHistory: history,
          ));
        },
        (status) {
          final history = state.exportHistory.map((e) {
            if (e.exportId == exportId) return e.copyWith(status: status.status);
            return e;
          }).toList();

          if (status.status == 'ready' || status.status == 'failed') {
            _pollTimer?.cancel();
            emit(state.copyWith(
              activeExportId: null,   // ← stops banner
              pollingStatus: null,    // ← clears banner content
              exportHistory: history,
            ));
          } else {
            emit(state.copyWith(pollingStatus: status, exportHistory: history));
          }
        },
      );
    });
  }

  // ── Download + save ────────────────────────────────────────────────────────

  Future<void> downloadExport(String exportId) async {
    emit(state.copyWith(isDownloadExportLoading: true, downloadExportError: null));
    final result = await _service.downloadExport(exportId);
    result.fold(
      (f) => emit(state.copyWith(
          isDownloadExportLoading: false, downloadExportError: f.message)),
      (r) async {
        emit(state.copyWith(
            isDownloadExportLoading: false,
            downloadExportResult: r,
            lastSyncAt: DateTime.now()));

        final url = r.fileUrl;

        if (url.startsWith('/') || (url.length > 2 && url[1] == ':')) {
          // ── Local file (dev/mock) — let user choose what to do ────────────
          await _handleLocalFile(url, r.fileName);
        } else if (url.startsWith('http')) {
          // ── Remote URL (production) — open in browser ─────────────────────
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }

        emit(state.copyWith(lastDownloadedFileName: r.fileName));
      },
    );
  }

  Future<void> _handleLocalFile(String filePath, String fileName) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop: let user pick a save directory
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose where to save $fileName',
      );
      if (dir != null) {
        final dest = File('$dir${Platform.pathSeparator}$fileName');
        await file.copy(dest.path);
        // Open the saved file
        await OpenFile.open(dest.path);
        emit(state.copyWith(lastSavedPath: dest.path));
      }
    } else {
      // Mobile (Android/iOS): share sheet — user can save to Files, Drive, etc.
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, name: fileName, mimeType: 'application/pdf')],
          subject: fileName,
          text: 'Barick Pharmacy — $fileName',
        ),
      );
    }
  }

  // ── Legacy service methods (kept for compatibility) ────────────────────────

  Future<void> requestExport(RequestExportRequest request) async {
    emit(state.copyWith(
        isRequestExportLoading: true, requestExportError: null));
    final result = await _service.requestExport(request);
    result.fold(
      (f) => emit(state.copyWith(
          isRequestExportLoading: false, requestExportError: f.message)),
      (_) => emit(state.copyWith(
          isRequestExportLoading: false, lastSyncAt: DateTime.now())),
    );
  }

  Future<void> getExportStatus(String exportId) async {
    emit(state.copyWith(
        isGetExportStatusLoading: true, getExportStatusError: null));
    final result = await _service.getExportStatus(exportId);
    result.fold(
      (f) => emit(state.copyWith(
          isGetExportStatusLoading: false, getExportStatusError: f.message)),
      (r) => emit(state.copyWith(
          isGetExportStatusLoading: false,
          getExportStatusResult: r,
          lastSyncAt: DateTime.now())),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setLoadingFlag(String flag, bool value) {
    emit(state.copyWith(
      isMarketingSummaryLoading:
          flag == 'marketing' ? value : state.isMarketingSummaryLoading,
      isSalesSummaryLoading:
          flag == 'sales' ? value : state.isSalesSummaryLoading,
      isCustomerListLoading:
          flag == 'customer_list' ? value : state.isCustomerListLoading,
      isCustomerIndividualLoading:
          flag == 'customer_individual' ? value : state.isCustomerIndividualLoading,
      isProductListLoading:
          flag == 'product_list' ? value : state.isProductListLoading,
      isInvoiceLoading:
          flag == 'invoice' ? value : state.isInvoiceLoading,
    ));
  }
}