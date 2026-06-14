// lib/features/visit/presentation/bloc/visit_bloc.dart
//
// CHANGE in _onReview and _onFlag:
//   REMOVED: add(VisitLoadAllRequested()) after emitting VisitOperationSuccess.
//
//   WHY it caused the black screen:
//     1. VisitOperationSuccess is emitted → BlocConsumer listener fires
//        → adds VisitLoadOneRequested(id) to reload the detail.
//     2. But add(VisitLoadAllRequested()) was also fired immediately after,
//        emitting VisitLoading() then VisitListLoaded() — which the detail
//        page builder had no case for, so it fell to the last `return
//        const SizedBox.shrink()` branch → black screen.
//
//   FIX: remove the redundant add(VisitLoadAllRequested()). The listener
//   in visit_detail_page.dart already adds VisitLoadOneRequested on success,
//   which correctly reloads the detail and emits VisitDetailLoaded.
//   The list page will refresh naturally when the user navigates back.
//
// Everything else is identical to the original.

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/services/visit_domain_service.dart';
import '../../domain/usecases/create_visit_usecase.dart';
import '../../domain/usecases/delete_visit_usecase.dart';
import '../../domain/usecases/get_visit_usecase.dart';
import '../../domain/usecases/get_all_visit_usecase.dart';
import '../../domain/usecases/update_visit_usecase.dart';
import '../../domain/usecases/get_customer_visits_usecase.dart';
import 'visit_event.dart';
import 'visit_state.dart';

class VisitBloc extends Bloc<VisitEvent, VisitState> {
  final GetAllVisitUseCase getAllUseCase;
  final GetVisitUseCase getUseCase;
  final CreateVisitUseCase createUseCase;
  final UpdateVisitUseCase updateUseCase;
  final DeleteVisitUseCase deleteUseCase;
  final VisitDomainService domainService;
  final GetCustomerVisitsUseCase getCustomerVisitsUseCase;

  VisitBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
    required this.domainService,
    required this.getCustomerVisitsUseCase,
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
    on<VisitLoadByCustomerRequested>(_onLoadByCustomer);
  }

  Future<void> _onLoadAll(
    VisitLoadAllRequested event,
    Emitter<VisitState> emit,
  ) async {
    emit(VisitLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (items) =>
          items.isEmpty ? emit(VisitEmpty()) : emit(VisitListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
    VisitLoadOneRequested event,
    Emitter<VisitState> emit,
  ) async {
    emit(VisitLoading());
    final result = await getUseCase(GetVisitParams(id: event.id));
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (item) => emit(VisitDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
    VisitCreateRequested event,
    Emitter<VisitState> emit,
  ) async {
    emit(VisitLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (_) => emit(VisitOperationSuccess('Visit created successfully')),
    );
  }

  Future<void> _onUpdate(
    VisitUpdateRequested event,
    Emitter<VisitState> emit,
  ) async {
    emit(VisitLoading());
    final result = await updateUseCase(UpdateVisitParams(entity: event.entity));
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (_) => emit(VisitOperationSuccess('Visit updated successfully')),
    );
  }

  Future<void> _onDelete(
    VisitDeleteRequested event,
    Emitter<VisitState> emit,
  ) async {
    emit(VisitLoading());
    final result = await deleteUseCase(DeleteVisitParams(id: event.id));
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (_) => emit(VisitOperationSuccess('Visit deleted successfully')),
    );
  }

  Future<void> _onReview(
    VisitReviewRequested event,
    Emitter<VisitState> emit,
  ) async {
    emit(VisitLoading());
    final result = await domainService.reviewWithComment(
      id: event.id,
      comment: event.comment,
    );
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      // CHANGED: removed add(VisitLoadAllRequested()) — it was overwriting
      // VisitOperationSuccess with VisitLoading/VisitListLoaded, causing the
      // black screen. The detail page listener handles reload via
      // VisitLoadOneRequested.
      (entity) =>
          emit(VisitOperationSuccess('Visit accepted', updatedItem: entity)),
    );
  }

  Future<void> _onFlag(
    VisitFlagRequested event,
    Emitter<VisitState> emit,
  ) async {
    emit(VisitLoading());
    final result = await domainService.flagWithComment(
      id: event.id,
      comment: event.comment,
    );
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      // CHANGED: same fix as _onReview — removed add(VisitLoadAllRequested()).
      (entity) =>
          emit(VisitOperationSuccess('Visit flagged', updatedItem: entity)),
    );
  }

  Future<void> _onUnflag(
    VisitUnflagRequested event,
    Emitter<VisitState> emit,
  ) async {
    emit(VisitLoading());
    final result = await domainService.unflagVisit(id: event.id);
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (entity) =>
          emit(VisitOperationSuccess('Flag removed', updatedItem: entity)),
    );
  }

  Future<void> _onLoadByCustomer(
    VisitLoadByCustomerRequested event,
    Emitter<VisitState> emit,
  ) async {
    emit(VisitLoading());
    final result = await getCustomerVisitsUseCase(
      GetCustomerVisitsParams(customerId: event.customerId),
    );
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (items) =>
          emit(CustomerVisitHistoryLoaded(items, customerId: event.customerId)),
    );
  }
}
