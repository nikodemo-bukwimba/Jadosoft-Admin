import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/create_conversation_usecase.dart';
import '../../domain/usecases/delete_conversation_usecase.dart';
import '../../domain/usecases/get_conversation_usecase.dart';
import '../../domain/usecases/get_all_conversation_usecase.dart';
import '../../domain/usecases/update_conversation_usecase.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final GetAllConversationUseCase  getAllUseCase;
  final GetConversationUseCase     getUseCase;
  final CreateConversationUseCase  createUseCase;
  final UpdateConversationUseCase  updateUseCase;
  final DeleteConversationUseCase  deleteUseCase;

  ConversationBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
  }) : super(ConversationInitial()) {
    on<ConversationLoadAllRequested>(_onLoadAll);
    on<ConversationLoadOneRequested>(_onLoadOne);
    on<ConversationCreateRequested>(_onCreate);
    on<ConversationUpdateRequested>(_onUpdate);
    on<ConversationDeleteRequested>(_onDelete);
    on<ConversationFormReset>((_, emit) => emit(ConversationInitial()));
  }

  Future<void> _onLoadAll(
      ConversationLoadAllRequested event, Emitter<ConversationState> emit) async {
    emit(ConversationLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(ConversationFailure(f.message)),
      (items) => items.isEmpty
          ? emit(ConversationEmpty())
          : emit(ConversationListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
      ConversationLoadOneRequested event, Emitter<ConversationState> emit) async {
    emit(ConversationLoading());
    final result = await getUseCase(GetConversationParams(id: event.id));
    result.fold(
      (f) => emit(ConversationFailure(f.message)),
      (item) => emit(ConversationDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
      ConversationCreateRequested event, Emitter<ConversationState> emit) async {
    emit(ConversationLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(ConversationFailure(f.message)),
      (_) => emit(ConversationOperationSuccess('Conversation created successfully')),
    );
  }

  Future<void> _onUpdate(
      ConversationUpdateRequested event, Emitter<ConversationState> emit) async {
    emit(ConversationLoading());
    final result = await updateUseCase(UpdateConversationParams(entity: event.entity));
    result.fold(
      (f) => emit(ConversationFailure(f.message)),
      (_) => emit(ConversationOperationSuccess('Conversation updated successfully')),
    );
  }

  Future<void> _onDelete(
      ConversationDeleteRequested event, Emitter<ConversationState> emit) async {
    emit(ConversationLoading());
    final result = await deleteUseCase(DeleteConversationParams(id: event.id));
    result.fold(
      (f) => emit(ConversationFailure(f.message)),
      (_) => emit(ConversationOperationSuccess('Conversation deleted successfully')),
    );
  }
}
