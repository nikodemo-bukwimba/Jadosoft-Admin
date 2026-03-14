import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/services/daily_report_domain_service.dart';
import '../../domain/usecases/create_daily_report_usecase.dart';
import '../../domain/usecases/delete_daily_report_usecase.dart';
import '../../domain/usecases/get_daily_report_usecase.dart';
import '../../domain/usecases/get_all_daily_report_usecase.dart';
import '../../domain/usecases/update_daily_report_usecase.dart';
import '../../domain/value_objects/daily_report_status.dart';
import 'daily_report_event.dart';
import 'daily_report_state.dart';

class DailyReportBloc extends Bloc<DailyReportEvent, DailyReportState> {
  final GetAllDailyReportUseCase getAllUseCase;
  final GetDailyReportUseCase getUseCase;
  final CreateDailyReportUseCase createUseCase;
  final UpdateDailyReportUseCase updateUseCase;
  final DeleteDailyReportUseCase deleteUseCase;
  final DailyReportDomainService domainService;

  DailyReportBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
    required this.domainService,
  }) : super(DailyReportInitial()) {
    on<DailyReportLoadAllRequested>(_onLoadAll);
    on<DailyReportLoadOneRequested>(_onLoadOne);
    on<DailyReportCreateRequested>(_onCreate);
    on<DailyReportUpdateRequested>(_onUpdate);
    on<DailyReportDeleteRequested>(_onDelete);
    on<DailyReportFormReset>((_, emit) => emit(DailyReportInitial()));
    on<DailyReportSubmitRequested>(_onSubmit);
    on<DailyReportApproveRequested>(_onApprove);
    on<DailyReportRejectRequested>(_onReject);
    on<DailyReportResubmitRequested>(_onResubmit);
  }

  Future<void> _onLoadAll(
    DailyReportLoadAllRequested event,
    Emitter<DailyReportState> emit,
  ) async {
    emit(DailyReportLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(DailyReportFailure(f.message)),
      (items) => items.isEmpty
          ? emit(DailyReportEmpty())
          : emit(DailyReportListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
    DailyReportLoadOneRequested event,
    Emitter<DailyReportState> emit,
  ) async {
    emit(DailyReportLoading());
    final result = await getUseCase(GetDailyReportParams(id: event.id));
    result.fold(
      (f) => emit(DailyReportFailure(f.message)),
      (item) => emit(DailyReportDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
    DailyReportCreateRequested event,
    Emitter<DailyReportState> emit,
  ) async {
    emit(DailyReportLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(DailyReportFailure(f.message)),
      (_) => emit(
        DailyReportOperationSuccess('Daily report created successfully'),
      ),
    );
  }

  Future<void> _onUpdate(
    DailyReportUpdateRequested event,
    Emitter<DailyReportState> emit,
  ) async {
    emit(DailyReportLoading());
    final result = await updateUseCase(
      UpdateDailyReportParams(entity: event.entity),
    );
    result.fold(
      (f) => emit(DailyReportFailure(f.message)),
      (_) => emit(
        DailyReportOperationSuccess('Daily report updated successfully'),
      ),
    );
  }

  Future<void> _onDelete(
    DailyReportDeleteRequested event,
    Emitter<DailyReportState> emit,
  ) async {
    emit(DailyReportLoading());
    final result = await deleteUseCase(DeleteDailyReportParams(id: event.id));
    result.fold(
      (f) => emit(DailyReportFailure(f.message)),
      (_) => emit(
        DailyReportOperationSuccess('Daily report deleted successfully'),
      ),
    );
  }

  Future<void> _onSubmit(
    DailyReportSubmitRequested event,
    Emitter<DailyReportState> emit,
  ) async {
    emit(DailyReportLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: DailyReportStatus.submitted,
    );
    result.fold(
      (f) => emit(DailyReportFailure(f.message)),
      (entity) => emit(
        DailyReportOperationSuccess(
          'Report submitted successfully',
          updatedItem: entity,
        ),
      ),
    );
  }

  Future<void> _onApprove(
    DailyReportApproveRequested event,
    Emitter<DailyReportState> emit,
  ) async {
    emit(DailyReportLoading());

    // Step 1: transition status
    final transitionResult = await domainService.transition(
      id: event.id,
      targetStatus: DailyReportStatus.approved,
    );

    // Extract failure or entity — no async inside fold
    if (transitionResult.isLeft()) {
      final failure = transitionResult.fold((f) => f, (_) => null)!;
      emit(DailyReportFailure(failure.message));
      return;
    }

    final entity = transitionResult.fold((_) => null, (e) => e)!;

    // Step 2: persist feedback
    final withFeedback = entity.copyWith(
      adminFeedback: event.feedback,
      reviewDecision: 'approved',
      reviewedAt: DateTime.now(),
      // TODO: replace with authenticated admin from AuthSession when real API lands
      reviewedByName: 'Dr. Joseph Barick',
      reviewedByRole: 'Head Marketing Officer',
    );

    final updateResult = await updateUseCase(
      UpdateDailyReportParams(entity: withFeedback),
    );

    updateResult.fold(
      (f) => emit(DailyReportFailure(f.message)),
      (updated) => emit(
        DailyReportOperationSuccess(
          'Report approved successfully',
          updatedItem: updated,
        ),
      ),
    );
  }

  Future<void> _onReject(
    DailyReportRejectRequested event,
    Emitter<DailyReportState> emit,
  ) async {
    emit(DailyReportLoading());

    // Step 1: transition status
    final transitionResult = await domainService.transition(
      id: event.id,
      targetStatus: DailyReportStatus.rejected,
    );

    // Extract failure or entity — no async inside fold
    if (transitionResult.isLeft()) {
      final failure = transitionResult.fold((f) => f, (_) => null)!;
      emit(DailyReportFailure(failure.message));
      return;
    }

    final entity = transitionResult.fold((_) => null, (e) => e)!;

    // Step 2: persist feedback
    final withFeedback = entity.copyWith(
      adminFeedback: event.feedback,
      reviewDecision: 'rejected',
      reviewedAt: DateTime.now(),
      // TODO: replace with authenticated admin from AuthSession when real API lands
      reviewedByName: 'Dr. Joseph Barick',
      reviewedByRole: 'Head Marketing Officer',
    );

    final updateResult = await updateUseCase(
      UpdateDailyReportParams(entity: withFeedback),
    );

    updateResult.fold(
      (f) => emit(DailyReportFailure(f.message)),
      (updated) => emit(
        DailyReportOperationSuccess('Report rejected', updatedItem: updated),
      ),
    );
  }

  Future<void> _onResubmit(
    DailyReportResubmitRequested event,
    Emitter<DailyReportState> emit,
  ) async {
    emit(DailyReportLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: DailyReportStatus.submitted,
    );
    result.fold(
      (f) => emit(DailyReportFailure(f.message)),
      (entity) => emit(
        DailyReportOperationSuccess('Report resubmitted', updatedItem: entity),
      ),
    );
  }
}
