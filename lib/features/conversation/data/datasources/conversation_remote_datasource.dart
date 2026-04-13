// === FILE: lib/features/conversation/data/datasources/conversation_remote_datasource.dart ===
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  /// Actor-ID → display name cache, populated from conversations & messages.
  /// Used by the BLoC/UI to resolve ULIDs to human-readable names.
  Map<String, String> get nameCache;

  /// Register a known actor name (called during DI setup with current user).
  void registerName(String actorId, String name);
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

  /// Type cache: conversation ID → 'direct' | 'group'
  final Map<String, String> _typeCache = {};

  /// Actor-ID → display name cache.
  /// Populated from:
  ///   1. registerName() called at DI time with the current user
  ///   2. Participant data from getAll / getById responses
  ///   3. Message sender data from getMessages responses
  final Map<String, String> _nameCache = {};

  @override
  Map<String, String> get nameCache => Map.unmodifiable(_nameCache);

  @override
  void registerName(String actorId, String name) {
    if (actorId.isNotEmpty && name.isNotEmpty) {
      _nameCache[actorId] = name;
    }
  }

  /// Returns true if the value looks like a raw ULID (26 uppercase alphanumeric).
  bool _isUlid(String? v) {
    if (v == null || v.length != 26) return false;
    return RegExp(r'^[0-9A-Z]{26}$', caseSensitive: false).hasMatch(v);
  }

  /// Resolve a name: use cache if the raw value looks like a ULID.
  String _resolveName(String? raw, String? actorId) {
    // If we have a non-ULID name from the API, use it
    if (raw != null && raw.isNotEmpty && !_isUlid(raw)) {
      // Also cache it
      if (actorId != null && actorId.isNotEmpty) {
        _nameCache[actorId] = raw;
      }
      return raw;
    }
    // Try the cache
    final id = actorId ?? raw ?? '';
    if (_nameCache.containsKey(id)) return _nameCache[id]!;
    // Also try case-insensitive
    final lower = id.toLowerCase();
    for (final entry in _nameCache.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    // Last resort: return a truncated ID
    if (id.length > 8) {
      return '${id.substring(0, 4)}…${id.substring(id.length - 4)}';
    }
    return id.isNotEmpty ? id : 'Unknown';
  }

  /// Cache name from a participant map.
  void _cacheParticipantName(Map<String, dynamic> p) {
    final id = p['actor_id'] as String? ?? p['id'] as String? ?? '';
    final name =
        p['name'] as String? ??
        p['display_name'] as String? ??
        p['full_name'] as String? ??
        '';
    if (id.isNotEmpty && name.isNotEmpty && !_isUlid(name)) {
      _nameCache[id] = name;
    }
  }

  /// Unwraps a standard Laravel JSON resource response.
  /// API responses may be: `{...fields}`, `{"data": {...fields}}`,
  /// `{"group": {...fields}}`, or `{"data": {"group": {...fields}}}`.
  Map<String, dynamic> _unwrapResponse(dynamic raw, {String? wrapperKey}) {
    if (raw is! Map<String, dynamic>) return <String, dynamic>{};
    // Check for nested wrapper key first (e.g. 'group')
    if (wrapperKey != null && raw[wrapperKey] is Map) {
      return raw[wrapperKey] as Map<String, dynamic>;
    }
    // Standard Laravel 'data' wrapper
    if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
      final inner = raw['data'] as Map<String, dynamic>;
      // Could be {"data": {"group": {...}}}
      if (wrapperKey != null && inner[wrapperKey] is Map) {
        return inner[wrapperKey] as Map<String, dynamic>;
      }
      return inner;
    }
    return raw;
  }

  String _scope(String convId) =>
      _typeCache[convId] == 'group' ? 'groups' : 'conversations';

  String _msgScope(String convId) =>
      _typeCache[convId] == 'group' ? 'group' : 'dm';

  // ── Normalizers ───────────────────────────────────────────

  /// Normalizes DirectConversation API shape → ConversationModel shape.
  Map<String, dynamic> _normalizeDirect(Map<String, dynamic> j) {
    // ── Debug: log raw API data for DM normalization ──
    debugPrint(
      '  [_normalizeDirect] id=${j['id']} '
      'initiator=${j['initiator_actor_id']} '
      'recipient=${j['recipient_actor_id']} '
      'keys=${j.keys.take(10).join(',')}',
    );

    final existing = j['participants'] as List?;
    if (existing != null && existing.isNotEmpty) {
      // Cache names from existing participants
      for (final p in existing) {
        if (p is Map<String, dynamic>) {
          _cacheParticipantName(p);
        }
      }
      return j;
    }

    final initiatorId =
        j['initiator_actor_id'] as String? ??
        j['initiator_id'] as String? ??
        '';
    final recipientId =
        j['recipient_actor_id'] as String? ??
        j['recipient_id'] as String? ??
        '';
    final now = DateTime.now().toIso8601String();

    final initiatorName = _resolveName(
      j['initiator_name'] as String? ??
          j['initiator_display_name'] as String? ??
          j['initiator_full_name'] as String?,
      initiatorId,
    );
    final recipientName = _resolveName(
      j['recipient_name'] as String? ??
          j['recipient_display_name'] as String? ??
          j['recipient_full_name'] as String?,
      recipientId,
    );

    return {
      ...j,
      'type': 'direct',
      'status': j['status'] as String? ?? 'open',
      'unread_count': j['unread_count'] ?? 0,
      'created_at': j['created_at'] ?? now,
      'participants': [
        {
          'id': initiatorId,
          'name': initiatorName,
          'role': j['initiator_role'] as String? ?? 'unknown',
          'joined_at': now,
          'online_status': j['initiator_online_status'] as String? ?? 'offline',
          'last_seen_at': j['initiator_last_seen_at'],
        },
        {
          'id': recipientId,
          'name': recipientName,
          'role': j['recipient_role'] as String? ?? 'unknown',
          'joined_at': now,
          'online_status': j['recipient_online_status'] as String? ?? 'offline',
          'last_seen_at': j['recipient_last_seen_at'],
        },
      ],
    };
  }

  /// Normalizes Group API shape → ConversationModel shape.
  Map<String, dynamic> _normalizeGroup(Map<String, dynamic> j) {
    final rawP = j['participants'] as List<dynamic>? ?? [];
    final now = DateTime.now().toIso8601String();

    final participants = rawP.map((p) {
      final m = p as Map<String, dynamic>;
      final id = m['actor_id'] as String? ?? m['id'] as String? ?? '';

      // Cache the name
      _cacheParticipantName(m);

      final name = _resolveName(
        m['name'] as String? ??
            m['display_name'] as String? ??
            m['full_name'] as String?,
        id,
      );

      // Map super_admin → admin for display friendliness
      final rawRole = m['role'] as String? ?? 'member';

      return {
        'id': id,
        'name': name,
        'role': rawRole,
        'joined_at': m['created_at'] as String? ?? now,
        'online_status': m['online_status'] as String? ?? 'offline',
        'last_seen_at': m['last_seen_at'],
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

  /// Try to fetch presence for a list of actor IDs and update participant maps.
  Future<void> _enrichPresence(List<Map<String, dynamic>> participants) async {
    final actorIds = participants
        .map((p) => p['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    if (actorIds.isEmpty) return;

    try {
      final r = await _dio.post(
        '$_base/presence/bulk',
        data: {'actor_ids': actorIds},
      );
      final presenceList = r.data is List
          ? r.data as List
          : (r.data is Map ? (r.data['data'] as List? ?? []) : []);

      final presenceMap = <String, Map<String, dynamic>>{};
      for (final p in presenceList) {
        final m = p as Map<String, dynamic>;
        final aid = m['actor_id'] as String? ?? '';
        if (aid.isNotEmpty) {
          presenceMap[aid] = m;
        }
      }

      for (final participant in participants) {
        final pid = participant['id'] as String? ?? '';
        final presence = presenceMap[pid];
        if (presence != null) {
          participant['online_status'] = (presence['is_online'] == true)
              ? 'online'
              : 'offline';
          participant['last_seen_at'] = presence['last_seen_at'];
        }
      }
    } catch (_) {
      // Presence fetch is best-effort — don't fail the conversation load
    }
  }

  // ── Type detection for getById ────────────────────────────

  /// Detects conversation type from the API response data.
  /// The API returns different shapes for DMs vs groups.
  String _detectType(Map<String, dynamic> data) {
    // Explicit type field
    final typeField = data['type'] as String?;
    if (typeField == 'group') return 'group';
    if (typeField == 'direct') return 'direct';

    // Groups have 'name' field (group name), DMs don't
    if (data.containsKey('name') && data['name'] != null) return 'group';

    // Groups typically have 'participant_ids' or multiple participants
    if (data.containsKey('participant_ids')) return 'group';

    // DMs have initiator_actor_id / recipient_actor_id
    if (data.containsKey('initiator_actor_id') ||
        data.containsKey('recipient_actor_id'))
      return 'direct';

    // Default to whatever was cached, or 'direct'
    return 'direct';
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
      // If we don't know the type, try the cached scope first.
      // If it 404s and we tried 'conversations', retry with 'groups' (and vice versa).
      final cachedType = _typeCache[id];
      final primaryScope = cachedType == 'group' ? 'groups' : 'conversations';
      final fallbackScope = primaryScope == 'groups'
          ? 'conversations'
          : 'groups';

      Map<String, dynamic> data;
      try {
        final r = await _dio.get('$_base/$primaryScope/$id');
        data = _unwrapResponse(r.data);
      } on DioException catch (e) {
        // If 404 and we didn't have a cached type, try the other scope
        if (e.response?.statusCode == 404 && cachedType == null) {
          final r2 = await _dio.get('$_base/$fallbackScope/$id');
          data = _unwrapResponse(r2.data);
        } else {
          rethrow;
        }
      }

      // Detect and cache the type from response
      final detectedType = _detectType(data);
      _typeCache[id] = detectedType;

      final normalized = detectedType == 'group'
          ? _normalizeGroup(data)
          : _normalizeDirect(data);

      // Enrich with presence data (best-effort)
      final participantMaps = (normalized['participants'] as List)
          .cast<Map<String, dynamic>>();
      await _enrichPresence(participantMaps);

      // Rebuild model with enriched presence
      return ConversationModel.fromJson({
        ...normalized,
        'participants': participantMaps,
      });
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
        final selfId = data['_currentUserId'] as String?;

        // Cache names from the participant list we're sending
        for (final p in participants) {
          if (p is Map<String, dynamic>) {
            _cacheParticipantName(p);
          }
        }

        // Backend auto-adds creator — exclude self to avoid duplicate
        final participantIds = participants
            .map((p) => (p as Map<String, dynamic>)['id'] as String?)
            .where((id) => id != null && id.isNotEmpty && id != selfId)
            .toList();

        final body = <String, dynamic>{
          'name': data['title'] ?? data['name'] ?? 'Group Chat',
          if (data['description'] != null) 'description': data['description'],
          'participant_ids': participantIds,
        };

        final r = await _dio.post('$_base/groups', data: body);
        final groupData = _unwrapResponse(r.data, wrapperKey: 'group');
        final newId = groupData['id'] as String? ?? '';
        _typeCache[newId] = 'group';
        return ConversationModel.fromJson(_normalizeGroup(groupData));
      } else {
        final participants = data['participants'] as List<dynamic>? ?? [];

        // Cache names from the participant list
        for (final p in participants) {
          if (p is Map<String, dynamic>) {
            _cacheParticipantName(p);
          }
        }

        final recipientId =
            data['recipient_actor_id'] as String? ??
            participants
                .map((p) => (p as Map<String, dynamic>)['id'] as String?)
                .where((id) => id != null && id.isNotEmpty)
                .firstOrNull;

        final body = <String, dynamic>{'recipient_actor_id': recipientId};
        final r = await _dio.post('$_base/conversations', data: body);
        final conv = _unwrapResponse(r.data);
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
      final unwrapped = _unwrapResponse(r.data);
      final normalized = _typeCache[id] == 'group'
          ? _normalizeGroup(unwrapped)
          : _normalizeDirect(unwrapped);
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

      final messages = list.map((e) {
        final msgMap = e as Map<String, dynamic>;
        // Resolve sender name from cache if API returns only actor_id
        final senderId =
            msgMap['sender_actor_id'] as String? ??
            msgMap['sender_id'] as String? ??
            '';
        final rawSenderName = msgMap['sender_name'] as String?;
        final resolvedName = _resolveName(rawSenderName, senderId);
        // Inject resolved name back into the map before parsing
        msgMap['sender_name'] = resolvedName;
        return MessageModel.fromJson(msgMap);
      }).toList();

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
        'reply_to_id': replyToId,
        'forwarded_from_id': forwardedFromConvId,
      };

      final r = await _dio.post('$_base/$scope/$convId/messages', data: body);
      final msgData = _unwrapResponse(r.data);

      // Resolve sender name
      final senderId =
          msgData['sender_actor_id'] as String? ??
          msgData['sender_id'] as String? ??
          '';
      msgData['sender_name'] = _resolveName(
        msgData['sender_name'] as String?,
        senderId,
      );

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
      return data.map((e) {
        final actorId = e['actor_id'] as String? ?? '';
        return ReadReceipt(
          userId: actorId,
          userName: _resolveName(e['name'] as String?, actorId),
          readAt: DateTime.parse(e['read_at'] as String),
        );
      }).toList();
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
      // Cache the added participant's name
      if (name.isNotEmpty && !_isUlid(name)) {
        _nameCache[pId] = name;
      }
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
        final scope = _scope(id);
        await _dio.post(
          '$_base/$scope/$id/messages',
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
      // Cache the participant name
      if (participantName.isNotEmpty && !_isUlid(participantName)) {
        _nameCache[participantId] = participantName;
      }

      final r = await _dio.post(
        '$_base/conversations',
        data: {'recipient_actor_id': participantId},
      );
      final conv = _unwrapResponse(r.data);
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
