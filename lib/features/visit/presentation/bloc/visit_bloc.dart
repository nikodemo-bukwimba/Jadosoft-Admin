// visit_bloc.dart
// Orchestrates CRUD and state machine transitions.
// Pure dispatcher — events in, states out.

import 'package:fca/features/visit/domain/usecases/create_isActive_usecase.dart';
import 'package:fca/features/visit/domain/usecases/delete_isActive_usecase.dart';
import 'package:fca/features/visit/domain/usecases/update_isActive_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/visit_repository.dart';
import '../../domain/usecases/get_visit_usecase.dart';
import '../../domain/usecases/get_all_visit_usecase.dart';



part 'visit_event.dart';
part 'visit_state.dart';

class VisitBloc extends Bloc<VisitEvent, VisitState> {
  final GetAllVisitUseCase  getAllUseCase;
  final GetVisitUseCase     getUseCase;
  final CreateVisitUseCase  createUseCase;
  final UpdateVisitUseCase  updateUseCase;
  final DeleteVisitUseCase  deleteUseCase;


  VisitBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
  }) : super(VisitInitial()) {
    on<VisitLoadAllRequested>(_onLoadAll);
    on<VisitLoadOneRequested>(_onLoadOne);
    on<VisitCreateRequested>(_onCreate);
    on<VisitUpdateRequested>(_onUpdate);
    on<VisitDeleteRequested>(_onDelete);
    on<VisitSearchChanged>(_onSearch);
    on<VisitFormReset>((_, emit) => emit(VisitInitial()));
  }

  Future<void> _onLoadAll(
      VisitLoadAllRequested event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    final result = await getAllUseCase(GetAllVisitParams(
      filters:    event.filters,
      sort:       event.sort,
      pagination: event.pagination,
    ));
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (items) => items.isEmpty
          ? emit(VisitEmpty())
          : emit(VisitListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
      VisitLoadOneRequested event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    final result = await getUseCase(GetVisitParams(id: event.id));
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (item) => emit(VisitDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
      VisitCreateRequested event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (_) => emit(VisitOperationSuccess('Visit created successfully')),
    );
  }

  Future<void> _onUpdate(
      VisitUpdateRequested event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    final result = await updateUseCase(UpdateVisitParams(entity: event.entity));
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (item) => emit(VisitOperationSuccess('Visit updated successfully', updatedItem: item)),
    );
  }

  Future<void> _onDelete(
      VisitDeleteRequested event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    final result = await deleteUseCase(DeleteVisitParams(id: event.id));
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (_) => emit(VisitOperationSuccess('Visit deleted successfully')),
    );
  }

  Future<void> _onSearch(
      VisitSearchChanged event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    final result = await getAllUseCase(const GetAllVisitParams());
    result.fold(
      (f) => emit(VisitFailure(f.message)),
      (items) {
        final filtered = items.where((item) =>
          item.toString().toLowerCase().contains(event.query.toLowerCase())
        ).toList();
        filtered.isEmpty
          ? emit(VisitEmpty())
          : emit(VisitListLoaded(filtered));
      },
    );
  }
}
