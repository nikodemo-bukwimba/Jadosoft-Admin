import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/create_hello_usecase.dart';
import '../../domain/usecases/delete_hello_usecase.dart';
import '../../domain/usecases/get_hello_usecase.dart';
import '../../domain/usecases/get_all_hello_usecase.dart';
import '../../domain/usecases/update_hello_usecase.dart';
import 'hello_event.dart';
import 'hello_state.dart';

class HelloBloc extends Bloc<HelloEvent, HelloState> {
  final GetAllHelloUseCase  getAllUseCase;
  final GetHelloUseCase     getUseCase;
  final CreateHelloUseCase  createUseCase;
  final UpdateHelloUseCase  updateUseCase;
  final DeleteHelloUseCase  deleteUseCase;

  HelloBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
  }) : super(HelloInitial()) {
    on<HelloLoadAllRequested>(_onLoadAll);
    on<HelloLoadOneRequested>(_onLoadOne);
    on<HelloCreateRequested>(_onCreate);
    on<HelloUpdateRequested>(_onUpdate);
    on<HelloDeleteRequested>(_onDelete);
    on<HelloFormReset>((_, emit) => emit(HelloInitial()));
  }

  Future<void> _onLoadAll(
      HelloLoadAllRequested event, Emitter<HelloState> emit) async {
    emit(HelloLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(HelloFailure(f.message)),
      (items) => items.isEmpty
          ? emit(HelloEmpty())
          : emit(HelloListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
      HelloLoadOneRequested event, Emitter<HelloState> emit) async {
    emit(HelloLoading());
    final result = await getUseCase(GetHelloParams(id: event.id));
    result.fold(
      (f) => emit(HelloFailure(f.message)),
      (item) => emit(HelloDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
      HelloCreateRequested event, Emitter<HelloState> emit) async {
    emit(HelloLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(HelloFailure(f.message)),
      (_) => emit(HelloOperationSuccess('Hello created successfully')),
    );
  }

  Future<void> _onUpdate(
      HelloUpdateRequested event, Emitter<HelloState> emit) async {
    emit(HelloLoading());
    final result = await updateUseCase(UpdateHelloParams(entity: event.entity));
    result.fold(
      (f) => emit(HelloFailure(f.message)),
      (_) => emit(HelloOperationSuccess('Hello updated successfully')),
    );
  }

  Future<void> _onDelete(
      HelloDeleteRequested event, Emitter<HelloState> emit) async {
    emit(HelloLoading());
    final result = await deleteUseCase(DeleteHelloParams(id: event.id));
    result.fold(
      (f) => emit(HelloFailure(f.message)),
      (_) => emit(HelloOperationSuccess('Hello deleted successfully')),
    );
  }
}
