import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/create_actor_usecase.dart';
import '../../domain/usecases/delete_actor_usecase.dart';
import '../../domain/usecases/get_actor_usecase.dart';
import '../../domain/usecases/get_all_actor_usecase.dart';
import '../../domain/usecases/update_actor_usecase.dart';
import 'actor_event.dart';
import 'actor_state.dart';

class ActorBloc extends Bloc<ActorEvent, ActorState> {
  final GetAllActorUseCase  getAllUseCase;
  final GetActorUseCase     getUseCase;
  final CreateActorUseCase  createUseCase;
  final UpdateActorUseCase  updateUseCase;
  final DeleteActorUseCase  deleteUseCase;

  ActorBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
  }) : super(ActorInitial()) {
    on<ActorLoadAllRequested>(_onLoadAll);
    on<ActorLoadOneRequested>(_onLoadOne);
    on<ActorCreateRequested>(_onCreate);
    on<ActorUpdateRequested>(_onUpdate);
    on<ActorDeleteRequested>(_onDelete);
    on<ActorFormReset>((_, emit) => emit(ActorInitial()));
  }

  Future<void> _onLoadAll(
      ActorLoadAllRequested event, Emitter<ActorState> emit) async {
    emit(ActorLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(ActorFailure(f.message)),
      (items) => items.isEmpty
          ? emit(ActorEmpty())
          : emit(ActorListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
      ActorLoadOneRequested event, Emitter<ActorState> emit) async {
    emit(ActorLoading());
    final result = await getUseCase(GetActorParams(id: event.id));
    result.fold(
      (f) => emit(ActorFailure(f.message)),
      (item) => emit(ActorDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
      ActorCreateRequested event, Emitter<ActorState> emit) async {
    emit(ActorLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(ActorFailure(f.message)),
      (_) => emit(ActorOperationSuccess('Actor created successfully')),
    );
  }

  Future<void> _onUpdate(
      ActorUpdateRequested event, Emitter<ActorState> emit) async {
    emit(ActorLoading());
    final result = await updateUseCase(UpdateActorParams(entity: event.entity));
    result.fold(
      (f) => emit(ActorFailure(f.message)),
      (_) => emit(ActorOperationSuccess('Actor updated successfully')),
    );
  }

  Future<void> _onDelete(
      ActorDeleteRequested event, Emitter<ActorState> emit) async {
    emit(ActorLoading());
    final result = await deleteUseCase(DeleteActorParams(id: event.id));
    result.fold(
      (f) => emit(ActorFailure(f.message)),
      (_) => emit(ActorOperationSuccess('Actor deleted successfully')),
    );
  }
}
