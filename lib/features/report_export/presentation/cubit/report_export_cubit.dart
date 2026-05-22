// lib/features/report_export/presentation/cubit/report_export_cubit.dart
//
// CHANGES vs previous delivery:
//   • Added CustomerExcelGenerator, CustomerPdfGenerator, 
//     GetAllCustomerUseCase, GetCustomerVisitsUseCase
//   • exportCustomerList() now does on-device generation using live
//     CustomerEntity + optional VisitEntity data.
//   • exportCustomerIndividual() uses GetCustomerUseCase + visits
//     and generates a single-customer PDF/Excel.
//   • _toCustomerRows() mapper added.
//   • All other methods IDENTICAL to previous delivery.
// ─────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../customer/domain/usecases/get_all_customer_usecase.dart';
import '../../../customer/domain/usecases/get_customer_usecase.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/domain/usecases/get_products_with_promotions_usecase.dart';
import '../../../visit/domain/usecases/get_customer_visits_usecase.dart';
import '../../domain/models/customer_export_row.dart';
import '../../domain/models/product_export_row.dart';
import '../../domain/models/request_export_request.dart';
import '../../domain/services/customer_excel_generator.dart';
import '../../domain/services/customer_pdf_generator.dart';
import '../../domain/services/product_excel_generator.dart';
import '../../domain/services/product_pdf_generator.dart';
import '../../domain/services/report_export_service.dart';
import 'report_export_state.dart';

class ReportExportCubit extends Cubit<ReportExportState> {
  final ReportExportService _service;

  // ── Product export ─────────────────────────────────────────────
  final GetProductsWithPromotionsUseCase _getProductsWithPromotions;
  final ProductPdfGenerator   _productPdfGenerator;
  final ProductExcelGenerator _productExcelGenerator;

  // ── Customer export ────────────────────────────────────────────
  final GetAllCustomerUseCase    _getAllCustomers;
  final GetCustomerUseCase       _getCustomer;
  final GetCustomerVisitsUseCase _getCustomerVisits;
  final CustomerPdfGenerator     _customerPdfGenerator;
  final CustomerExcelGenerator   _customerExcelGenerator;

  Timer? _pollTimer;

  ReportExportCubit({
    required ReportExportService service,
    required GetProductsWithPromotionsUseCase getProductsWithPromotions,
    required GetAllCustomerUseCase getAllCustomers,
    required GetCustomerUseCase getCustomer,
    required GetCustomerVisitsUseCase getCustomerVisits,
    ProductPdfGenerator productPdfGenerator = const ProductPdfGenerator(),
    ProductExcelGenerator productExcelGenerator = const ProductExcelGenerator(),
    CustomerPdfGenerator customerPdfGenerator = const CustomerPdfGenerator(),
    CustomerExcelGenerator customerExcelGenerator = const CustomerExcelGenerator(),
  })  : _service = service,
        _getProductsWithPromotions = getProductsWithPromotions,
        _getAllCustomers = getAllCustomers,
        _getCustomer = getCustomer,
        _getCustomerVisits = getCustomerVisits,
        _productPdfGenerator = productPdfGenerator,
        _productExcelGenerator = productExcelGenerator,
        _customerPdfGenerator = customerPdfGenerator,
        _customerExcelGenerator = customerExcelGenerator,
        super(const ReportExportState());

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  // ── Public triggers ────────────────────────────────────────────────────────

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

  Future<void> exportInvoice({required String orderId}) => _startExport(
        reportType: 'invoice',
        format: 'pdf',
        loadingFlag: 'invoice',
        referenceId: orderId,
      );

  void setInvoiceOrderId(String value) =>
      emit(state.copyWith(invoiceOrderId: value, invoiceError: null));

  // ── Product list export — on-device ────────────────────────────────────────

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
          final rows = _toProductRows(products);
          final File file = format == 'excel'
              ? await _productExcelGenerator.generate(rows)
              : await _productPdfGenerator.generate(rows);
          _setLoadingFlag('product_list', false);
          await _openOrShareLocalFile(file, format, 'product_list');
        } catch (e) {
          _setLoadingFlag('product_list', false);
          emit(state.copyWith(productListError: e.toString()));
        }
      },
    );
  }

  // ── Customer list export — on-device ───────────────────────────────────────
  //
  // includeVisits: when true, fetches visit history for every customer
  // via GetCustomerVisitsUseCase and appends it to each row.

  Future<void> exportCustomerList({
    required String format,
    bool includeVisits = false,
  }) async {
    _setLoadingFlag('customer_list', true);

    final result = await _getAllCustomers(NoParams());

    await result.fold(
      (failure) async {
        _setLoadingFlag('customer_list', false);
        emit(state.copyWith(customerListError: failure.message));
      },
      (paginated) async {
        try {
          final customers = paginated.items;
          final rows = await _toCustomerRows(
            customers,
            includeVisits: includeVisits,
          );

          final File file = format == 'excel'
              ? await _customerExcelGenerator.generate(rows,
                  includeVisits: includeVisits)
              : await _customerPdfGenerator.generate(rows,
                  includeVisits: includeVisits);

          _setLoadingFlag('customer_list', false);
          await _openOrShareLocalFile(file, format, 'customer_list');
        } catch (e) {
          _setLoadingFlag('customer_list', false);
          emit(state.copyWith(customerListError: e.toString()));
        }
      },
    );
  }

  // ── Customer individual export — on-device ─────────────────────────────────

  Future<void> exportCustomerIndividual({
    required String customerId,
    required String format,
    bool includeVisits = true, // default true for individual export
  }) async {
    _setLoadingFlag('customer_individual', true);

    final result = await _getCustomer(GetCustomerParams(id: customerId));

    await result.fold(
      (failure) async {
        _setLoadingFlag('customer_individual', false);
        emit(state.copyWith(customerListError: failure.message));
      },
      (customer) async {
        try {
          final rows = await _toCustomerRows(
            [customer],
            includeVisits: includeVisits,
          );

          final File file = format == 'excel'
              ? await _customerExcelGenerator.generate(rows,
                  includeVisits: includeVisits)
              : await _customerPdfGenerator.generate(rows,
                  includeVisits: includeVisits);

          _setLoadingFlag('customer_individual', false);
          await _openOrShareLocalFile(file, format, 'customer_${customer.name.replaceAll(' ', '_').toLowerCase()}');
        } catch (e) {
          _setLoadingFlag('customer_individual', false);
          emit(state.copyWith(customerListError: e.toString()));
        }
      },
    );
  }

  // ── Row mappers ────────────────────────────────────────────────────────────

  List<ProductExportRow> _toProductRows(List<ProductEntity> products) {
    return products.asMap().entries.map((e) {
      final p = e.value;
      return ProductExportRow(
        no: e.key + 1,
        name: p.name,
        description: p.description ?? '',
        packSize: p.packSize ?? '',
        packPrice: p.effectivePrice,
        quantityAvailable: p.quantityAvailable ?? 0,
      );
    }).toList();
  }

  Future<List<CustomerExportRow>> _toCustomerRows(
    List<CustomerEntity> customers, {
    required bool includeVisits,
  }) async {
    final List<CustomerExportRow> rows = [];

    for (int i = 0; i < customers.length; i++) {
      final c = customers[i];

      // Fetch visits if requested
      List<CustomerVisitRow> visitRows = [];
      if (includeVisits) {
        final visitResult = await _getCustomerVisits(
          GetCustomerVisitsParams(customerId: c.id),
        );
        visitResult.fold(
          (_) => visitRows = [],
          (visits) {
            visitRows = visits.map((v) => CustomerVisitRow(
              visitDate: _fmtDate(v.visitDate),
              status: v.status,
              officerName: v.officerName,
              purpose: v.purpose,
              notes: v.notes,
              outcome: v.outcome,
            )).toList();
          },
        );
      }

      rows.add(CustomerExportRow(
        no: i + 1,
        name: c.name,
        code: c.code,
        customerType: c.customerType,
        category: c.category,
        tier: c.tier,
        status: c.status,
        phone: c.phone,
        altPhone: c.altPhone,
        email: c.email,
        whatsappNumber: c.whatsappNumber,
        receivesWhatsapp: c.receivesWhatsapp,
        receivesSms: c.receivesSms,
        receivesInApp: c.receivesInApp,
        address: c.address,
        city: c.city,
        county: c.county,
        country: c.country,
        latitude: c.latitude,
        longitude: c.longitude,
        businessRegistration: c.businessRegistration,
        taxPin: c.taxPin,
        creditLimit: c.creditLimit,
        currency: c.currency,
        notes: c.notes,
        contacts: c.contacts.map((ct) => CustomerContactRow(
          name: ct.name,
          role: ct.role,
          phone: ct.phone,
          email: ct.email,
          whatsapp: ct.whatsappNumber,
          isPrimary: ct.isPrimary,
        )).toList(),
        // assignedOfficerName: not resolved here to avoid N+1 officer API calls.
        // The officer actorId is stored in c.assignedOfficerId.
        // Consumers who need the name should resolve it upstream before calling
        // this method, or pass a pre-built name map. For now we fall back to
        // the raw ID which is better than a silent blank.
        assignedOfficerName: c.assignedOfficerId,
        registeredAt: c.createdAt != null ? _fmtDate(c.createdAt!) : null,
        visits: visitRows,
      ));
    }

    return rows;
  }

  // ── Local file open / share ────────────────────────────────────────────────

  Future<void> _openOrShareLocalFile(
      File file, String format, String baseName) async {
    final ext = format == 'excel' ? 'xlsx' : 'pdf';
    final fileName =
        '${baseName}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose where to save $fileName',
      );
      if (dir != null) {
        final dest = File('$dir${Platform.pathSeparator}$fileName');
        await file.copy(dest.path);
        await OpenFile.open(dest.path);
        emit(state.copyWith(
          lastSavedPath: dest.path,
          lastDownloadedFileName: fileName,
        ));
      }
    } else {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, name: fileName)],
          subject: fileName,
          text: 'Barick Pharmacy — $fileName',
        ),
      );
      emit(state.copyWith(lastDownloadedFileName: fileName));
    }
  }

  // ── Server export flow ─────────────────────────────────────────────────────

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
          final history = state.exportHistory.map((e) {
            if (e.exportId == exportId) return e.copyWith(status: 'failed');
            return e;
          }).toList();
          emit(state.copyWith(
            activeExportId: null,
            pollingStatus: null,
            exportHistory: history,
          ));
        },
        (status) {
          final history = state.exportHistory.map((e) {
            if (e.exportId == exportId) {
              return e.copyWith(status: status.status);
            }
            return e;
          }).toList();
          if (status.status == 'ready' || status.status == 'failed') {
            _pollTimer?.cancel();
            emit(state.copyWith(
                activeExportId: null,
                pollingStatus: null,
                exportHistory: history));
          } else {
            emit(state.copyWith(
                pollingStatus: status, exportHistory: history));
          }
        },
      );
    });
  }

  // ── Download + save (server exports) ──────────────────────────────────────

  Future<void> downloadExport(String exportId) async {
    emit(state.copyWith(
        isDownloadExportLoading: true, downloadExportError: null));
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
          text: 'Barick Pharmacy — $fileName',
        ),
      );
    }
  }

  // ── Legacy service methods ─────────────────────────────────────────────────

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
          flag == 'customer_individual'
              ? value
              : state.isCustomerIndividualLoading,
      isProductListLoading:
          flag == 'product_list' ? value : state.isProductListLoading,
      isInvoiceLoading:
          flag == 'invoice' ? value : state.isInvoiceLoading,
    ));
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}