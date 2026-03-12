import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/services/weekly_plan_domain_service.dart';
import '../../domain/usecases/create_weekly_plan_usecase.dart';
import '../../domain/usecases/delete_weekly_plan_usecase.dart';
import '../../domain/usecases/get_weekly_plan_usecase.dart';
import '../../domain/usecases/get_all_weekly_plan_usecase.dart';
import '../../domain/usecases/update_weekly_plan_usecase.dart';
import '../../domain/value_objects/weekly_plan_status.dart';
import 'weekly_plan_event.dart';
import 'weekly_plan_state.dart';

class WeeklyPlanBloc extends Bloc<WeeklyPlanEvent, WeeklyPlanState> {
  final GetAllWeeklyPlanUseCase  getAllUseCase;
  final GetWeeklyPlanUseCase     getUseCase;
  final CreateWeeklyPlanUseCase  createUseCase;
  final UpdateWeeklyPlanUseCase  updateUseCase;
  final DeleteWeeklyPlanUseCase  deleteUseCase;
  final WeeklyPlanDomainService  domainService;

  WeeklyPlanBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
    required this.domainService,
  }) : super(WeeklyPlanInitial()) {
    on<WeeklyPlanLoadAllRequested>(_onLoadAll);
    on<WeeklyPlanLoadOneRequested>(_onLoadOne);
    on<WeeklyPlanCreateRequested>(_onCreate);
    on<WeeklyPlanUpdateRequested>(_onUpdate);
    on<WeeklyPlanDeleteRequested>(_onDelete);
    on<WeeklyPlanFormReset>((_, emit) => emit(WeeklyPlanInitial()));
    on<WeeklyPlanApproveRequested>(_onApprove);
    on<WeeklyPlanRejectRequested>(_onReject);
    on<WeeklyPlanResubmitRequested>(_onResubmit);
  }

  Future<void> _onLoadAll(
      WeeklyPlanLoadAllRequested event, Emitter<WeeklyPlanState> emit) async {
    emit(WeeklyPlanLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(WeeklyPlanFailure(f.message)),
      (items) => items.isEmpty
          ? emit(WeeklyPlanEmpty())
          : emit(WeeklyPlanListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
      WeeklyPlanLoadOneRequested event, Emitter<WeeklyPlanState> emit) async {
    emit(WeeklyPlanLoading());
    final result = await getUseCase(GetWeeklyPlanParams(id: event.id));
    result.fold(
      (f) => emit(WeeklyPlanFailure(f.message)),
      (item) => emit(WeeklyPlanDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
      WeeklyPlanCreateRequested event, Emitter<WeeklyPlanState> emit) async {
    emit(WeeklyPlanLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(WeeklyPlanFailure(f.message)),
      (_) => emit(WeeklyPlanOperationSuccess('WeeklyPlan created successfully')),
    );
  }

  Future<void> _onUpdate(
      WeeklyPlanUpdateRequested event, Emitter<WeeklyPlanState> emit) async {
    emit(WeeklyPlanLoading());
    final result = await updateUseCase(UpdateWeeklyPlanParams(entity: event.entity));
    result.fold(
      (f) => emit(WeeklyPlanFailure(f.message)),
      (_) => emit(WeeklyPlanOperationSuccess('WeeklyPlan updated successfully')),
    );
  }

  Future<void> _onDelete(
      WeeklyPlanDeleteRequested event, Emitter<WeeklyPlanState> emit) async {
    emit(WeeklyPlanLoading());
    final result = await deleteUseCase(DeleteWeeklyPlanParams(id: event.id));
    result.fold(
      (f) => emit(WeeklyPlanFailure(f.message)),
      (_) => emit(WeeklyPlanOperationSuccess('WeeklyPlan deleted successfully')),
    );
  }

  Future<void> _onApprove(
      WeeklyPlanApproveRequested event, Emitter<WeeklyPlanState> emit) async {
    emit(WeeklyPlanLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: WeeklyPlanStatus.approved,
    );
    result.fold(
      (f) => emit(WeeklyPlanFailure(f.message)),
      (entity) => emit(WeeklyPlanOperationSuccess(
        'Approve Plan successful',
        updatedItem: entity,
      )),
    );
  }
  Future<void> _onReject(
      WeeklyPlanRejectRequested event, Emitter<WeeklyPlanState> emit) async {
    emit(WeeklyPlanLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: WeeklyPlanStatus.rejected,
    );
    result.fold(
      (f) => emit(WeeklyPlanFailure(f.message)),
      (entity) => emit(WeeklyPlanOperationSuccess(
        'Reject Plan successful',
        updatedItem: entity,
      )),
    );
  }
  Future<void> _onResubmit(
      WeeklyPlanResubmitRequested event, Emitter<WeeklyPlanState> emit) async {
    emit(WeeklyPlanLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: WeeklyPlanStatus.submitted,
    );
    result.fold(
      (f) => emit(WeeklyPlanFailure(f.message)),
      (entity) => emit(WeeklyPlanOperationSuccess(
        'Resubmit Plan successful',
        updatedItem: entity,
      )),
    );
  }
}
