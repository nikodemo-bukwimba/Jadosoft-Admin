import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/services/promotion_domain_service.dart';
import '../../domain/usecases/create_promotion_usecase.dart';
import '../../domain/usecases/delete_promotion_usecase.dart';
import '../../domain/usecases/get_promotion_usecase.dart';
import '../../domain/usecases/get_all_promotion_usecase.dart';
import '../../domain/usecases/update_promotion_usecase.dart';
import '../../domain/value_objects/promotion_status.dart';
import 'promotion_event.dart';
import 'promotion_state.dart';

class PromotionBloc extends Bloc<PromotionEvent, PromotionState> {
  final GetAllPromotionUseCase  getAllUseCase;
  final GetPromotionUseCase     getUseCase;
  final CreatePromotionUseCase  createUseCase;
  final UpdatePromotionUseCase  updateUseCase;
  final DeletePromotionUseCase  deleteUseCase;
  final PromotionDomainService  domainService;

  PromotionBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
    required this.domainService,
  }) : super(PromotionInitial()) {
    on<PromotionLoadAllRequested>(_onLoadAll);
    on<PromotionLoadOneRequested>(_onLoadOne);
    on<PromotionCreateRequested>(_onCreate);
    on<PromotionUpdateRequested>(_onUpdate);
    on<PromotionDeleteRequested>(_onDelete);
    on<PromotionFormReset>((_, emit) => emit(PromotionInitial()));
    on<PromotionActivateRequested>(_onActivate);
    on<PromotionEndRequested>(_onEnd);
    on<PromotionCancelRequested>(_onCancel);
  }

  Future<void> _onLoadAll(
      PromotionLoadAllRequested event, Emitter<PromotionState> emit) async {
    emit(PromotionLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(PromotionFailure(f.message)),
      (items) => items.isEmpty
          ? emit(PromotionEmpty())
          : emit(PromotionListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
      PromotionLoadOneRequested event, Emitter<PromotionState> emit) async {
    emit(PromotionLoading());
    final result = await getUseCase(GetPromotionParams(id: event.id));
    result.fold(
      (f) => emit(PromotionFailure(f.message)),
      (item) => emit(PromotionDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
      PromotionCreateRequested event, Emitter<PromotionState> emit) async {
    emit(PromotionLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(PromotionFailure(f.message)),
      (_) => emit(PromotionOperationSuccess('Promotion created successfully')),
    );
  }

  Future<void> _onUpdate(
      PromotionUpdateRequested event, Emitter<PromotionState> emit) async {
    emit(PromotionLoading());
    final result = await updateUseCase(UpdatePromotionParams(entity: event.entity));
    result.fold(
      (f) => emit(PromotionFailure(f.message)),
      (_) => emit(PromotionOperationSuccess('Promotion updated successfully')),
    );
  }

  Future<void> _onDelete(
      PromotionDeleteRequested event, Emitter<PromotionState> emit) async {
    emit(PromotionLoading());
    final result = await deleteUseCase(DeletePromotionParams(id: event.id));
    result.fold(
      (f) => emit(PromotionFailure(f.message)),
      (_) => emit(PromotionOperationSuccess('Promotion deleted successfully')),
    );
  }

  Future<void> _onActivate(
      PromotionActivateRequested event, Emitter<PromotionState> emit) async {
    emit(PromotionLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: PromotionStatus.active,
    );
    result.fold(
      (f) => emit(PromotionFailure(f.message)),
      (entity) => emit(PromotionOperationSuccess(
        'Activate Promotion successful',
        updatedItem: entity,
      )),
    );
  }
  Future<void> _onEnd(
      PromotionEndRequested event, Emitter<PromotionState> emit) async {
    emit(PromotionLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: PromotionStatus.ended,
    );
    result.fold(
      (f) => emit(PromotionFailure(f.message)),
      (entity) => emit(PromotionOperationSuccess(
        'End Promotion successful',
        updatedItem: entity,
      )),
    );
  }
  Future<void> _onCancel(
      PromotionCancelRequested event, Emitter<PromotionState> emit) async {
    emit(PromotionLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: PromotionStatus.cancelled,
    );
    result.fold(
      (f) => emit(PromotionFailure(f.message)),
      (entity) => emit(PromotionOperationSuccess(
        'Cancel Promotion successful',
        updatedItem: entity,
      )),
    );
  }
}
