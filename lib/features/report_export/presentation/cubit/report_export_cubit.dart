// lib/features/report_export/presentation/cubit/report_export_cubit.dart
//
// CHANGES vs previous delivery:
//   • Added WeeklyPlanPdfGenerator, WeeklyPlanExcelGenerator,
//     GetAllWeeklyPlanUseCase
//   • exportWeeklyPlans() — all plans, on-device
//   • exportWeeklyPlansByOfficers() — filtered by officer IDs, on-device
//   • _toWeeklyPlanRows() mapper added
//   • All other methods IDENTICAL to previous delivery
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
import '../../../weekly_plan/domain/entities/weekly_plan_entity.dart';
import '../../../weekly_plan/domain/usecases/get_all_weekly_plan_usecase.dart';
import '../../domain/models/customer_export_row.dart';
import '../../domain/models/product_export_row.dart';
import '../../domain/models/request_export_request.dart';
import '../../domain/models/weekly_plan_export_row.dart';
import '../../domain/services/customer_excel_generator.dart';
import '../../domain/services/customer_pdf_generator.dart';
import '../../domain/services/product_excel_generator.dart';
import '../../domain/services/product_pdf_generator.dart';
import '../../domain/services/report_export_service.dart';
import '../../domain/services/weekly_plan_excel_generator.dart';
import '../../domain/services/weekly_plan_pdf_generator.dart';
import 'report_export_state.dart';

class ReportExportCubit extends Cubit<ReportExportState> {
  final ReportExportService _service;

  // ── Product export ────────────────────────────────────────────
  final GetProductsWithPromotionsUseCase _getProductsWithPromotions;
  final ProductPdfGenerator _productPdfGenerator;
  final ProductExcelGenerator _productExcelGenerator;

  // ── Customer export ───────────────────────────────────────────
  final GetAllCustomerUseCase _getAllCustomers;
  final GetCustomerUseCase _getCustomer;
  final GetCustomerVisitsUseCase _getCustomerVisits;
  final CustomerPdfGenerator _customerPdfGenerator;
  final CustomerExcelGenerator _customerExcelGenerator;

  // ── Weekly plan export ────────────────────────────────────────
  final GetAllWeeklyPlanUseCase _getAllWeeklyPlans;
  final WeeklyPlanPdfGenerator _weeklyPlanPdfGenerator;
  final WeeklyPlanExcelGenerator _weeklyPlanExcelGenerator;

  Timer? _pollTimer;

  ReportExportCubit({
    required ReportExportService service,
    required GetProductsWithPromotionsUseCase getProductsWithPromotions,
    required GetAllCustomerUseCase getAllCustomers,
    required GetCustomerUseCase getCustomer,
    required GetCustomerVisitsUseCase getCustomerVisits,
    required GetAllWeeklyPlanUseCase getAllWeeklyPlans,
    ProductPdfGenerator productPdfGenerator = const ProductPdfGenerator(),
    ProductExcelGenerator productExcelGenerator = const ProductExcelGenerator(),
    CustomerPdfGenerator customerPdfGenerator = const CustomerPdfGenerator(),
    CustomerExcelGenerator customerExcelGenerator =
        const CustomerExcelGenerator(),
    WeeklyPlanPdfGenerator weeklyPlanPdfGenerator =
        const WeeklyPlanPdfGenerator(),
    WeeklyPlanExcelGenerator weeklyPlanExcelGenerator =
        const WeeklyPlanExcelGenerator(),
  }) : _service = service,
       _getProductsWithPromotions = getProductsWithPromotions,
       _getAllCustomers = getAllCustomers,
       _getCustomer = getCustomer,
       _getCustomerVisits = getCustomerVisits,
       _getAllWeeklyPlans = getAllWeeklyPlans,
       _productPdfGenerator = productPdfGenerator,
       _productExcelGenerator = productExcelGenerator,
       _customerPdfGenerator = customerPdfGenerator,
       _customerExcelGenerator = customerExcelGenerator,
       _weeklyPlanPdfGenerator = weeklyPlanPdfGenerator,
       _weeklyPlanExcelGenerator = weeklyPlanExcelGenerator,
       super(const ReportExportState());

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  // ── Server-side exports ────────────────────────────────────────────────────

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

  Future<void> exportInvoice({required String orderId}) => _startExport(
    reportType: 'invoice',
    format: 'pdf',
    loadingFlag: 'invoice',
    referenceId: orderId,
  );

  void setInvoiceOrderId(String value) =>
      emit(state.copyWith(invoiceOrderId: value, invoiceError: null));

  // ── Product list — on-device ───────────────────────────────────────────────

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

  // ── Customer list — on-device ──────────────────────────────────────────────

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
          final rows = await _toCustomerRows(
            paginated.items,
            includeVisits: includeVisits,
          );
          final File file = format == 'excel'
              ? await _customerExcelGenerator.generate(
                  rows,
                  includeVisits: includeVisits,
                )
              : await _customerPdfGenerator.generate(
                  rows,
                  includeVisits: includeVisits,
                );
          _setLoadingFlag('customer_list', false);
          await _openOrShareLocalFile(file, format, 'customer_list');
        } catch (e) {
          _setLoadingFlag('customer_list', false);
          emit(state.copyWith(customerListError: e.toString()));
        }
      },
    );
  }

  // ── Customer individual — on-device ───────────────────────────────────────

  Future<void> exportCustomerIndividual({
    required String customerId,
    required String format,
    bool includeVisits = true,
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
          final rows = await _toCustomerRows([
            customer,
          ], includeVisits: includeVisits);
          final File file = format == 'excel'
              ? await _customerExcelGenerator.generate(
                  rows,
                  includeVisits: includeVisits,
                )
              : await _customerPdfGenerator.generate(
                  rows,
                  includeVisits: includeVisits,
                );
          _setLoadingFlag('customer_individual', false);
          await _openOrShareLocalFile(
            file,
            format,
            'customer_${customer.name.replaceAll(' ', '_').toLowerCase()}',
          );
        } catch (e) {
          _setLoadingFlag('customer_individual', false);
          emit(state.copyWith(customerListError: e.toString()));
        }
      },
    );
  }

  // ── Weekly plans — all, on-device ─────────────────────────────────────────

  Future<void> exportWeeklyPlans({required String format}) async {
    _setLoadingFlag('weekly_plans', true);
    final result = await _getAllWeeklyPlans(NoParams());
    await result.fold(
      (failure) async {
        _setLoadingFlag('weekly_plans', false);
        emit(state.copyWith(weeklyPlansError: failure.message));
      },
      (plans) async {
        try {
          final rows = _toWeeklyPlanRows(plans);
          final File file = format == 'excel'
              ? await _weeklyPlanExcelGenerator.generate(rows)
              : await _weeklyPlanPdfGenerator.generate(rows);
          _setLoadingFlag('weekly_plans', false);
          await _openOrShareLocalFile(file, format, 'weekly_plans');
        } catch (e) {
          _setLoadingFlag('weekly_plans', false);
          emit(state.copyWith(weeklyPlansError: e.toString()));
        }
      },
    );
  }

  // ── Weekly plans — filtered by officer IDs, on-device ─────────────────────
  //
  // [officerIds] is a Set of officerId values (from WeeklyPlanEntity.officerId).
  // The user selects one or more officers in the UI; the cubit filters here.

  Future<void> exportWeeklyPlansByOfficers({
    required String format,
    required Set<String> officerIds,
  }) async {
    if (officerIds.isEmpty) {
      emit(state.copyWith(weeklyPlansError: 'Select at least one officer.'));
      return;
    }

    _setLoadingFlag('weekly_plans_filtered', true);
    final result = await _getAllWeeklyPlans(NoParams());
    await result.fold(
      (failure) async {
        _setLoadingFlag('weekly_plans_filtered', false);
        emit(state.copyWith(weeklyPlansError: failure.message));
      },
      (plans) async {
        try {
          // Filter to selected officers only
          final filtered = plans
              .where((p) => officerIds.contains(p.officerId))
              .toList();

          if (filtered.isEmpty) {
            _setLoadingFlag('weekly_plans_filtered', false);
            emit(
              state.copyWith(
                weeklyPlansError: 'No plans found for the selected officer(s).',
              ),
            );
            return;
          }

          final rows = _toWeeklyPlanRows(filtered);

          // Build a readable filter label for the document header
          final officerNames = rows
              .map((r) => r.officerName)
              .toSet()
              .take(3)
              .join(', ');
          final filterLabel = rows.length < plans.length
              ? 'Officer${officerIds.length > 1 ? "s" : ""}: $officerNames'
                    '${officerIds.length > 3 ? " +${officerIds.length - 3} more" : ""}'
              : null;

          final File file = format == 'excel'
              ? await _weeklyPlanExcelGenerator.generate(
                  rows,
                  filterLabel: filterLabel,
                )
              : await _weeklyPlanPdfGenerator.generate(
                  rows,
                  filterLabel: filterLabel,
                );

          _setLoadingFlag('weekly_plans_filtered', false);
          await _openOrShareLocalFile(file, format, 'weekly_plans_filtered');
        } catch (e) {
          _setLoadingFlag('weekly_plans_filtered', false);
          emit(state.copyWith(weeklyPlansError: e.toString()));
        }
      },
    );
  }

  // ── Row mappers ────────────────────────────────────────────────────────────

  List<ProductExportRow> _toProductRows(List<ProductEntity> products) =>
      products.asMap().entries.map((e) {
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

  Future<List<CustomerExportRow>> _toCustomerRows(
    List<CustomerEntity> customers, {
    required bool includeVisits,
  }) async {
    final List<CustomerExportRow> rows = [];
    for (int i = 0; i < customers.length; i++) {
      final c = customers[i];
      List<CustomerVisitRow> visitRows = [];
      if (includeVisits) {
        final visitResult = await _getCustomerVisits(
          GetCustomerVisitsParams(customerId: c.id),
        );
        visitResult.fold((_) => visitRows = [], (visits) {
          visitRows = visits
              .map(
                (v) => CustomerVisitRow(
                  visitDate: _fmtDate(v.visitDate),
                  status: v.status,
                  officerName: v.officerName,
                  purpose: v.purpose,
                  notes: v.notes,
                  outcome: v.outcome,
                ),
              )
              .toList();
        });
      }
      rows.add(
        CustomerExportRow(
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
          contacts: c.contacts
              .map(
                (ct) => CustomerContactRow(
                  name: ct.name,
                  role: ct.role,
                  phone: ct.phone,
                  email: ct.email,
                  whatsapp: ct.whatsappNumber,
                  isPrimary: ct.isPrimary,
                ),
              )
              .toList(),
          assignedOfficerName: c.assignedOfficerId,
          registeredAt: c.createdAt != null ? _fmtDate(c.createdAt!) : null,
          visits: visitRows,
        ),
      );
    }
    return rows;
  }

  List<WeeklyPlanExportRow> _toWeeklyPlanRows(List<WeeklyPlanEntity> plans) {
    return plans.asMap().entries.map((e) {
      final i = e.key;
      final p = e.value;

      final weekRange = '${_fmtShort(p.weekStart)} – ${_fmtShort(p.weekEnd)}';

      final items = p.items
          .map(
            (it) => PlanItemExportRow(
              customerId: it.customerId,
              customerName: it.customerName,
              title: it.title,
              objective: it.objective,
              plannedDate: it.plannedDate != null
                  ? _fmtDate(it.plannedDate!)
                  : null,
              startTime: it.plannedStartTime,
              endTime: it.plannedEndTime,
              notes: it.notes,
              status: it.status,
            ),
          )
          .toList();

      return WeeklyPlanExportRow(
        no: i + 1,
        id: p.id,
        officerId: p.officerId,
        officerName: p.officerName ?? p.officerId,
        weekRange: weekRange,
        weekStart: _fmtDate(p.weekStart),
        weekEnd: _fmtDate(p.weekEnd),
        status: p.status,
        plannedActivities: p.plannedActivities,
        notes: p.notes,
        plannedCustomerIds: p.plannedCustomerIds ?? [],
        items: items,
        submittedAt: p.submittedAt != null ? _fmtDate(p.submittedAt!) : null,
        reviewedAt: p.reviewedAt != null ? _fmtDate(p.reviewedAt!) : null,
        reviewNotes: p.reviewNotes,
        createdAt: _fmtDate(p.createdAt),
      );
    }).toList();
  }

  // ── Local file open / share ────────────────────────────────────────────────

  Future<void> _openOrShareLocalFile(
    File file,
    String format,
    String baseName,
  ) async {
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
            if (e.exportId == exportId) {
              return e.copyWith(status: status.status);
            }
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
          text: 'Barick Pharmacy — $fileName',
        ),
      );
    }
  }

  // ── Legacy service methods ─────────────────────────────────────────────────

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
        isWeeklyPlansLoading:
            (flag == 'weekly_plans' || flag == 'weekly_plans_filtered')
            ? value
            : state.isWeeklyPlansLoading,
        isInvoiceLoading: flag == 'invoice' ? value : state.isInvoiceLoading,
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _fmtShort(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} '
        '${months[d.month]} ${d.year}';
  }
}
