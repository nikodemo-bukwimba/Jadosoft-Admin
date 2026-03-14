import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/conversation_mock_datasource.dart';
import '../../domain/usecases/create_conversation_usecase.dart';
import '../../domain/usecases/delete_conversation_usecase.dart';
import '../../domain/usecases/get_conversation_usecase.dart';
import '../../domain/usecases/get_all_conversation_usecase.dart';
import '../../domain/usecases/update_conversation_usecase.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final GetAllConversationUseCase getAllUseCase;
  final GetConversationUseCase getUseCase;
  final CreateConversationUseCase createUseCase;
  final UpdateConversationUseCase updateUseCase;
  final DeleteConversationUseCase deleteUseCase;
  final ConversationMockDataSource _mockDs = ConversationMockDataSource();

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
    on<ConversationLoadMessagesRequested>(_onLoadMessages);
    on<ConversationSendMessageRequested>(_onSendMessage);
    on<ConversationAutoReplyReceived>(_onAutoReply);
    on<ConversationTypingStarted>(_onTypingStarted);
    on<ConversationTypingStopped>(_onTypingStopped);
    on<ConversationDeleteMessageRequested>(_onDeleteMessage);
    on<ConversationTogglePinRequested>(_onTogglePin);
    on<ConversationToggleStarRequested>(_onToggleStar);
    on<ConversationAddReactionRequested>(_onAddReaction);
    on<ConversationEditMessageRequested>(_onEditMessage);
    on<ConversationViewReadReceipts>(_onViewReadReceipts);
    on<ConversationSearchMessages>(_onSearchMessages);
    on<ConversationClearSearch>(_onClearSearch);
    on<ConversationForwardMessageRequested>(_onForwardMessage);
    on<ConversationBroadcastRequested>(_onBroadcast);
    on<ConversationCloseRequested>(_onClose);
    on<ConversationReopenRequested>(_onReopen);
    on<ConversationAddParticipantRequested>(_onAddParticipant);
    on<ConversationRemoveParticipantRequested>(_onRemoveParticipant);
    on<ConversationPrivateReplyRequested>(_onPrivateReply);
    on<ConversationStartNewRequested>(_onStartNew);

    _mockDs.onAutoReply = (convId, msg) {
      if (!isClosed) add(ConversationAutoReplyReceived(convId));
    };
    _mockDs.onTypingStart = (convId, name) {
      if (!isClosed) add(ConversationTypingStarted(convId, name));
    };
    _mockDs.onTypingStop = (convId) {
      if (!isClosed) add(ConversationTypingStopped(convId));
    };
  }

  Future<void> _reloadChat(
    String convId,
    Emitter<ConversationState> emit,
  ) async {
    final conv = await _mockDs.getById(convId);
    final msgs = await _mockDs.getMessages(convId);
    final pinned = _mockDs.getPinnedMessages(convId);
    final currentTyping = state is ConversationChatLoaded
        ? (state as ConversationChatLoaded).typingUser
        : null;
    final currentSearch = state is ConversationChatLoaded
        ? (state as ConversationChatLoaded).searchResults
        : null;
    final currentQuery = state is ConversationChatLoaded
        ? (state as ConversationChatLoaded).searchQuery
        : null;
    emit(
      ConversationChatLoaded(
        conversation: conv,
        messages: msgs,
        typingUser: currentTyping,
        pinnedMessages: pinned,
        searchResults: currentSearch,
        searchQuery: currentQuery,
      ),
    );
  }

  // ─── LIST ───
  Future<void> _onLoadAll(
    ConversationLoadAllRequested event,
    Emitter<ConversationState> emit,
  ) async {
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
    ConversationLoadOneRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationLoading());
    try {
      final conv = await _mockDs.getById(event.id);
      final msgs = await _mockDs.getMessages(event.id);
      final pinned = _mockDs.getPinnedMessages(event.id);
      emit(
        ConversationChatLoaded(
          conversation: conv,
          messages: msgs,
          pinnedMessages: pinned,
        ),
      );
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onCreate(
    ConversationCreateRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(ConversationFailure(f.message)),
      (_) => emit(ConversationOperationSuccess('Conversation created')),
    );
  }

  Future<void> _onUpdate(
    ConversationUpdateRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationLoading());
    final result = await updateUseCase(
      UpdateConversationParams(entity: event.entity),
    );
    result.fold(
      (f) => emit(ConversationFailure(f.message)),
      (_) => emit(ConversationOperationSuccess('Conversation updated')),
    );
  }

  Future<void> _onDelete(
    ConversationDeleteRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationLoading());
    final result = await deleteUseCase(DeleteConversationParams(id: event.id));
    result.fold(
      (f) => emit(ConversationFailure(f.message)),
      (_) => emit(ConversationOperationSuccess('Conversation deleted')),
    );
  }

  // ─── CHAT ───
  Future<void> _onLoadMessages(
    ConversationLoadMessagesRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationLoading());
    try {
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onSendMessage(
    ConversationSendMessageRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _mockDs.sendMessage(
        convId: event.conversationId,
        content: event.content,
        imageUrl: event.imageUrl,
        replyToId: event.replyToId,
        replyToSenderName: event.replyToSenderName,
        replyToContent: event.replyToContent,
        mentionedUserIds: event.mentionedUserIds,
        forwardedFromConvId: event.forwardedFromConvId,
        forwardedFromSenderName: event.forwardedFromSenderName,
        voiceDurationSeconds: event.voiceDurationSeconds,
      );
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onAutoReply(
    ConversationAutoReplyReceived event,
    Emitter<ConversationState> emit,
  ) async {
    if (state is! ConversationChatLoaded) return;
    if ((state as ConversationChatLoaded).conversation.id !=
        event.conversationId)
      return;
    try {
      await _reloadChat(event.conversationId, emit);
    } catch (_) {}
  }

  void _onTypingStarted(
    ConversationTypingStarted event,
    Emitter<ConversationState> emit,
  ) {
    if (state is! ConversationChatLoaded) return;
    final s = state as ConversationChatLoaded;
    if (s.conversation.id != event.conversationId) return;
    emit(s.copyWith(typingUser: event.senderName));
  }

  void _onTypingStopped(
    ConversationTypingStopped event,
    Emitter<ConversationState> emit,
  ) {
    if (state is! ConversationChatLoaded) return;
    final s = state as ConversationChatLoaded;
    if (s.conversation.id != event.conversationId) return;
    emit(s.copyWith(clearTyping: true));
  }

  // ─── MESSAGE OPS ───
  Future<void> _onDeleteMessage(
    ConversationDeleteMessageRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _mockDs.deleteMessage(event.conversationId, event.messageId);
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onTogglePin(
    ConversationTogglePinRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _mockDs.togglePin(event.conversationId, event.messageId);
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onToggleStar(
    ConversationToggleStarRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _mockDs.toggleStar(event.conversationId, event.messageId);
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onAddReaction(
    ConversationAddReactionRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _mockDs.addReaction(
        event.conversationId,
        event.messageId,
        event.emoji,
      );
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onEditMessage(
    ConversationEditMessageRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _mockDs.editMessage(
        event.conversationId,
        event.messageId,
        event.newContent,
      );
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onViewReadReceipts(
    ConversationViewReadReceipts event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final receipts = await _mockDs.getReadReceipts(
        event.conversationId,
        event.messageId,
      );
      emit(
        ConversationReadReceiptsLoaded(
          receipts: receipts,
          messageId: event.messageId,
        ),
      );
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  void _onSearchMessages(
    ConversationSearchMessages event,
    Emitter<ConversationState> emit,
  ) {
    if (state is! ConversationChatLoaded) return;
    final s = state as ConversationChatLoaded;
    if (event.query.isEmpty) {
      emit(s.copyWith(clearSearch: true));
      return;
    }
    final results = _mockDs.searchMessages(event.conversationId, event.query);
    emit(s.copyWith(searchResults: results, searchQuery: event.query));
  }

  void _onClearSearch(
    ConversationClearSearch event,
    Emitter<ConversationState> emit,
  ) {
    if (state is! ConversationChatLoaded) return;
    emit((state as ConversationChatLoaded).copyWith(clearSearch: true));
  }

  // ─── FORWARD ───
  Future<void> _onForwardMessage(
    ConversationForwardMessageRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _mockDs.sendMessage(
        convId: event.targetConversationId,
        content: event.content,
        forwardedFromConvId: event.originalConvId,
        forwardedFromSenderName: event.originalSenderName,
      );
      if (state is ConversationChatLoaded) {
        final s = state as ConversationChatLoaded;
        if (s.conversation.id == event.targetConversationId) {
          await _reloadChat(event.targetConversationId, emit);
        }
      }
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  // ─── BROADCAST ───
  Future<void> _onBroadcast(
    ConversationBroadcastRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final sent = await _mockDs.broadcastMessage(
        event.conversationIds,
        event.content,
      );
      emit(ConversationBroadcastSuccess(sent));
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  // ─── GROUP ───
  Future<void> _onClose(
    ConversationCloseRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _mockDs.closeConversation(event.conversationId);
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onReopen(
    ConversationReopenRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _mockDs.reopenConversation(event.conversationId);
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onAddParticipant(
    ConversationAddParticipantRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _mockDs.addParticipant(
        event.conversationId,
        event.participantId,
        event.name,
        event.role,
      );
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onRemoveParticipant(
    ConversationRemoveParticipantRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _mockDs.removeParticipant(
        event.conversationId,
        event.participantId,
        event.name,
      );
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  // ─── PRIVATE REPLY ───
  Future<void> _onPrivateReply(
    ConversationPrivateReplyRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final convId = await _mockDs.createPrivateFromGroup(
        event.participantId,
        event.participantName,
        event.participantRole,
        event.message,
      );
      emit(ConversationNewCreated(convId));
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  // ─── NEW CONVERSATION ───
  Future<void> _onStartNew(
    ConversationStartNewRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationLoading());
    try {
      final participantMaps = <Map<String, dynamic>>[
        {
          'id': kAdminId,
          'name': kAdminName,
          'role': kAdminRole,
          'joined_at': DateTime.now().toIso8601String(),
          'online_status': 'online',
          'last_seen_at': null,
        },
        ...event.participants.map(
          (p) => {
            'id': p['id']!,
            'name': p['name']!,
            'role': p['role']!,
            'joined_at': DateTime.now().toIso8601String(),
            'online_status': 'offline',
            'last_seen_at': null,
          },
        ),
      ];
      final conv = await _mockDs.create({
        'type': event.type,
        'title': event.title,
        'participants': participantMaps,
      });
      if (event.firstMessage != null && event.firstMessage!.isNotEmpty) {
        await _mockDs.sendMessage(
          convId: conv.id,
          content: event.firstMessage!,
        );
      }
      emit(ConversationNewCreated(conv.id));
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }
}
