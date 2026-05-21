// lib/features/report_export/presentation/cubit/report_export_cubit.dart
//
// CHANGES vs original — minimal surgical additions only:
//   1. New constructor params:
//        GetProductsWithPromotionsUseCase _getProductsWithPromotions
//        ProductPdfGenerator              _productPdfGenerator
//        ProductExcelGenerator            _productExcelGenerator
//   2. exportProductList() replaced: now calls live usecase + local generator.
//   3. _toExportRows() helper added.
//   4. _openOrShareLocalFile() helper added.
//
// ALL OTHER METHODS are IDENTICAL to the original:
//   exportMarketingSummary, exportSalesSummary, exportCustomerList,
//   exportCustomerIndividual, exportInvoice, setInvoiceOrderId,
//   _startExport, _startPolling, downloadExport, _handleLocalFile,
//   requestExport, getExportStatus, _setLoadingFlag
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/domain/usecases/get_products_with_promotions_usecase.dart';
import '../../domain/models/product_export_row.dart';
import '../../domain/models/request_export_request.dart';
import '../../domain/services/product_excel_generator.dart';
import '../../domain/services/product_pdf_generator.dart';
import '../../domain/services/report_export_service.dart';
import 'report_export_state.dart';

class ReportExportCubit extends Cubit<ReportExportState> {
  final ReportExportService _service;

  // NEW — on-device product list generation
  final GetProductsWithPromotionsUseCase _getProductsWithPromotions;
  final ProductPdfGenerator _productPdfGenerator;
  final ProductExcelGenerator _productExcelGenerator;

  Timer? _pollTimer;

  ReportExportCubit({
    required ReportExportService service,
    required GetProductsWithPromotionsUseCase getProductsWithPromotions,
    ProductPdfGenerator productPdfGenerator = const ProductPdfGenerator(),
    ProductExcelGenerator productExcelGenerator = const ProductExcelGenerator(),
  }) : _service = service,
       _getProductsWithPromotions = getProductsWithPromotions,
       _productPdfGenerator = productPdfGenerator,
       _productExcelGenerator = productExcelGenerator,
       super(const ReportExportState());

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  // ── Public export triggers ─────────────────────────────────────────────────

  Future<void> exportMarketingSummary({
    required String format,
    String? dateFrom,
    String? dateTo,
  }) => _startExport(
    reportType: 'marketing_summary',
    format: format,
    loadingFlag: 'marketing',
    dateFrom: dateFrom,
    dateTo: dateTo,
  );

  Future<void> exportSalesSummary({
    required String format,
    String? dateFrom,
    String? dateTo,
  }) => _startExport(
    reportType: 'sales_summary',
    format: format,
    loadingFlag: 'sales',
    dateFrom: dateFrom,
    dateTo: dateTo,
  );

  Future<void> exportCustomerList({required String format}) => _startExport(
    reportType: 'customer_list',
    format: format,
    loadingFlag: 'customer_list',
  );

  Future<void> exportCustomerIndividual({
    required String customerId,
    required String format,
  }) => _startExport(
    reportType: 'customer_individual',
    format: format,
    loadingFlag: 'customer_individual',
    referenceId: customerId,
  );

  Future<void> exportInvoice({required String orderId}) => _startExport(
    reportType: 'invoice',
    format: 'pdf',
    loadingFlag: 'invoice',
    referenceId: orderId,
  );

  void setInvoiceOrderId(String value) =>
      emit(state.copyWith(invoiceOrderId: value, invoiceError: null));

  // ── Product list — on-device generation with live domain data ──────────────
  //
  // Replaces the original _startExport('product_list') delegation.
  // Source: GetProductsWithPromotionsUseCase → ProductEntity list →
  //         ProductExportRow DTO → PDF or Excel file → open/share.

  Future<void> exportProductList({required String format}) async {
    _setLoadingFlag('product_list', true);

    final result = await _getProductsWithPromotions(NoParams());

    await result.fold(
      (failure) async {
        _setLoadingFlag('product_list', false);
        emit(state.copyWith(productListError: failure.message));
      },
      (products) async {
        try {
          final rows = _toExportRows(products);

          final File file;
          if (format == 'excel') {
            file = await _productExcelGenerator.generate(rows);
          } else {
            file = await _productPdfGenerator.generate(rows);
          }

          _setLoadingFlag('product_list', false);
          await _openOrShareLocalFile(file, format);
        } catch (e) {
          _setLoadingFlag('product_list', false);
          emit(state.copyWith(productListError: e.toString()));
        }
      },
    );
  }

  // ── Row mapper ─────────────────────────────────────────────────────────────

  List<ProductExportRow> _toExportRows(List<ProductEntity> products) {
    return products.asMap().entries.map((entry) {
      final p = entry.value;
      return ProductExportRow(
        no: entry.key + 1,
        name: p.name,
        description: p.description ?? '',
        packSize: p.packSize ?? '',
        // effectivePrice is promotion-aware — never use raw price here
        packPrice: p.effectivePrice,
        quantityAvailable: p.quantityAvailable ?? 0,
      );
    }).toList();
  }

  // ── Local file open / share ────────────────────────────────────────────────

  Future<void> _openOrShareLocalFile(File file, String format) async {
    final fileName =
        'product_list_${DateTime.now().millisecondsSinceEpoch}'
        '.${format == 'excel' ? 'xlsx' : 'pdf'}';

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose where to save $fileName',
      );
      if (dir != null) {
        final dest = File('$dir${Platform.pathSeparator}$fileName');
        await file.copy(dest.path);
        await OpenFile.open(dest.path);
        emit(
          state.copyWith(
            lastSavedPath: dest.path,
            lastDownloadedFileName: fileName,
          ),
        );
      }
    } else {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, name: fileName)],
          subject: fileName,
          text: 'Bariki Pharmacy — $fileName',
        ),
      );
      emit(state.copyWith(lastDownloadedFileName: fileName));
    }
  }

  // ── Core server export flow ────────────────────────────────────────────────

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
        emit(
          state.copyWith(
            activeExportId: response.exportId,
            exportHistory: history,
            lastSyncAt: DateTime.now(),
            pollingStatus: null,
          ),
        );
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
          final history = state.exportHistory.map((e) {
            if (e.exportId == exportId) return e.copyWith(status: 'failed');
            return e;
          }).toList();
          emit(
            state.copyWith(
              activeExportId: null,
              pollingStatus: null,
              exportHistory: history,
            ),
          );
        },
        (status) {
          final history = state.exportHistory.map((e) {
            if (e.exportId == exportId)
              return e.copyWith(status: status.status);
            return e;
          }).toList();
          if (status.status == 'ready' || status.status == 'failed') {
            _pollTimer?.cancel();
            emit(
              state.copyWith(
                activeExportId: null,
                pollingStatus: null,
                exportHistory: history,
              ),
            );
          } else {
            emit(state.copyWith(pollingStatus: status, exportHistory: history));
          }
        },
      );
    });
  }

  // ── Download + save (server exports) ──────────────────────────────────────

  Future<void> downloadExport(String exportId) async {
    emit(
      state.copyWith(isDownloadExportLoading: true, downloadExportError: null),
    );
    final result = await _service.downloadExport(exportId);
    result.fold(
      (f) => emit(
        state.copyWith(
          isDownloadExportLoading: false,
          downloadExportError: f.message,
        ),
      ),
      (r) async {
        emit(
          state.copyWith(
            isDownloadExportLoading: false,
            downloadExportResult: r,
            lastSyncAt: DateTime.now(),
          ),
        );

        final url = r.fileUrl;

        if (url.startsWith('/') || (url.length > 2 && url[1] == ':')) {
          await _handleLocalFile(url, r.fileName);
        } else if (url.startsWith('http')) {
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
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose where to save $fileName',
      );
      if (dir != null) {
        final dest = File('$dir${Platform.pathSeparator}$fileName');
        await file.copy(dest.path);
        await OpenFile.open(dest.path);
        emit(state.copyWith(lastSavedPath: dest.path));
      }
    } else {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, name: fileName, mimeType: 'application/pdf')],
          subject: fileName,
          text: 'Bariki Pharmacy — $fileName',
        ),
      );
    }
  }

  // ── Legacy service methods (kept for compatibility) ────────────────────────

  Future<void> requestExport(RequestExportRequest request) async {
    emit(
      state.copyWith(isRequestExportLoading: true, requestExportError: null),
    );
    final result = await _service.requestExport(request);
    result.fold(
      (f) => emit(
        state.copyWith(
          isRequestExportLoading: false,
          requestExportError: f.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          isRequestExportLoading: false,
          lastSyncAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> getExportStatus(String exportId) async {
    emit(
      state.copyWith(
        isGetExportStatusLoading: true,
        getExportStatusError: null,
      ),
    );
    final result = await _service.getExportStatus(exportId);
    result.fold(
      (f) => emit(
        state.copyWith(
          isGetExportStatusLoading: false,
          getExportStatusError: f.message,
        ),
      ),
      (r) => emit(
        state.copyWith(
          isGetExportStatusLoading: false,
          getExportStatusResult: r,
          lastSyncAt: DateTime.now(),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setLoadingFlag(String flag, bool value) {
    emit(
      state.copyWith(
        isMarketingSummaryLoading: flag == 'marketing'
            ? value
            : state.isMarketingSummaryLoading,
        isSalesSummaryLoading: flag == 'sales'
            ? value
            : state.isSalesSummaryLoading,
        isCustomerListLoading: flag == 'customer_list'
            ? value
            : state.isCustomerListLoading,
        isCustomerIndividualLoading: flag == 'customer_individual'
            ? value
            : state.isCustomerIndividualLoading,
        isProductListLoading: flag == 'product_list'
            ? value
            : state.isProductListLoading,
        isInvoiceLoading: flag == 'invoice' ? value : state.isInvoiceLoading,
      ),
    );
  }
}
