import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../../domain/entities/message_entity.dart';

abstract class ConversationRemoteDataSource {
  Future<List<ConversationModel>> getAll();
  Future<ConversationModel> getById(String id);
  Future<ConversationModel> create(Map<String, dynamic> data);
  Future<ConversationModel> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);

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

  Future<void> addReaction(String convId, String msgId, String emoji);

  Future<void> togglePin(String convId, String msgId);
  List<MessageModel> getPinnedMessages(String convId);

  Future<void> toggleStar(String convId, String msgId);
  List<MessageModel> getStarredMessages();

  Future<void> editMessage(String convId, String msgId, String newContent);

  Future<List<ReadReceipt>> getReadReceipts(String convId, String msgId);

  List<MessageModel> searchMessages(String convId, String query);

  Future<void> closeConversation(String convId);
  Future<void> reopenConversation(String convId);

  Future<void> addParticipant(
    String convId,
    String pId,
    String name,
    String role,
  );
  Future<void> removeParticipant(String convId, String pId, String name);

  Future<int> broadcastMessage(List<String> convIds, String content);

  Future<String> createPrivateFromGroup(
    String participantId,
    String participantName,
    String participantRole,
    String? message,
  );

  void Function(String conversationId, MessageModel message)? onAutoReply;
  void Function(String conversationId, String senderName)? onTypingStart;
  void Function(String conversationId)? onTypingStop;
}

class ConversationRemoteDataSourceImpl implements ConversationRemoteDataSource {
  final Dio _dio;
  ConversationRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  static const _base = 'communications';

  @override
  void Function(String, MessageModel)? onAutoReply;
  @override
  void Function(String, String)? onTypingStart;
  @override
  void Function(String)? onTypingStop;

  final Map<String, String> _typeCache = {};

  String _scope(String convId) =>
      _typeCache[convId] == 'group' ? 'groups' : 'conversations';

  String _msgScope(String convId) =>
      _typeCache[convId] == 'group' ? 'group' : 'dm';

  // ── Normalizers ───────────────────────────────────────────

  /// Normalizes DirectConversation API shape → ConversationModel shape.
  /// The API returns initiator_actor_id / recipient_actor_id, not participants[].
  Map<String, dynamic> _normalizeDirect(Map<String, dynamic> j) {
    // Already has a non-empty participants array — no normalization needed
    final existing = j['participants'] as List?;
    if (existing != null && existing.isNotEmpty) return j;

    final initiatorId = j['initiator_actor_id'] as String? ?? '';
    final recipientId = j['recipient_actor_id'] as String? ?? '';
    final now = DateTime.now().toIso8601String();

    return {
      ...j,
      'type': 'direct',
      'status': j['status'] as String? ?? 'open',
      'unread_count': j['unread_count'] ?? 0,
      'created_at': j['created_at'] ?? now,
      'participants': [
        {
          'id': initiatorId,
          'name': j['initiator_name'] as String? ?? initiatorId,
          'role': j['initiator_role'] as String? ?? 'unknown',
          'joined_at': now,
          'online_status': 'offline',
          'last_seen_at': null,
        },
        {
          'id': recipientId,
          'name': j['recipient_name'] as String? ?? recipientId,
          'role': j['recipient_role'] as String? ?? 'unknown',
          'joined_at': now,
          'online_status': 'offline',
          'last_seen_at': null,
        },
      ],
    };
  }

  /// Normalizes Group API shape → ConversationModel shape.
  /// Group participants use actor_id not id.
  Map<String, dynamic> _normalizeGroup(Map<String, dynamic> j) {
    final rawP = j['participants'] as List<dynamic>? ?? [];
    final now = DateTime.now().toIso8601String();

    final participants = rawP.map((p) {
      final m = p as Map<String, dynamic>;
      // Group participants use actor_id field
      final id = m['actor_id'] as String? ?? m['id'] as String? ?? '';
      return {
        'id': id,
        'name': m['name'] as String? ?? id,
        'role': m['role'] as String? ?? 'member',
        'joined_at': m['created_at'] as String? ?? now,
        'online_status': 'offline',
        'last_seen_at': null,
      };
    }).toList();

    return {
      ...j,
      'type': 'group',
      'status': j['status'] as String? ?? 'open',
      'title': j['name'] as String? ?? j['title'] as String?,
      'participants': participants,
      'unread_count': j['unread_count'] ?? 0,
      'created_at': j['created_at'] ?? now,
    };
  }

  // ── CRUD ──────────────────────────────────────────────────

  @override
  Future<List<ConversationModel>> getAll() async {
    try {
      final dmFuture = _dio.get('$_base/conversations');
      final groupFuture = _dio.get('$_base/groups');
      final results = await Future.wait([dmFuture, groupFuture]);

      final dms = (results[0].data['data'] as List? ?? []).map((e) {
        final map = e as Map<String, dynamic>;
        _typeCache[map['id'] as String? ?? ''] = 'direct';
        return ConversationModel.fromJson(_normalizeDirect(map));
      }).toList();

      // Groups index returns a flat list (Collection, not paginated)
      final groupRaw = results[1].data;
      final groupList = groupRaw is List
          ? groupRaw
          : (groupRaw is Map ? (groupRaw['data'] as List? ?? []) : <dynamic>[]);

      final groups = groupList.map((e) {
        final map = e as Map<String, dynamic>;
        _typeCache[map['id'] as String? ?? ''] = 'group';
        return ConversationModel.fromJson(_normalizeGroup(map));
      }).toList();

      final all = [...dms, ...groups];
      all.sort(
        (a, b) => (b.lastMessageAt ?? b.createdAt).compareTo(
          a.lastMessageAt ?? a.createdAt,
        ),
      );
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
      final data = r.data as Map<String, dynamic>;

      // Update type cache from response if available
      final typeFromApi = data['type'] as String?;
      if (typeFromApi != null) {
        _typeCache[id] = typeFromApi == 'group' ? 'group' : 'direct';
      }

      final normalized = _typeCache[id] == 'group'
          ? _normalizeGroup(data)
          : _normalizeDirect(data);
      return ConversationModel.fromJson(normalized);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ConversationModel> create(Map<String, dynamic> data) async {
    try {
      final type = data['type'] as String? ?? 'direct';

      if (type == 'group') {
        final participants = data['participants'] as List<dynamic>? ?? [];
        // API only needs name + participant_ids (creator added automatically)
        final participantIds = participants
            .map((p) => (p as Map<String, dynamic>)['id'] as String?)
            .where((id) => id != null && id!.isNotEmpty)
            .toList();

        final body = <String, dynamic>{
          'name': data['title'] ?? data['name'] ?? 'Group Chat',
          if (data['description'] != null) 'description': data['description'],
          'participant_ids': participantIds,
        };

        final r = await _dio.post('$_base/groups', data: body);
        final responseData = r.data as Map<String, dynamic>;
        // Response may wrap in 'group' key
        final groupData = responseData['group'] is Map
            ? responseData['group'] as Map<String, dynamic>
            : responseData;
        final newId = groupData['id'] as String? ?? '';
        _typeCache[newId] = 'group';
        return ConversationModel.fromJson(_normalizeGroup(groupData));
      } else {
        // Direct conversation — API only needs recipient_actor_id
        final participants = data['participants'] as List<dynamic>? ?? [];
        final recipientId =
            data['recipient_actor_id'] as String? ??
            participants
                .map((p) => (p as Map<String, dynamic>)['id'] as String?)
                .where((id) => id != null && id!.isNotEmpty)
                .firstOrNull;

        final body = <String, dynamic>{'recipient_actor_id': recipientId};
        final r = await _dio.post('$_base/conversations', data: body);
        final conv = r.data as Map<String, dynamic>;
        final newId = conv['id'] as String? ?? '';
        _typeCache[newId] = 'direct';
        return ConversationModel.fromJson(_normalizeDirect(conv));
      }
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ConversationModel> update(String id, Map<String, dynamic> data) async {
    try {
      final scope = _scope(id);
      final r = await _dio.patch('$_base/$scope/$id', data: data);
      final normalized = _typeCache[id] == 'group'
          ? _normalizeGroup(r.data as Map<String, dynamic>)
          : _normalizeDirect(r.data as Map<String, dynamic>);
      return ConversationModel.fromJson(normalized);
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
  Future<List<MessageModel>> getMessages(
    String convId, {
    int perPage = 50,
  }) async {
    try {
      final scope = _scope(convId);
      final r = await _dio.get(
        '$_base/$scope/$convId/messages',
        queryParameters: {'per_page': perPage},
      );
      final raw = r.data;
      final list = raw is Map
          ? (raw['data'] as List? ?? [])
          : (raw as List? ?? []);

      final messages = list
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // API returns newest-first (desc) — reverse to chronological for UI
      return messages.reversed.toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
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
        if (forwardedFromConvId != null)
          'forwarded_from_id': forwardedFromConvId,
      };

      final r = await _dio.post('$_base/$scope/$convId/messages', data: body);
      // Response wraps message in 'data' key
      final msgData = r.data is Map && (r.data as Map).containsKey('data')
          ? r.data['data'] as Map<String, dynamic>
          : r.data as Map<String, dynamic>;
      return MessageModel.fromJson(msgData);
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
      await _dio.post(
        '$_base/messages/$scope/$msgId/react',
        data: {'emoji': emoji},
      );
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Pins ──────────────────────────────────────────────────

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
  List<MessageModel> getPinnedMessages(String convId) => [];

  // ── Stars ─────────────────────────────────────────────────

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
  List<MessageModel> getStarredMessages() => [];

  // ── Edit ──────────────────────────────────────────────────

  @override
  Future<void> editMessage(
    String convId,
    String msgId,
    String newContent,
  ) async {
    try {
      final scope = _msgScope(convId);
      await _dio.patch(
        '$_base/messages/$scope/$msgId',
        data: {'content': newContent},
      );
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
      return data
          .map(
            (e) => ReadReceipt(
              userId: e['actor_id'] as String? ?? '',
              userName: e['name'] as String? ?? '',
              readAt: DateTime.parse(e['read_at'] as String),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Search ────────────────────────────────────────────────

  @override
  List<MessageModel> searchMessages(String convId, String query) => [];

  // ── Conversation management ───────────────────────────────

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
  Future<void> addParticipant(
    String convId,
    String pId,
    String name,
    String role,
  ) async {
    try {
      await _dio.post(
        '$_base/groups/$convId/participants',
        data: {'actor_id': pId},
      );
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
        await _dio.post(
          '$_base/broadcasts/$id/messages',
          data: {'content': content, 'content_type': 'text'},
        );
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
    String participantId,
    String participantName,
    String participantRole,
    String? message,
  ) async {
    try {
      final r = await _dio.post(
        '$_base/conversations',
        data: {'recipient_actor_id': participantId},
      );
      final conv = r.data as Map<String, dynamic>;
      final convId = conv['id'] as String? ?? '';
      _typeCache[convId] = 'direct';

      if (message != null && message.isNotEmpty) {
        await _dio.post(
          '$_base/conversations/$convId/messages',
          data: {'content': message, 'content_type': 'text'},
        );
      }
      return convId;
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'An error occurred. Please try again.';
  }
}
