import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/services/visit_domain_service.dart';
import '../../domain/usecases/create_visit_usecase.dart';
import '../../domain/usecases/delete_visit_usecase.dart';
import '../../domain/usecases/get_visit_usecase.dart';
import '../../domain/usecases/get_all_visit_usecase.dart';
import '../../domain/usecases/update_visit_usecase.dart';
import '../../domain/value_objects/visit_status.dart';
import 'visit_event.dart';
import 'visit_state.dart';

class VisitBloc extends Bloc<VisitEvent, VisitState> {
  final GetAllVisitUseCase  getAllUseCase;
  final GetVisitUseCase     getUseCase;
  final CreateVisitUseCase  createUseCase;
  final UpdateVisitUseCase  updateUseCase;
  final DeleteVisitUseCase  deleteUseCase;
  final VisitDomainService  domainService;

  VisitBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
    required this.domainService,
  }) : super(VisitInitial()) {
    on<VisitLoadAllRequested>(_onLoadAll);
    on<VisitLoadOneRequested>(_onLoadOne);
    on<VisitCreateRequested>(_onCreate);
    on<VisitUpdateRequested>(_onUpdate);
    on<VisitDeleteRequested>(_onDelete);
    on<VisitFormReset>((_, emit) => emit(VisitInitial()));
    on<VisitReviewRequested>(_onReview);
    on<VisitFlagRequested>(_onFlag);
    on<VisitUnflagRequested>(_onUnflag);
  }

  Future<void> _onLoadAll(VisitLoadAllRequested event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (items) => items.isEmpty ? emit(VisitEmpty()) : emit(VisitListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(VisitLoadOneRequested event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    final result = await getUseCase(GetVisitParams(id: event.id));
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (item) => emit(VisitDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(VisitCreateRequested event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (_) => emit(VisitOperationSuccess('Visit created successfully')),
    );
  }

  Future<void> _onUpdate(VisitUpdateRequested event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    final result = await updateUseCase(UpdateVisitParams(entity: event.entity));
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (_) => emit(VisitOperationSuccess('Visit updated successfully')),
    );
  }

  Future<void> _onDelete(VisitDeleteRequested event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    final result = await deleteUseCase(DeleteVisitParams(id: event.id));
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (_) => emit(VisitOperationSuccess('Visit deleted successfully')),
    );
  }

  /// Accept visit with optional comment.
  Future<void> _onReview(VisitReviewRequested event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    final result = await domainService.reviewWithComment(
      id: event.id, comment: event.comment,
    );
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (entity) => emit(VisitOperationSuccess('Visit accepted', updatedItem: entity)),
    );
  }

  /// Flag visit with required comment.
  Future<void> _onFlag(VisitFlagRequested event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    final result = await domainService.flagWithComment(
      id: event.id, comment: event.comment,
    );
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (entity) => emit(VisitOperationSuccess('Visit flagged', updatedItem: entity)),
    );
  }

  Future<void> _onUnflag(VisitUnflagRequested event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    final result = await domainService.unflagVisit(id: event.id);
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (entity) => emit(VisitOperationSuccess('Flag removed', updatedItem: entity)),
    );
  }
}
