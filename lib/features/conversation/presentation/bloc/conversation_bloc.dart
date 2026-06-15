// === FILE: lib/features/conversation/presentation/bloc/conversation_bloc.dart ===
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/conversation_remote_datasource.dart';
import '../../domain/usecases/create_conversation_usecase.dart';
import '../../domain/usecases/delete_conversation_usecase.dart';
import '../../domain/usecases/get_all_conversation_usecase.dart';
import '../../domain/usecases/get_conversation_usecase.dart';
import '../../domain/usecases/update_conversation_usecase.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final GetAllConversationUseCase getAllUseCase;
  final GetConversationUseCase getUseCase;
  final CreateConversationUseCase createUseCase;
  final UpdateConversationUseCase updateUseCase;
  final DeleteConversationUseCase deleteUseCase;

  final ConversationRemoteDataSource _ds;

  final String currentUserId;
  final String currentUserName;
  final String currentUserRole;

  // ── Polling ───────────────────────────────────────────────
  // Only fetches getMessages() on each tick — never getById().
  // This avoids rebuilding the conversation widget tree so the
  // keyboard and TextField focus are never disrupted while typing.
  static const _pollInterval = Duration(seconds: 6);
  Timer? _pollTimer;
  String? _activeConvId;

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
  }) : _ds = dataSource,
       super(ConversationInitial()) {
    _ds.registerName(currentUserId, currentUserName);

    debugPrint('╔══════════════════════════════════╗');
    debugPrint('║ ConversationBloc identity        ║');
    debugPrint('║ userId:   $currentUserId');
    debugPrint('║ userName: $currentUserName');
    debugPrint('║ role:     $currentUserRole');
    debugPrint('╚══════════════════════════════════╝');

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
    on<_ConversationPollTick>(_onPollTick);

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

  // ── Polling ───────────────────────────────────────────────

  void _startPolling(String convId) {
    if (_activeConvId == convId && _pollTimer?.isActive == true) return;
    _stopPolling();
    _activeConvId = convId;
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!isClosed && _activeConvId != null) {
        add(_ConversationPollTick(_activeConvId!));
      }
    });
    debugPrint('[ConvBloc] polling $convId every ${_pollInterval.inSeconds}s');
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _activeConvId = null;
  }

  /// Message-only silent poll.
  ///
  /// Calls only getMessages() — NOT getById().
  /// Emits only when there are genuinely new message IDs.
  /// Preserves typingUser and searchResults via copyWith.
  Future<void> _onPollTick(
    _ConversationPollTick event,
    Emitter<ConversationState> emit,
  ) async {
    if (state is! ConversationChatLoaded) return;
    final current = state as ConversationChatLoaded;
    if (current.conversation.id != event.convId) return;

    try {
      final newMsgs = await _ds.getMessages(event.convId);
      final currentIds = current.messages.map((m) => m.id).toSet();
      final hasNew = newMsgs.any((m) => !currentIds.contains(m.id));
      if (!hasNew) return;

      _ds.markAsRead(event.convId).ignore();

      // copyWith preserves typingUser + search — no focus disruption
      emit(current.copyWith(messages: newMsgs));
    } catch (_) {
      // Silent — never surfaces to user
    }
  }

  Future<Map<String, dynamic>> uploadAttachment(String filePath) =>
      _ds.uploadAttachment(filePath);

  // ── Helpers ───────────────────────────────────────────────

  Future<void> _reloadChat(
    String convId,
    Emitter<ConversationState> emit,
  ) async {
    final conv = await _ds.getById(convId);
    final msgs = await _ds.getMessages(convId);
    final pinned = _ds.getPinnedMessages(convId);

    debugPrint('┌─ reloadChat($convId)');
    for (final p in conv.participants) {
      final me = p.id.toLowerCase() == currentUserId.toLowerCase();
      debugPrint('│  ${me ? '✓' : ' '} ${p.name} (${p.id})');
    }
    debugPrint('└─ ${msgs.length} messages');

    final prev = state is ConversationChatLoaded
        ? state as ConversationChatLoaded
        : null;
    emit(
      ConversationChatLoaded(
        conversation: conv,
        messages: msgs,
        typingUser: prev?.typingUser,
        pinnedMessages: pinned,
        searchResults: prev?.searchResults,
        searchQuery: prev?.searchQuery,
      ),
    );
  }

  // ── LIST ──────────────────────────────────────────────────

  Future<void> _onLoadAll(
    ConversationLoadAllRequested event,
    Emitter<ConversationState> emit,
  ) async {
    _stopPolling();
    emit(ConversationLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(ConversationFailure(f.message)),
      (items) => items.isEmpty
          ? emit(ConversationEmpty())
          : emit(ConversationListLoaded(items)),
    );
  }

  // ── CHAT ──────────────────────────────────────────────────

  Future<void> _onLoadOne(
    ConversationLoadOneRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationLoading());
    try {
      await _reloadChat(event.id, emit);
      _ds.markAsRead(event.id).ignore();
      _startPolling(event.id);
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  Future<void> _onLoadMessages(
    ConversationLoadMessagesRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationLoading());
    try {
      await _reloadChat(event.conversationId, emit);
      _startPolling(event.conversationId);
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

        // NEW
        attachmentId: event.attachmentId,
        attachmentType: event.attachmentType,

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

  // ── CRUD ──────────────────────────────────────────────────

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

  // ── Typing ────────────────────────────────────────────────

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

  // ── Message ops ───────────────────────────────────────────

  Future<void> _onDeleteMessage(
    ConversationDeleteMessageRequested e,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.deleteMessage(e.conversationId, e.messageId);
      await _reloadChat(e.conversationId, emit);
    } catch (ex) {
      emit(ConversationFailure(ex.toString()));
    }
  }

  Future<void> _onTogglePin(
    ConversationTogglePinRequested e,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.togglePin(e.conversationId, e.messageId);
      await _reloadChat(e.conversationId, emit);
    } catch (ex) {
      emit(ConversationFailure(ex.toString()));
    }
  }

  Future<void> _onToggleStar(
    ConversationToggleStarRequested e,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.toggleStar(e.conversationId, e.messageId);
      await _reloadChat(e.conversationId, emit);
    } catch (ex) {
      emit(ConversationFailure(ex.toString()));
    }
  }

  Future<void> _onAddReaction(
    ConversationAddReactionRequested e,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.addReaction(e.conversationId, e.messageId, e.emoji);
      await _reloadChat(e.conversationId, emit);
    } catch (ex) {
      emit(ConversationFailure(ex.toString()));
    }
  }

  Future<void> _onEditMessage(
    ConversationEditMessageRequested e,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.editMessage(e.conversationId, e.messageId, e.newContent);
      await _reloadChat(e.conversationId, emit);
    } catch (ex) {
      emit(ConversationFailure(ex.toString()));
    }
  }

  Future<void> _onViewReadReceipts(
    ConversationViewReadReceipts e,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final receipts = await _ds.getReadReceipts(e.conversationId, e.messageId);
      emit(
        ConversationReadReceiptsLoaded(
          receipts: receipts,
          messageId: e.messageId,
        ),
      );
    } catch (ex) {
      emit(ConversationFailure(ex.toString()));
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
    final results = _ds.searchMessages(event.conversationId, event.query);
    final effective = results.isNotEmpty
        ? results
        : s.messages
              .where(
                (m) =>
                    m.content.toLowerCase().contains(event.query.toLowerCase()),
              )
              .toList();
    emit(s.copyWith(searchResults: effective, searchQuery: event.query));
  }

  void _onClearSearch(
    ConversationClearSearch e,
    Emitter<ConversationState> emit,
  ) {
    if (state is! ConversationChatLoaded) return;
    emit((state as ConversationChatLoaded).copyWith(clearSearch: true));
  }

  Future<void> _onForwardMessage(
    ConversationForwardMessageRequested e,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.sendMessage(
        convId: e.targetConversationId,
        content: e.content,
        forwardedFromConvId: e.originalConvId,
        forwardedFromSenderName: e.originalSenderName,
      );
      if (state is ConversationChatLoaded &&
          (state as ConversationChatLoaded).conversation.id ==
              e.targetConversationId) {
        await _reloadChat(e.targetConversationId, emit);
      }
    } catch (ex) {
      emit(ConversationFailure(ex.toString()));
    }
  }

  Future<void> _onBroadcast(
    ConversationBroadcastRequested e,
    Emitter<ConversationState> emit,
  ) async {
    try {
      emit(
        ConversationBroadcastSuccess(
          await _ds.broadcastMessage(e.conversationIds, e.content),
        ),
      );
    } catch (ex) {
      emit(ConversationFailure(ex.toString()));
    }
  }

  Future<void> _onClose(
    ConversationCloseRequested e,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.closeConversation(e.conversationId);
      await _reloadChat(e.conversationId, emit);
    } catch (ex) {
      emit(ConversationFailure(ex.toString()));
    }
  }

  Future<void> _onReopen(
    ConversationReopenRequested e,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.reopenConversation(e.conversationId);
      await _reloadChat(e.conversationId, emit);
    } catch (ex) {
      emit(ConversationFailure(ex.toString()));
    }
  }

  Future<void> _onAddParticipant(
    ConversationAddParticipantRequested e,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.addParticipant(
        e.conversationId,
        e.participantId,
        e.name,
        e.role,
      );
      await _reloadChat(e.conversationId, emit);
    } catch (ex) {
      emit(ConversationFailure(ex.toString()));
    }
  }

  Future<void> _onRemoveParticipant(
    ConversationRemoveParticipantRequested e,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _ds.removeParticipant(e.conversationId, e.participantId, e.name);
      await _reloadChat(e.conversationId, emit);
    } catch (ex) {
      emit(ConversationFailure(ex.toString()));
    }
  }

  Future<void> _onPrivateReply(
    ConversationPrivateReplyRequested e,
    Emitter<ConversationState> emit,
  ) async {
    try {
      emit(
        ConversationNewCreated(
          await _ds.createPrivateFromGroup(
            e.participantId,
            e.participantName,
            e.participantRole,
            e.message,
          ),
        ),
      );
    } catch (ex) {
      emit(ConversationFailure(ex.toString()));
    }
  }

  Future<void> _onStartNew(
    ConversationStartNewRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationLoading());
    try {
      for (final p in event.participants) {
        final id = p['id'] ?? '';
        final name = p['name'] ?? '';
        if (id.isNotEmpty && name.isNotEmpty) _ds.registerName(id, name);
      }
      final now = DateTime.now().toIso8601String();
      final pMaps = <Map<String, dynamic>>[
        {
          'id': currentUserId,
          'name': currentUserName,
          'role': currentUserRole,
          'joined_at': now,
          'online_status': 'online',
          'last_seen_at': null,
        },
        ...event.participants.map(
          (p) => {
            'id': p['id']!,
            'name': p['name']!,
            'role': p['role']!,
            'joined_at': now,
            'online_status': 'offline',
            'last_seen_at': null,
          },
        ),
      ];
      final body = event.type == 'group'
          ? {
              'type': event.type,
              'title': event.title,
              '_currentUserId': currentUserId,
              'participants': pMaps,
            }
          : {
              'type': event.type,
              'recipient_actor_id': event.participants.first['id'],
              'participants': pMaps,
            };
      final conv = await _ds.create(body);
      if (event.firstMessage != null && event.firstMessage!.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        await _ds.sendMessage(convId: conv.id, content: event.firstMessage!);
      }
      emit(ConversationNewCreated(conv.id));
    } catch (e) {
      emit(ConversationFailure(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}

class _ConversationPollTick extends ConversationEvent {
  final String convId;
  _ConversationPollTick(this.convId);
  List<Object?> get props => [convId];
}
