import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/create_activity_log_usecase.dart';
import '../../domain/usecases/delete_activity_log_usecase.dart';
import '../../domain/usecases/get_activity_log_usecase.dart';
import '../../domain/usecases/get_all_activity_log_usecase.dart';
import '../../domain/usecases/update_activity_log_usecase.dart';
import 'activity_log_event.dart';
import 'activity_log_state.dart';

class ActivityLogBloc extends Bloc<ActivityLogEvent, ActivityLogState> {
  final GetAllActivityLogUseCase  getAllUseCase;
  final GetActivityLogUseCase     getUseCase;
  final CreateActivityLogUseCase  createUseCase;
  final UpdateActivityLogUseCase  updateUseCase;
  final DeleteActivityLogUseCase  deleteUseCase;

  ActivityLogBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
  }) : super(ActivityLogInitial()) {
    on<ActivityLogLoadAllRequested>(_onLoadAll);
    on<ActivityLogLoadOneRequested>(_onLoadOne);
    on<ActivityLogCreateRequested>(_onCreate);
    on<ActivityLogUpdateRequested>(_onUpdate);
    on<ActivityLogDeleteRequested>(_onDelete);
    on<ActivityLogFormReset>((_, emit) => emit(ActivityLogInitial()));
  }

  Future<void> _onLoadAll(
      ActivityLogLoadAllRequested event, Emitter<ActivityLogState> emit) async {
    emit(ActivityLogLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(ActivityLogFailure(f.message)),
      (items) => items.isEmpty
          ? emit(ActivityLogEmpty())
          : emit(ActivityLogListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
      ActivityLogLoadOneRequested event, Emitter<ActivityLogState> emit) async {
    emit(ActivityLogLoading());
    final result = await getUseCase(GetActivityLogParams(id: event.id));
    result.fold(
      (f) => emit(ActivityLogFailure(f.message)),
      (item) => emit(ActivityLogDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
      ActivityLogCreateRequested event, Emitter<ActivityLogState> emit) async {
    emit(ActivityLogLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(ActivityLogFailure(f.message)),
      (_) => emit(ActivityLogOperationSuccess('ActivityLog created successfully')),
    );
  }

  Future<void> _onUpdate(
      ActivityLogUpdateRequested event, Emitter<ActivityLogState> emit) async {
    emit(ActivityLogLoading());
    final result = await updateUseCase(UpdateActivityLogParams(entity: event.entity));
    result.fold(
      (f) => emit(ActivityLogFailure(f.message)),
      (_) => emit(ActivityLogOperationSuccess('ActivityLog updated successfully')),
    );
  }

  Future<void> _onDelete(
      ActivityLogDeleteRequested event, Emitter<ActivityLogState> emit) async {
    emit(ActivityLogLoading());
    final result = await deleteUseCase(DeleteActivityLogParams(id: event.id));
    result.fold(
      (f) => emit(ActivityLogFailure(f.message)),
      (_) => emit(ActivityLogOperationSuccess('ActivityLog deleted successfully')),
    );
  }
}
