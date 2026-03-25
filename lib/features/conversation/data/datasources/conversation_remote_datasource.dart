import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../../domain/entities/message_entity.dart';

/// Full datasource interface for Nexora Communications API.
///
/// Extends the original Maishell CRUD interface with all message
/// operations. The BLoC should inject this instead of hardcoding
/// ConversationMockDataSource.
///
/// Scope logic: DM conversations use /communications/conversations/{id}/...
///              Group conversations use /communications/groups/{id}/...
///              The datasource resolves the scope from conversation type.
abstract class ConversationRemoteDataSource {
  // ── Original CRUD (Maishell) ──────────────────────────────
  Future<List<ConversationModel>> getAll();
  Future<ConversationModel>       getById(String id);
  Future<ConversationModel>       create(Map<String, dynamic> data);
  Future<ConversationModel>       update(String id, Map<String, dynamic> data);
  Future<void>                    delete(String id);

  // ── Messages ──────────────────────────────────────────────
  Future<List<MessageModel>> getMessages(String convId, {int perPage = 50});
  Future<MessageModel> sendMessage({
    required String convId,
    required String content,
    String? imageUrl,
    String? replyToId,
    String? replyToSenderName,
    String? replyToContent,
    List<String>? mentionedUserIds,
    String? forwardedFromConvId,
    String? forwardedFromSenderName,
    int? voiceDurationSeconds,
  });
  Future<void> deleteMessage(String convId, String msgId);
  Future<void> markAsRead(String convId);

  // ── Reactions ─────────────────────────────────────────────
  Future<void> addReaction(String convId, String msgId, String emoji);

  // ── Pins 🔴 MISSING API ──────────────────────────────────
  Future<void> togglePin(String convId, String msgId);
  List<MessageModel> getPinnedMessages(String convId);

  // ── Stars 🔴 MISSING API ─────────────────────────────────
  Future<void> toggleStar(String convId, String msgId);
  List<MessageModel> getStarredMessages();

  // ── Edit 🔴 MISSING API ──────────────────────────────────
  Future<void> editMessage(String convId, String msgId, String newContent);

  // ── Read Receipts ─────────────────────────────────────────
  Future<List<ReadReceipt>> getReadReceipts(String convId, String msgId);

  // ── Search (client-side for now) ──────────────────────────
  List<MessageModel> searchMessages(String convId, String query);

  // ── Conversation management ───────────────────────────────
  Future<void> closeConversation(String convId);
  Future<void> reopenConversation(String convId);

  // ── Group participants ────────────────────────────────────
  Future<void> addParticipant(String convId, String pId, String name, String role);
  Future<void> removeParticipant(String convId, String pId, String name);

  // ── Broadcast ─────────────────────────────────────────────
  Future<int> broadcastMessage(List<String> convIds, String content);

  // ── Private reply from group ──────────────────────────────
  Future<String> createPrivateFromGroup(
    String participantId, String participantName, String participantRole, String? message,
  );

  // ── Typing (no-op for REST, real implementation via WebSocket) ──
  // Typing indicators are client-side events dispatched via WebSocket/Pusher.
  // The datasource does not handle them — the BLoC manages typing state directly.

  // ── Callbacks for auto-reply simulation (mock only) ───────
  void Function(String conversationId, MessageModel message)? onAutoReply;
  void Function(String conversationId, String senderName)? onTypingStart;
  void Function(String conversationId)? onTypingStop;
}

/// Production implementation wired to Nexora Communications API.
///
/// Endpoints used:
///   DMs:        /api/v1/communications/conversations/...
///   Groups:     /api/v1/communications/groups/...
///   Broadcasts: /api/v1/communications/broadcasts/...
///   Presence:   /api/v1/communications/presence/...
///   Reactions:  /api/v1/communications/messages/{scope}/{id}/react
class ConversationRemoteDataSourceImpl implements ConversationRemoteDataSource {
  final Dio _dio;
  ConversationRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  static const _base = '/api/v1/communications';

  // Callbacks (unused in production — mock-only feature)
  @override void Function(String, MessageModel)? onAutoReply;
  @override void Function(String, String)? onTypingStart;
  @override void Function(String)? onTypingStop;

  // ── Track conversation types for scope resolution ─────────
  final Map<String, String> _typeCache = {}; // convId → 'direct' | 'group' | 'broadcast'

  String _scope(String convId) => _typeCache[convId] == 'group' ? 'groups' : 'conversations';
  String _msgScope(String convId) => _typeCache[convId] == 'group' ? 'group' : 'dm';

  // ── CRUD ──────────────────────────────────────────────────

  @override
  Future<List<ConversationModel>> getAll() async {
    try {
      // Fetch DMs + groups in parallel
      final dmFuture = _dio.get('$_base/conversations');
      final groupFuture = _dio.get('$_base/groups');
      final results = await Future.wait([dmFuture, groupFuture]);

      final dms = (results[0].data['data'] as List? ?? [])
          .map((e) { _typeCache[e['id']] = 'direct'; return ConversationModel.fromJson(e as Map<String, dynamic>); }).toList();
      final groups = (results[1].data['data'] as List? ?? [])
          .map((e) { _typeCache[e['id']] = 'group'; return ConversationModel.fromJson(e as Map<String, dynamic>); }).toList();

      final all = [...dms, ...groups];
      all.sort((a, b) => (b.lastMessageAt ?? b.createdAt).compareTo(a.lastMessageAt ?? a.createdAt));
      return all;
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ConversationModel> getById(String id) async {
    try {
      final scope = _scope(id);
      final r = await _dio.get('$_base/$scope/$id');
      _typeCache[id] = (r.data['type'] as String?) ?? _typeCache[id] ?? 'direct';
      return ConversationModel.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ConversationModel> create(Map<String, dynamic> data) async {
    try {
      final type = data['type'] as String? ?? 'direct';
      final endpoint = type == 'group' ? '$_base/groups' : '$_base/conversations';
      final body = type == 'group' ? data : {'recipient_actor_id': data['recipient_actor_id'] ?? data['participants']?.first?['id']};
      final r = await _dio.post(endpoint, data: body);
      final id = r.data['id'] as String? ?? '';
      _typeCache[id] = type;
      return ConversationModel.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ConversationModel> update(String id, Map<String, dynamic> data) async {
    try {
      final scope = _scope(id);
      final r = await _dio.patch('$_base/$scope/$id', data: data);
      return ConversationModel.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final scope = _scope(id);
      await _dio.delete('$_base/$scope/$id');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Messages ──────────────────────────────────────────────

  @override
  Future<List<MessageModel>> getMessages(String convId, {int perPage = 50}) async {
    try {
      final scope = _scope(convId);
      final r = await _dio.get('$_base/$scope/$convId/messages', queryParameters: {'per_page': perPage});
      final data = r.data is Map ? (r.data['data'] as List? ?? []) : (r.data as List? ?? []);
      return data.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String convId, required String content,
    String? imageUrl, String? replyToId, String? replyToSenderName,
    String? replyToContent, List<String>? mentionedUserIds,
    String? forwardedFromConvId, String? forwardedFromSenderName,
    int? voiceDurationSeconds,
  }) async {
    try {
      final scope = _scope(convId);
      String contentType = 'text';
      if (imageUrl != null) contentType = 'image';
      if (voiceDurationSeconds != null) contentType = 'audio';
      if (forwardedFromConvId != null) contentType = 'forwarded';

      final body = <String, dynamic>{
        'content': content,
        'content_type': contentType,
        if (replyToId != null) 'reply_to_id': replyToId,
        if (forwardedFromConvId != null) 'forwarded_from_id': forwardedFromConvId,
      };

      final r = await _dio.post('$_base/$scope/$convId/messages', data: body);
      return MessageModel.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> deleteMessage(String convId, String msgId) async {
    try {
      final scope = _msgScope(convId);
      await _dio.delete('$_base/messages/$scope/$msgId/everyone');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> markAsRead(String convId) async {
    try {
      final scope = _scope(convId);
      await _dio.post('$_base/$scope/$convId/read');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Reactions ─────────────────────────────────────────────

  @override
  Future<void> addReaction(String convId, String msgId, String emoji) async {
    try {
      final scope = _msgScope(convId);
      await _dio.post('$_base/messages/$scope/$msgId/react', data: {'emoji': emoji});
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Pins 🔴 MISSING API — calls will 404 until Laravel implements ──

  @override
  Future<void> togglePin(String convId, String msgId) async {
    try {
      final scope = _msgScope(convId);
      await _dio.post('$_base/messages/$scope/$msgId/pin');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  List<MessageModel> getPinnedMessages(String convId) {
    // 🔴 MISSING API — returns empty until endpoint is built
    // When available: GET /communications/{scope}/{convId}/pinned
    return [];
  }

  // ── Stars 🔴 MISSING API ─────────────────────────────────

  @override
  Future<void> toggleStar(String convId, String msgId) async {
    try {
      final scope = _msgScope(convId);
      await _dio.post('$_base/messages/$scope/$msgId/star');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  List<MessageModel> getStarredMessages() {
    // 🔴 MISSING API — returns empty until endpoint is built
    return [];
  }

  // ── Edit 🔴 MISSING API ──────────────────────────────────

  @override
  Future<void> editMessage(String convId, String msgId, String newContent) async {
    try {
      final scope = _msgScope(convId);
      await _dio.patch('$_base/messages/$scope/$msgId', data: {'content': newContent});
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Read Receipts ─────────────────────────────────────────

  @override
  Future<List<ReadReceipt>> getReadReceipts(String convId, String msgId) async {
    try {
      final scope = _msgScope(convId);
      final r = await _dio.get('$_base/messages/$scope/$msgId/receipts');
      final data = r.data['receipts'] as List? ?? [];
      return data.map((e) => ReadReceipt(
        userId: e['actor_id'] as String? ?? '',
        userName: e['name'] as String? ?? '',
        readAt: DateTime.parse(e['read_at'] as String),
      )).toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Search (client-side) ──────────────────────────────────

  @override
  List<MessageModel> searchMessages(String convId, String query) {
    // Client-side search — operates on already-loaded messages.
    // Server-side search would use GET .../search?q= when available.
    return [];
  }

  // ── Conversation management 🔴 MISSING API ───────────────

  @override
  Future<void> closeConversation(String convId) async {
    try {
      final scope = _scope(convId);
      await _dio.post('$_base/$scope/$convId/close');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> reopenConversation(String convId) async {
    try {
      final scope = _scope(convId);
      await _dio.post('$_base/$scope/$convId/reopen');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Group participants ────────────────────────────────────

  @override
  Future<void> addParticipant(String convId, String pId, String name, String role) async {
    try {
      await _dio.post('$_base/groups/$convId/participants', data: {'actor_id': pId});
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> removeParticipant(String convId, String pId, String name) async {
    try {
      await _dio.delete('$_base/groups/$convId/participants/$pId');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Broadcast ─────────────────────────────────────────────

  @override
  Future<int> broadcastMessage(List<String> convIds, String content) async {
    try {
      int sent = 0;
      for (final id in convIds) {
        await _dio.post('$_base/broadcasts/$id/messages', data: {'content': content, 'content_type': 'text'});
        sent++;
      }
      return sent;
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Private reply from group ──────────────────────────────

  @override
  Future<String> createPrivateFromGroup(
    String participantId, String participantName, String participantRole, String? message,
  ) async {
    try {
      // Create or retrieve DM with that participant
      final r = await _dio.post('$_base/conversations', data: {'recipient_actor_id': participantId});
      final convId = r.data['id'] as String;
      _typeCache[convId] = 'direct';

      // Send first message if provided
      if (message != null && message.isNotEmpty) {
        await _dio.post('$_base/conversations/$convId/messages', data: {'content': message, 'content_type': 'text'});
      }
      return convId;
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) return data['message'] as String;
    return 'An error occurred. Please try again.';
  }
}
