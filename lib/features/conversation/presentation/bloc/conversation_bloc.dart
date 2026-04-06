import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/conversation_remote_datasource.dart';
import '../../domain/usecases/create_conversation_usecase.dart';
import '../../domain/usecases/delete_conversation_usecase.dart';
import '../../domain/usecases/get_conversation_usecase.dart';
import '../../domain/usecases/get_all_conversation_usecase.dart';
import '../../domain/usecases/update_conversation_usecase.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

// Admin identity is resolved from the authenticated session at runtime.
// Injected via [ConversationBloc] constructor so the BLoC has no
// hard-coded credential references.
class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final GetAllConversationUseCase getAllUseCase;
  final GetConversationUseCase getUseCase;
  final CreateConversationUseCase createUseCase;
  final UpdateConversationUseCase updateUseCase;
  final DeleteConversationUseCase deleteUseCase;

  // ── Production datasource (injected) ──────────────────────────────────
  // The BLoC no longer owns a ConversationMockDataSource singleton.
  // The concrete type is ConversationRemoteDataSourceImpl in production and
  // ConversationMockDataSource in tests/dev via the same interface.
  final ConversationRemoteDataSource _ds;

  // Current user identity — provided by the auth session at injection time.
  final String currentUserId;
  final String currentUserName;
  final String currentUserRole;

  ConversationBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
    required ConversationRemoteDataSource dataSource,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserRole,
  })  : _ds = dataSource,
        super(ConversationInitial()) {
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

    // Real-time callbacks — no-op in REST mode; populated by WebSocket/Pusher
    // layer when present. The interface contract is identical to mock.
    _ds.onAutoReply = (convId, _) {
      if (!isClosed) add(ConversationAutoReplyReceived(convId));
    };
    _ds.onTypingStart = (convId, name) {
      if (!isClosed) add(ConversationTypingStarted(convId, name));
    };
    _ds.onTypingStop = (convId) {
      if (!isClosed) add(ConversationTypingStopped(convId));
    };
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Future<void> _reloadChat(
    String convId,
    Emitter<ConversationState> emit,
  ) async {
    final conv = await _ds.getById(convId);
    final msgs = await _ds.getMessages(convId);
    final pinned = _ds.getPinnedMessages(convId);
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

  // ── LIST ──────────────────────────────────────────────────────────────

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
      await _reloadChat(event.id, emit);
      // Mark conversation as read on open
      await _ds.markAsRead(event.id);
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

  // ── CHAT ──────────────────────────────────────────────────────────────

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
      await _ds.sendMessage(
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
        event.conversationId) return;
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

  // ── MESSAGE OPS ───────────────────────────────────────────────────────

  Future<void> _onDeleteMessage(
    ConversationDeleteMessageRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.deleteMessage(event.conversationId, event.messageId);
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
      await _ds.togglePin(event.conversationId, event.messageId);
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      // 🔴 Pin endpoint not yet available — silently ignore 404
      // Remove the catch once the API implements /messages/{scope}/{id}/pin
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onToggleStar(
    ConversationToggleStarRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.toggleStar(event.conversationId, event.messageId);
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      // 🔴 Star endpoint not yet available
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onAddReaction(
    ConversationAddReactionRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.addReaction(
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
      await _ds.editMessage(
        event.conversationId,
        event.messageId,
        event.newContent,
      );
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      // 🔴 Edit endpoint not yet available
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onViewReadReceipts(
    ConversationViewReadReceipts event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final receipts = await _ds.getReadReceipts(
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
    // Client-side search over already-loaded messages
    final results = _ds.searchMessages(event.conversationId, event.query);
    // Fallback: if the datasource returns empty (API impl), search in-memory
    final effective = results.isNotEmpty
        ? results
        : s.messages
              .where(
                (m) => m.content
                    .toLowerCase()
                    .contains(event.query.toLowerCase()),
              )
              .toList();
    emit(s.copyWith(searchResults: effective, searchQuery: event.query));
  }

  void _onClearSearch(
    ConversationClearSearch event,
    Emitter<ConversationState> emit,
  ) {
    if (state is! ConversationChatLoaded) return;
    emit((state as ConversationChatLoaded).copyWith(clearSearch: true));
  }

  // ── FORWARD ──────────────────────────────────────────────────────────

  Future<void> _onForwardMessage(
    ConversationForwardMessageRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.sendMessage(
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

  // ── BROADCAST ─────────────────────────────────────────────────────────

  Future<void> _onBroadcast(
    ConversationBroadcastRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final sent = await _ds.broadcastMessage(
        event.conversationIds,
        event.content,
      );
      emit(ConversationBroadcastSuccess(sent));
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  // ── GROUP MANAGEMENT ─────────────────────────────────────────────────

  Future<void> _onClose(
    ConversationCloseRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.closeConversation(event.conversationId);
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
      await _ds.reopenConversation(event.conversationId);
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
      await _ds.addParticipant(
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
      await _ds.removeParticipant(
        event.conversationId,
        event.participantId,
        event.name,
      );
      await _reloadChat(event.conversationId, emit);
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  // ── PRIVATE REPLY ────────────────────────────────────────────────────

  Future<void> _onPrivateReply(
    ConversationPrivateReplyRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final convId = await _ds.createPrivateFromGroup(
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

  // ── NEW CONVERSATION ─────────────────────────────────────────────────

  Future<void> _onStartNew(
    ConversationStartNewRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationLoading());
    try {
      final participantMaps = <Map<String, dynamic>>[
        {
          'id': currentUserId,
          'name': currentUserName,
          'role': currentUserRole,
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

      // For direct conversations the API only needs recipient_actor_id
      final body = event.type == 'group'
          ? {
              'type': event.type,
              'title': event.title,
              'participants': participantMaps,
            }
          : {
              'type': event.type,
              'recipient_actor_id': event.participants.first['id'],
              'participants': participantMaps,
            };

      final conv = await _ds.create(body);

      if (event.firstMessage != null && event.firstMessage!.isNotEmpty) {
        await _ds.sendMessage(
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