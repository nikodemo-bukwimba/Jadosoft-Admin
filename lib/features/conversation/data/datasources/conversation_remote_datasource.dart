// lib/features/conversation/data/datasources/conversation_remote_datasource.dart
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
    String? attachmentId,
    String? attachmentType,
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

  /// Upload a file attachment before sending a message.
  /// Returns { id, url, file_url, type, name, size, mime }.
  Future<Map<String, dynamic>> uploadAttachment(String filePath);

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
  final Map<String, String> _nameCache = {};

  @override
  Map<String, String> get nameCache => Map.unmodifiable(_nameCache);

  @override
  void registerName(String actorId, String name) {
    if (actorId.isNotEmpty && name.isNotEmpty) {
      _nameCache[actorId] = name;
    }
  }

  @override
  Future<Map<String, dynamic>> uploadAttachment(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final r = await _dio.post(
        '$_base/attachments/upload',
        data: formData,
        options: Options(
          headers: {'Accept': 'application/json'},
          contentType: 'multipart/form-data',
        ),
      );
      final body = r.data as Map<String, dynamic>;
      final att = body['attachment'] as Map<String, dynamic>? ?? body;
      return Map<String, dynamic>.from(att);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  bool _isUlid(String? v) {
    if (v == null || v.length != 26) return false;
    return RegExp(r'^[0-9A-Z]{26}$', caseSensitive: false).hasMatch(v);
  }

  String _resolveName(String? raw, String? actorId) {
    if (raw != null && raw.isNotEmpty && !_isUlid(raw)) {
      if (actorId != null && actorId.isNotEmpty) {
        _nameCache[actorId] = raw;
      }
      return raw;
    }
    final id = actorId ?? raw ?? '';
    if (_nameCache.containsKey(id)) return _nameCache[id]!;
    final lower = id.toLowerCase();
    for (final entry in _nameCache.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    if (id.length > 8) {
      return '${id.substring(0, 4)}…${id.substring(id.length - 4)}';
    }
    return id.isNotEmpty ? id : 'Unknown';
  }

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

  Map<String, dynamic> _unwrapResponse(dynamic raw, {String? wrapperKey}) {
    if (raw is! Map<String, dynamic>) return <String, dynamic>{};
    if (wrapperKey != null && raw[wrapperKey] is Map) {
      return raw[wrapperKey] as Map<String, dynamic>;
    }
    if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
      final inner = raw['data'] as Map<String, dynamic>;
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

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'An error occurred. Please try again.';
  }

  // ── Name resolution ───────────────────────────────────────

  Future<void> _resolveActorNames(List<String> actorIds) async {
    if (actorIds.isEmpty) return;

    final needed = actorIds.where((id) => !_nameCache.containsKey(id)).toList();
    if (needed.isEmpty) return;

    // 1. Presence bulk endpoint
    try {
      final r = await _dio.post(
        '$_base/presence/bulk',
        data: {'actor_ids': needed},
      );
      final list = r.data is List
          ? r.data as List
          : (r.data is Map ? (r.data['data'] as List? ?? []) : []);
      for (final p in list) {
        final m = p as Map<String, dynamic>;
        final aid = m['actor_id'] as String? ?? '';
        final name =
            m['name'] as String? ??
            m['display_name'] as String? ??
            m['full_name'] as String? ??
            '';
        if (aid.isNotEmpty && name.isNotEmpty && !_isUlid(name)) {
          _nameCache[aid] = name;
        }
      }
    } catch (_) {}

    // 2. Platform actors fallback
    final stillMissing = needed
        .where((id) => !_nameCache.containsKey(id))
        .toList();
    if (stillMissing.isEmpty) return;

    try {
      final r = await _dio.get(
        'api/v1/actors',
        queryParameters: {'per_page': 200},
      );
      final raw = r.data;
      final list = raw is Map
          ? (raw['data'] as List? ?? [])
          : (raw is List ? raw : []);
      for (final a in list) {
        final m = a as Map<String, dynamic>;
        final aid = m['id'] as String? ?? '';
        final name = m['display_name'] as String? ?? m['name'] as String? ?? '';
        if (aid.isNotEmpty && name.isNotEmpty && !_isUlid(name)) {
          _nameCache[aid] = name;
        }
      }
    } catch (_) {}
  }

  // ── Normalizers ───────────────────────────────────────────

  Map<String, dynamic> _normalizeDirect(Map<String, dynamic> j) {
    debugPrint(
      '[_normalizeDirect] id=${j['id']} '
      'initiator=${j['initiator_actor_id']} '
      'recipient=${j['recipient_actor_id']}',
    );

    final existing = j['participants'] as List?;
    if (existing != null && existing.isNotEmpty) {
      for (final p in existing) {
        if (p is Map<String, dynamic>) _cacheParticipantName(p);
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

  Map<String, dynamic> _normalizeGroup(Map<String, dynamic> j) {
    final rawP = j['participants'] as List<dynamic>? ?? [];
    final now = DateTime.now().toIso8601String();

    final participants = rawP.map((p) {
      final m = p as Map<String, dynamic>;
      final id = m['actor_id'] as String? ?? m['id'] as String? ?? '';
      _cacheParticipantName(m);
      final name = _resolveName(
        m['name'] as String? ??
            m['display_name'] as String? ??
            m['full_name'] as String?,
        id,
      );
      return {
        'id': id,
        'name': name,
        'role': m['role'] as String? ?? 'member',
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
        if (aid.isNotEmpty) presenceMap[aid] = m;
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
    } catch (_) {}
  }

  String _detectType(Map<String, dynamic> data) {
    final typeField = data['type'] as String?;
    if (typeField == 'group') return 'group';
    if (typeField == 'direct') return 'direct';
    if (data.containsKey('name') && data['name'] != null) return 'group';
    if (data.containsKey('participant_ids')) return 'group';
    if (data.containsKey('initiator_actor_id') ||
        data.containsKey('recipient_actor_id'))
      return 'direct';
    return 'direct';
  }

  // ── CRUD ──────────────────────────────────────────────────

  @override
  Future<List<ConversationModel>> getAll() async {
    try {
      final dmFuture = _dio.get('$_base/conversations');
      final groupFuture = _dio.get('$_base/groups');
      final results = await Future.wait([dmFuture, groupFuture]);

      final dmRawList = (results[0].data['data'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final groupRaw = results[1].data;
      final groupRawList =
          (groupRaw is List
                  ? groupRaw
                  : (groupRaw is Map
                        ? (groupRaw['data'] as List? ?? [])
                        : <dynamic>[]))
              .cast<Map<String, dynamic>>();

      // Pre-warm name cache before normalizing
      final idsToResolve = <String>{};
      for (final m in dmRawList) {
        final iid =
            m['initiator_actor_id'] as String? ??
            m['initiator_id'] as String? ??
            '';
        final rid =
            m['recipient_actor_id'] as String? ??
            m['recipient_id'] as String? ??
            '';
        if (iid.isNotEmpty) idsToResolve.add(iid);
        if (rid.isNotEmpty) idsToResolve.add(rid);
        final existing = m['participants'] as List?;
        if (existing != null) {
          for (final p in existing) {
            if (p is Map<String, dynamic>) {
              final pid = p['actor_id'] as String? ?? p['id'] as String? ?? '';
              if (pid.isNotEmpty) idsToResolve.add(pid);
            }
          }
        }
      }
      for (final m in groupRawList) {
        final rawP = m['participants'] as List<dynamic>? ?? [];
        for (final p in rawP) {
          if (p is Map<String, dynamic>) {
            final pid = p['actor_id'] as String? ?? p['id'] as String? ?? '';
            if (pid.isNotEmpty) idsToResolve.add(pid);
          }
        }
      }

      await _resolveActorNames(idsToResolve.toList());

      for (final m in dmRawList) {
        _typeCache[m['id'] as String? ?? ''] = 'direct';
      }
      for (final m in groupRawList) {
        _typeCache[m['id'] as String? ?? ''] = 'group';
      }

      final dms = dmRawList
          .map((m) => ConversationModel.fromJson(_normalizeDirect(m)))
          .toList();
      final groups = groupRawList
          .map((m) => ConversationModel.fromJson(_normalizeGroup(m)))
          .toList();

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
        if (e.response?.statusCode == 404 && cachedType == null) {
          final r2 = await _dio.get('$_base/$fallbackScope/$id');
          data = _unwrapResponse(r2.data);
        } else {
          rethrow;
        }
      }

      final detectedType = _detectType(data);
      _typeCache[id] = detectedType;

      // Pre-warm cache for participants before normalizing
      final idsToResolve = <String>[];
      if (detectedType == 'direct') {
        final iid =
            data['initiator_actor_id'] as String? ??
            data['initiator_id'] as String? ??
            '';
        final rid =
            data['recipient_actor_id'] as String? ??
            data['recipient_id'] as String? ??
            '';
        if (iid.isNotEmpty) idsToResolve.add(iid);
        if (rid.isNotEmpty) idsToResolve.add(rid);
      } else {
        final rawP = data['participants'] as List<dynamic>? ?? [];
        for (final p in rawP) {
          if (p is Map<String, dynamic>) {
            final pid = p['actor_id'] as String? ?? p['id'] as String? ?? '';
            if (pid.isNotEmpty) idsToResolve.add(pid);
          }
        }
      }
      await _resolveActorNames(idsToResolve);

      final normalized = detectedType == 'group'
          ? _normalizeGroup(data)
          : _normalizeDirect(data);

      final participantMaps = (normalized['participants'] as List)
          .cast<Map<String, dynamic>>();
      await _enrichPresence(participantMaps);

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

        for (final p in participants) {
          if (p is Map<String, dynamic>) _cacheParticipantName(p);
        }

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
        for (final p in participants) {
          if (p is Map<String, dynamic>) _cacheParticipantName(p);
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

        final iid =
            conv['initiator_actor_id'] as String? ??
            conv['initiator_id'] as String? ??
            '';
        final rid =
            conv['recipient_actor_id'] as String? ??
            conv['recipient_id'] as String? ??
            '';
        await _resolveActorNames([iid, rid]..removeWhere((s) => s.isEmpty));

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

      // Collect uncached sender IDs for bulk resolution
      final uncachedIds = <String>{};
      for (final e in list) {
        final msgMap = e as Map<String, dynamic>;
        final senderId =
            msgMap['sender_actor_id'] as String? ??
            msgMap['sender_id'] as String? ??
            '';
        final rawName = msgMap['sender_name'] as String?;
        if (senderId.isNotEmpty &&
            !_nameCache.containsKey(senderId) &&
            (rawName == null || rawName.isEmpty || _isUlid(rawName))) {
          uncachedIds.add(senderId);
        }
      }
      if (uncachedIds.isNotEmpty) {
        await _resolveActorNames(uncachedIds.toList());
      }

      final messages = list.map((e) {
        final msgMap = e as Map<String, dynamic>;
        final senderId =
            msgMap['sender_actor_id'] as String? ??
            msgMap['sender_id'] as String? ??
            '';
        msgMap['sender_name'] = _resolveName(
          msgMap['sender_name'] as String?,
          senderId,
        );
        return MessageModel.fromJson(msgMap);
      }).toList();

      // API returns newest-first — reverse to chronological for UI
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
    String? attachmentId,
    String? attachmentType,
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
      if (attachmentType == 'image' || imageUrl != null) contentType = 'image';
      if (attachmentType == 'document') contentType = 'document';
      if (voiceDurationSeconds != null) contentType = 'audio';
      if (forwardedFromConvId != null) contentType = 'forwarded';

      final body = <String, dynamic>{
        'content': content,
        'content_type': contentType,
        if (replyToId != null) 'reply_to_id': replyToId,
        if (forwardedFromConvId != null)
          'forwarded_from_id': forwardedFromConvId,
        if (attachmentId != null) 'attachment_ids': [attachmentId],
      };

      final r = await _dio.post('$_base/$scope/$convId/messages', data: body);
      final msgData = _unwrapResponse(r.data);

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

  @override
  List<MessageModel> searchMessages(String convId, String query) => [];

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

  @override
  Future<String> createPrivateFromGroup(
    String participantId,
    String participantName,
    String participantRole,
    String? message,
  ) async {
    try {
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
}
