import 'dart:async';
import 'dart:math';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../../domain/entities/message_entity.dart';
import 'conversation_remote_datasource.dart';

const kAdminId = 'admin-001';
const kAdminName = 'Elia Adam';
const kAdminRole = 'admin';

class ConversationMockDataSource implements ConversationRemoteDataSource {
  static final ConversationMockDataSource _instance =
      ConversationMockDataSource._internal();
  factory ConversationMockDataSource() => _instance;
  ConversationMockDataSource._internal() {
    _initData();
  }

  final List<Map<String, dynamic>> _conversations = [];
  final Map<String, List<Map<String, dynamic>>> _messages = {};
  int _msgCounter = 200;
  int _convCounter = 100;
  final _random = Random();
  final Map<String, String> _nameCache = {};

  @override
  Map<String, String> get nameCache => Map.unmodifiable(_nameCache);

  @override
  void registerName(String actorId, String name) {
    if (actorId.isNotEmpty && name.isNotEmpty) {
      _nameCache[actorId] = name;
    }
  }

  void Function(String conversationId, MessageModel message)? onAutoReply;
  void Function(String conversationId, String senderName)? onTypingStart;
  void Function(String conversationId)? onTypingStop;

  final Map<String, String> _onlineStatuses = {
    'off-001': 'online',
    'off-002': 'away',
    'off-003': 'online',
    'off-004': 'offline',
    'off-005': 'offline',
    'off-006': 'away',
    'cust-001': 'online',
    'cust-002': 'offline',
    'cust-003': 'away',
    'cust-004': 'offline',
    'cust-005': 'online',
    'cust-006': 'offline',
  };
  final Map<String, DateTime> _lastSeen = {};

  void _initData() {
    if (_conversations.isNotEmpty) return;
    final now = DateTime.now();
    for (final id in _onlineStatuses.keys) {
      if (_onlineStatuses[id] != 'online') {
        _lastSeen[id] = now.subtract(
          Duration(minutes: 5 + _random.nextInt(300)),
        );
      }
    }
    _conversations.add(
      _convMap(
        'conv-001',
        'direct',
        'open',
        null,
        [
          _participant(
            kAdminId,
            kAdminName,
            'admin',
            now.subtract(const Duration(days: 30)),
            'online',
          ),
          _participant(
            'off-001',
            'Amina Juma',
            'officer',
            now.subtract(const Duration(days: 30)),
            'online',
          ),
        ],
        'I will visit Mbeya Pharmacy today',
        now.subtract(const Duration(minutes: 12)),
        'Amina Juma',
        2,
        now.subtract(const Duration(days: 30)),
      ),
    );
    _messages['conv-001'] = [
      _msg(
        'msg-001',
        'conv-001',
        kAdminId,
        kAdminName,
        'admin',
        'Good morning Amina. How is the Mbeya route going?',
        now.subtract(const Duration(hours: 3)),
        'read',
      ),
      _msg(
        'msg-002',
        'conv-001',
        'off-001',
        'Amina Juma',
        'officer',
        'Good morning! I visited 4 pharmacies yesterday. All confirmed stock of Panadol Extra.',
        now.subtract(const Duration(hours: 2, minutes: 45)),
        'read',
      ),
      _msg(
        'msg-003',
        'conv-001',
        kAdminId,
        kAdminName,
        'admin',
        'Excellent. Did you manage to get the order from Sumbawanga Medical?',
        now.subtract(const Duration(hours: 2, minutes: 30)),
        'read',
      ),
      _msg(
        'msg-004',
        'conv-001',
        'off-001',
        'Amina Juma',
        'officer',
        'Not yet. They want to see the new pricing list first. I will bring it today.',
        now.subtract(const Duration(hours: 2)),
        'read',
      ),
      _msg(
        'msg-005',
        'conv-001',
        kAdminId,
        kAdminName,
        'admin',
        'Good. Make sure to take photos of their shelf space too.',
        now.subtract(const Duration(hours: 1, minutes: 30)),
        'delivered',
        isPinned: true,
      ),
      _msg(
        'msg-006',
        'conv-001',
        'off-001',
        'Amina Juma',
        'officer',
        'Will do. I will visit Mbeya Pharmacy today',
        now.subtract(const Duration(minutes: 12)),
        'read',
      ),
    ];
    _conversations.add(
      _convMap(
        'conv-002',
        'direct',
        'open',
        null,
        [
          _participant(
            kAdminId,
            kAdminName,
            'admin',
            now.subtract(const Duration(days: 14)),
            'online',
          ),
          _participant(
            'cust-001',
            'Mbeya Central Pharmacy',
            'customer',
            now.subtract(const Duration(days: 14)),
            'online',
          ),
        ],
        'We need 50 boxes of Amoxicillin 500mg',
        now.subtract(const Duration(hours: 1)),
        'Mbeya Central Pharmacy',
        1,
        now.subtract(const Duration(days: 14)),
      ),
    );
    _messages['conv-002'] = [
      _msg(
        'msg-010',
        'conv-002',
        'cust-001',
        'Mbeya Central Pharmacy',
        'customer',
        'Hello, we are running low on antibiotics.',
        now.subtract(const Duration(hours: 5)),
        'read',
      ),
      _msg(
        'msg-011',
        'conv-002',
        kAdminId,
        kAdminName,
        'admin',
        'Hello! Which products specifically do you need?',
        now.subtract(const Duration(hours: 4, minutes: 45)),
        'read',
      ),
      _msg(
        'msg-012',
        'conv-002',
        'cust-001',
        'Mbeya Central Pharmacy',
        'customer',
        'We need 50 boxes of Amoxicillin 500mg',
        now.subtract(const Duration(hours: 1)),
        'delivered',
      ),
    ];
    _conversations.add(
      _convMap(
        'conv-003',
        'direct',
        'open',
        null,
        [
          _participant(
            'off-002',
            'Baraka Mtui',
            'officer',
            now.subtract(const Duration(days: 20)),
            'away',
          ),
          _participant(
            'cust-002',
            'Sumbawanga Medical Store',
            'customer',
            now.subtract(const Duration(days: 20)),
            'offline',
          ),
        ],
        'The delivery arrived this morning. Thank you!',
        now.subtract(const Duration(hours: 6)),
        'Sumbawanga Medical Store',
        0,
        now.subtract(const Duration(days: 20)),
      ),
    );
    _messages['conv-003'] = [
      _msg(
        'msg-020',
        'conv-003',
        'off-002',
        'Baraka Mtui',
        'officer',
        'Good morning! Your order #ORD-2045 has been dispatched.',
        now.subtract(const Duration(days: 1)),
        'read',
      ),
      _msg(
        'msg-021',
        'conv-003',
        'cust-002',
        'Sumbawanga Medical Store',
        'customer',
        'Great, when should we expect it?',
        now.subtract(const Duration(days: 1)).add(const Duration(minutes: 15)),
        'read',
      ),
      _msg(
        'msg-022',
        'conv-003',
        'off-002',
        'Baraka Mtui',
        'officer',
        'Should arrive by tomorrow morning.',
        now.subtract(const Duration(days: 1)).add(const Duration(minutes: 20)),
        'read',
      ),
      _msg(
        'msg-023',
        'conv-003',
        'cust-002',
        'Sumbawanga Medical Store',
        'customer',
        'The delivery arrived this morning. Thank you!',
        now.subtract(const Duration(hours: 6)),
        'read',
      ),
    ];
    _conversations.add(
      _convMap(
        'conv-004',
        'group',
        'open',
        'Mbeya Region Team',
        [
          _participant(
            kAdminId,
            kAdminName,
            'admin',
            now.subtract(const Duration(days: 60)),
            'online',
          ),
          _participant(
            'off-001',
            'Amina Juma',
            'officer',
            now.subtract(const Duration(days: 60)),
            'online',
          ),
          _participant(
            'off-002',
            'Baraka Mtui',
            'officer',
            now.subtract(const Duration(days: 60)),
            'away',
          ),
          _participant(
            'off-003',
            'Celestine Msigwa',
            'officer',
            now.subtract(const Duration(days: 45)),
            'online',
          ),
        ],
        'Reminder: Weekly reports due by Friday 5pm',
        now.subtract(const Duration(minutes: 45)),
        kAdminName,
        0,
        now.subtract(const Duration(days: 60)),
      ),
    );
    _messages['conv-004'] = [
      _sysMsg(
        'msg-030',
        'conv-004',
        'Celestine Msigwa was added to the group',
        now.subtract(const Duration(days: 45)),
      ),
      _msg(
        'msg-031',
        'conv-004',
        kAdminId,
        kAdminName,
        'admin',
        'Welcome Celestine! This is our Mbeya team coordination group.',
        now.subtract(const Duration(days: 45)).add(const Duration(minutes: 5)),
        'read',
      ),
      _msg(
        'msg-032',
        'conv-004',
        'off-003',
        'Celestine Msigwa',
        'officer',
        'Thank you! Happy to join the team.',
        now.subtract(const Duration(days: 45)).add(const Duration(minutes: 10)),
        'read',
      ),
      _msg(
        'msg-033',
        'conv-004',
        'off-001',
        'Amina Juma',
        'officer',
        'I completed all visits in Sumbawanga zone this week.',
        now.subtract(const Duration(hours: 4)),
        'read',
      ),
      _msg(
        'msg-034',
        'conv-004',
        'off-002',
        'Baraka Mtui',
        'officer',
        'Same here for Tunduma zone. 12 pharmacies visited.',
        now.subtract(const Duration(hours: 3)),
        'read',
      ),
      _msg(
        'msg-035',
        'conv-004',
        kAdminId,
        kAdminName,
        'admin',
        '@all Reminder: Weekly reports due by Friday 5pm',
        now.subtract(const Duration(minutes: 45)),
        'delivered',
        mentionedUserIds: ['all'],
        isPinned: true,
      ),
    ];
    _conversations.add(
      _convMap(
        'conv-005',
        'group',
        'open',
        'Mbeya Central - Support',
        [
          _participant(
            'off-001',
            'Amina Juma',
            'officer',
            now.subtract(const Duration(days: 10)),
            'online',
          ),
          _participant(
            'off-004',
            'Diana Kimaro',
            'officer',
            now.subtract(const Duration(days: 10)),
            'offline',
          ),
          _participant(
            'cust-001',
            'Mbeya Central Pharmacy',
            'customer',
            now.subtract(const Duration(days: 10)),
            'online',
          ),
        ],
        'We will send the updated catalog tomorrow',
        now.subtract(const Duration(hours: 8)),
        'Diana Kimaro',
        0,
        now.subtract(const Duration(days: 10)),
      ),
    );
    _messages['conv-005'] = [
      _msg(
        'msg-040',
        'conv-005',
        'cust-001',
        'Mbeya Central Pharmacy',
        'customer',
        'Do you have the new pricing for Q2?',
        now.subtract(const Duration(hours: 10)),
        'read',
      ),
      _msg(
        'msg-041',
        'conv-005',
        'off-001',
        'Amina Juma',
        'officer',
        'Let me check with the team and get back to you.',
        now.subtract(const Duration(hours: 9, minutes: 30)),
        'read',
      ),
      _msg(
        'msg-042',
        'conv-005',
        'off-004',
        'Diana Kimaro',
        'officer',
        'We will send the updated catalog tomorrow',
        now.subtract(const Duration(hours: 8)),
        'read',
      ),
    ];
    _conversations.add(
      _convMap(
        'conv-006',
        'group',
        'closed',
        'Product Launch - Panadol Extra',
        [
          _participant(
            kAdminId,
            kAdminName,
            'admin',
            now.subtract(const Duration(days: 90)),
            'online',
          ),
          _participant(
            'off-001',
            'Amina Juma',
            'officer',
            now.subtract(const Duration(days: 90)),
            'online',
          ),
          _participant(
            'off-002',
            'Baraka Mtui',
            'officer',
            now.subtract(const Duration(days: 90)),
            'away',
          ),
        ],
        'This conversation has been closed',
        now.subtract(const Duration(days: 5)),
        null,
        0,
        now.subtract(const Duration(days: 90)),
        closedBy: kAdminName,
        closedAt: now.subtract(const Duration(days: 5)),
      ),
    );
    _messages['conv-006'] = [
      _msg(
        'msg-050',
        'conv-006',
        kAdminId,
        kAdminName,
        'admin',
        'Launch campaign completed. 85% coverage achieved!',
        now.subtract(const Duration(days: 6)),
        'read',
        isPinned: true,
      ),
      _msg(
        'msg-051',
        'conv-006',
        'off-001',
        'Amina Juma',
        'officer',
        'Great results from Mbeya zone.',
        now.subtract(const Duration(days: 6)).add(const Duration(hours: 1)),
        'read',
      ),
      _sysMsg(
        'msg-052',
        'conv-006',
        'This conversation has been closed by $kAdminName',
        now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  Map<String, dynamic> _convMap(
    String id,
    String type,
    String status,
    String? title,
    List<Map<String, dynamic>> participants,
    String? lastMsg,
    DateTime? lastMsgAt,
    String? lastMsgSender,
    int unread,
    DateTime createdAt, {
    String? closedBy,
    DateTime? closedAt,
  }) => {
    'id': id,
    'type': type,
    'status': status,
    'title': title,
    'participants': participants,
    'last_message': lastMsg,
    'last_message_at': lastMsgAt?.toIso8601String(),
    'last_message_sender_name': lastMsgSender,
    'unread_count': unread,
    'closed_by': closedBy,
    'closed_at': closedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  Map<String, dynamic> _participant(
    String id,
    String name,
    String role,
    DateTime joined,
    String online,
  ) => {
    'id': id,
    'name': name,
    'role': role,
    'joined_at': joined.toIso8601String(),
    'online_status': online,
    'last_seen_at': online != 'online'
        ? _lastSeen[id]?.toIso8601String()
        : null,
  };

  Map<String, dynamic> _msg(
    String id,
    String convId,
    String senderId,
    String senderName,
    String role,
    String content,
    DateTime sentAt,
    String delivery, {
    bool isPinned = false,
    bool isStarred = false,
    List<String>? mentionedUserIds,
    String? replyToId,
    String? replyToSenderName,
    String? replyToContent,
  }) => {
    'id': id,
    'conversation_id': convId,
    'sender_id': senderId,
    'sender_name': senderName,
    'sender_role': role,
    'type': 'text',
    'content': content,
    'image_url': null,
    'delivery_status': delivery,
    'sent_at': sentAt.toIso8601String(),
    'reply_to_id': replyToId,
    'reply_to_sender_name': replyToSenderName,
    'reply_to_content': replyToContent,
    'reactions': <Map<String, dynamic>>[],
    'is_pinned': isPinned,
    'is_starred': isStarred,
    'is_edited': false,
    'edited_at': null,
    'mentioned_user_ids': mentionedUserIds ?? <String>[],
    'read_receipts': <Map<String, dynamic>>[],
    'voice_duration_seconds': null,
    'forwarded_from_conversation_id': null,
    'forwarded_from_sender_name': null,
  };

  Map<String, dynamic> _sysMsg(
    String id,
    String convId,
    String content,
    DateTime sentAt,
  ) => {
    'id': id,
    'conversation_id': convId,
    'sender_id': 'system',
    'sender_name': 'System',
    'sender_role': 'system',
    'type': 'system',
    'content': content,
    'image_url': null,
    'delivery_status': 'read',
    'sent_at': sentAt.toIso8601String(),
    'reply_to_id': null,
    'reply_to_sender_name': null,
    'reply_to_content': null,
    'reactions': <Map<String, dynamic>>[],
    'is_pinned': false,
    'is_starred': false,
    'is_edited': false,
    'edited_at': null,
    'mentioned_user_ids': <String>[],
    'read_receipts': <Map<String, dynamic>>[],
    'voice_duration_seconds': null,
    'forwarded_from_conversation_id': null,
    'forwarded_from_sender_name': null,
  };

  Future<void> _simulateDelay() =>
      Future.delayed(Duration(milliseconds: 100 + _random.nextInt(150)));

  @override
  Future<List<ConversationModel>> getAll() async {
    await _simulateDelay();
    final sorted = List<Map<String, dynamic>>.from(_conversations)
      ..sort((a, b) {
        final aT = a['last_message_at'] as String?;
        final bT = b['last_message_at'] as String?;
        if (aT == null && bT == null) return 0;
        if (aT == null) return 1;
        if (bT == null) return -1;
        return bT.compareTo(aT);
      });
    return sorted.map((e) => ConversationModel.fromJson(e)).toList();
  }

  @override
  Future<ConversationModel> getById(String id) async {
    await _simulateDelay();
    return ConversationModel.fromJson(
      _conversations.firstWhere(
        (c) => c['id'] == id,
        orElse: () => throw Exception('Not found'),
      ),
    );
  }

  @override
  Future<ConversationModel> create(Map<String, dynamic> data) async {
    await _simulateDelay();
    final id = 'conv-${_convCounter++}';
    final now = DateTime.now();
    final newConv = {
      'id': id,
      'type': data['type'] ?? 'direct',
      'status': 'open',
      'title': data['title'],
      'participants': data['participants'] ?? [],
      'last_message': null,
      'last_message_at': now.toIso8601String(),
      'last_message_sender_name': null,
      'unread_count': 0,
      'closed_by': null,
      'closed_at': null,
      'created_at': now.toIso8601String(),
    };
    _conversations.add(newConv);
    _messages[id] = [];
    if (data['type'] == 'group') {
      _messages[id]!.add(
        _sysMsg(
          'msg-${_msgCounter++}',
          id,
          'Group "${data['title'] ?? 'Unnamed'}" created by $kAdminName',
          now,
        ),
      );
    }
    return ConversationModel.fromJson(newConv);
  }

  @override
  Future<ConversationModel> update(String id, Map<String, dynamic> data) async {
    await _simulateDelay();
    final idx = _conversations.indexWhere((c) => c['id'] == id);
    if (idx == -1) throw Exception('Not found');
    _conversations[idx] = {..._conversations[idx], ...data};
    return ConversationModel.fromJson(_conversations[idx]);
  }

  @override
  Future<void> delete(String id) async {
    await _simulateDelay();
    _conversations.removeWhere((c) => c['id'] == id);
    _messages.remove(id);
  }

  @override
  Future<List<MessageModel>> getMessages(
    String convId, {
    int perPage = 50,
  }) async {
    await _simulateDelay();
    return (_messages[convId] ?? [])
        .map((m) => MessageModel.fromJson(m))
        .toList();
  }

  @override
  Future<void> markAsRead(String convId) async {
    await _simulateDelay();
    // Mock: mark all messages as read
    final msgs = _messages[convId];
    if (msgs != null) {
      for (final m in msgs) {
        if (m['sender_id'] != kAdminId) {
          m['delivery_status'] = 'read';
        }
      }
    }
  }

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
    await _simulateDelay();
    final now = DateTime.now();
    final msgId = 'msg-${_msgCounter++}';
    final msgType = imageUrl != null
        ? 'image'
        : (voiceDurationSeconds != null ? 'voice' : 'text');
    final msgData = _msg(
      msgId,
      convId,
      kAdminId,
      kAdminName,
      kAdminRole,
      content,
      now,
      'sent',
      replyToId: replyToId,
      replyToSenderName: replyToSenderName,
      replyToContent: replyToContent,
      mentionedUserIds: mentionedUserIds,
    );
    msgData['type'] = msgType;
    msgData['image_url'] = imageUrl;
    msgData['voice_duration_seconds'] = voiceDurationSeconds;
    msgData['forwarded_from_conversation_id'] = forwardedFromConvId;
    msgData['forwarded_from_sender_name'] = forwardedFromSenderName;
    _messages.putIfAbsent(convId, () => []);
    _messages[convId]!.add(msgData);
    _updateLastMessage(convId);
    Future.delayed(const Duration(milliseconds: 500), () {
      msgData['delivery_status'] = 'delivered';
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      msgData['delivery_status'] = 'read';
    });
    _scheduleAutoReply(convId);
    return MessageModel.fromJson(msgData);
  }

  void _scheduleAutoReply(String convId) {
    final convIdx = _conversations.indexWhere((c) => c['id'] == convId);
    if (convIdx == -1 || _conversations[convIdx]['status'] == 'closed') return;
    final participants = _conversations[convIdx]['participants'] as List;
    final others = participants
        .where((p) => (p as Map)['id'] != kAdminId)
        .toList();
    if (others.isEmpty) return;
    final replier = others[_random.nextInt(others.length)] as Map;
    Future.delayed(const Duration(milliseconds: 1000), () {
      onTypingStart?.call(convId, replier['name'] as String);
    });
    Future.delayed(Duration(milliseconds: 2000 + _random.nextInt(1000)), () {
      onTypingStop?.call(convId);
      final replies = [
        'Noted, I will follow up on this.',
        'Thank you for the update.',
        'Understood. I will check and get back to you.',
        'Sure, let me look into it.',
        'Good to know. I will handle this today.',
        'Received. Will update you shortly.',
        'Okay, I will coordinate with the team.',
      ];
      final content = replies[_random.nextInt(replies.length)];
      final now = DateTime.now();
      final replyData = _msg(
        'msg-${_msgCounter++}',
        convId,
        replier['id'] as String,
        replier['name'] as String,
        replier['role'] as String,
        content,
        now,
        'read',
      );
      _messages.putIfAbsent(convId, () => []);
      _messages[convId]!.add(replyData);
      _updateLastMessage(convId);
      onAutoReply?.call(convId, MessageModel.fromJson(replyData));
    });
  }

  Future<void> deleteMessage(String convId, String msgId) async {
    await _simulateDelay();
    _messages[convId]?.removeWhere((m) => m['id'] == msgId);
    _updateLastMessage(convId);
  }

  Future<void> togglePin(String convId, String msgId) async {
    await _simulateDelay();
    final msg = _findMsg(convId, msgId);
    if (msg != null) msg['is_pinned'] = !(msg['is_pinned'] as bool? ?? false);
  }

  Future<void> toggleStar(String convId, String msgId) async {
    await _simulateDelay();
    final msg = _findMsg(convId, msgId);
    if (msg != null) msg['is_starred'] = !(msg['is_starred'] as bool? ?? false);
  }

  Future<void> addReaction(String convId, String msgId, String emoji) async {
    await _simulateDelay();
    final msg = _findMsg(convId, msgId);
    if (msg == null) return;
    final reactions = (msg['reactions'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final existing = reactions.indexWhere(
      (r) => r['user_id'] == kAdminId && r['emoji'] == emoji,
    );
    if (existing != -1) {
      reactions.removeAt(existing);
    } else {
      reactions.add({
        'emoji': emoji,
        'user_id': kAdminId,
        'user_name': kAdminName,
      });
    }
  }

  Future<void> editMessage(
    String convId,
    String msgId,
    String newContent,
  ) async {
    await _simulateDelay();
    final msg = _findMsg(convId, msgId);
    if (msg == null) return;
    msg['content'] = newContent;
    msg['is_edited'] = true;
    msg['edited_at'] = DateTime.now().toIso8601String();
    _updateLastMessage(convId);
  }

  Future<List<ReadReceipt>> getReadReceipts(String convId, String msgId) async {
    await _simulateDelay();
    final convIdx = _conversations.indexWhere((c) => c['id'] == convId);
    if (convIdx == -1) return [];
    final participants = (_conversations[convIdx]['participants'] as List)
        .cast<Map<String, dynamic>>();
    return participants
        .where((p) => p['id'] != kAdminId)
        .map(
          (p) => ReadReceipt(
            userId: p['id'] as String,
            userName: p['name'] as String,
            readAt: DateTime.now().subtract(
              Duration(minutes: _random.nextInt(60)),
            ),
          ),
        )
        .toList();
  }

  List<MessageModel> searchMessages(String convId, String query) {
    final msgs = _messages[convId] ?? [];
    final q = query.toLowerCase();
    return msgs
        .where((m) => (m['content'] as String? ?? '').toLowerCase().contains(q))
        .map((m) => MessageModel.fromJson(m))
        .toList();
  }

  List<MessageModel> getPinnedMessages(String convId) {
    return (_messages[convId] ?? [])
        .where((m) => m['is_pinned'] == true)
        .map((m) => MessageModel.fromJson(m))
        .toList();
  }

  List<MessageModel> getStarredMessages() {
    final starred = <MessageModel>[];
    for (final msgs in _messages.values) {
      starred.addAll(
        msgs
            .where((m) => m['is_starred'] == true)
            .map((m) => MessageModel.fromJson(m)),
      );
    }
    starred.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return starred;
  }

  Future<void> closeConversation(String convId) async {
    await _simulateDelay();
    final idx = _conversations.indexWhere((c) => c['id'] == convId);
    if (idx == -1) throw Exception('Not found');
    final now = DateTime.now();
    _conversations[idx]['status'] = 'closed';
    _conversations[idx]['closed_by'] = kAdminName;
    _conversations[idx]['closed_at'] = now.toIso8601String();
    _messages.putIfAbsent(convId, () => []);
    _messages[convId]!.add(
      _sysMsg(
        'msg-${_msgCounter++}',
        convId,
        'This conversation has been closed by $kAdminName',
        now,
      ),
    );
    _updateLastMessage(convId);
  }

  Future<void> reopenConversation(String convId) async {
    await _simulateDelay();
    final idx = _conversations.indexWhere((c) => c['id'] == convId);
    if (idx == -1) throw Exception('Not found');
    final now = DateTime.now();
    _conversations[idx]['status'] = 'open';
    _conversations[idx]['closed_by'] = null;
    _conversations[idx]['closed_at'] = null;
    _messages[convId]!.add(
      _sysMsg(
        'msg-${_msgCounter++}',
        convId,
        'This conversation has been reopened by $kAdminName',
        now,
      ),
    );
    _updateLastMessage(convId);
  }

  Future<void> addParticipant(
    String convId,
    String pId,
    String name,
    String role,
  ) async {
    await _simulateDelay();
    final idx = _conversations.indexWhere((c) => c['id'] == convId);
    if (idx == -1) throw Exception('Not found');
    final ps = _conversations[idx]['participants'] as List;
    if (ps.any((p) => (p as Map)['id'] == pId)) return;
    ps.add(
      _participant(
        pId,
        name,
        role,
        DateTime.now(),
        _onlineStatuses[pId] ?? 'offline',
      ),
    );
    _messages.putIfAbsent(convId, () => []);
    _messages[convId]!.add(
      _sysMsg(
        'msg-${_msgCounter++}',
        convId,
        '$name was added to the group',
        DateTime.now(),
      ),
    );
  }

  Future<void> removeParticipant(String convId, String pId, String name) async {
    await _simulateDelay();
    final idx = _conversations.indexWhere((c) => c['id'] == convId);
    if (idx == -1) throw Exception('Not found');
    (_conversations[idx]['participants'] as List).removeWhere(
      (p) => (p as Map)['id'] == pId,
    );
    _messages.putIfAbsent(convId, () => []);
    _messages[convId]!.add(
      _sysMsg(
        'msg-${_msgCounter++}',
        convId,
        '$name was removed from the group',
        DateTime.now(),
      ),
    );
  }

  Future<int> broadcastMessage(List<String> convIds, String content) async {
    int sent = 0;
    for (final convId in convIds) {
      try {
        await sendMessage(convId: convId, content: content);
        sent++;
      } catch (_) {}
    }
    return sent;
  }

  Future<String> createPrivateFromGroup(
    String participantId,
    String participantName,
    String participantRole,
    String? firstMessage,
  ) async {
    final existing = _conversations
        .where(
          (c) =>
              c['type'] == 'direct' &&
              (c['participants'] as List).any(
                (p) => (p as Map)['id'] == kAdminId,
              ) &&
              (c['participants'] as List).any(
                (p) => (p as Map)['id'] == participantId,
              ),
        )
        .toList();
    if (existing.isNotEmpty) {
      if (firstMessage != null)
        await sendMessage(
          convId: existing.first['id'] as String,
          content: firstMessage,
        );
      return existing.first['id'] as String;
    }
    final conv = await create({
      'type': 'direct',
      'participants': [
        _participant(kAdminId, kAdminName, 'admin', DateTime.now(), 'online'),
        _participant(
          participantId,
          participantName,
          participantRole,
          DateTime.now(),
          _onlineStatuses[participantId] ?? 'offline',
        ),
      ],
    });
    if (firstMessage != null)
      await sendMessage(convId: conv.id, content: firstMessage);
    return conv.id;
  }

  Map<String, dynamic>? _findMsg(String convId, String msgId) {
    final msgs = _messages[convId];
    if (msgs == null) return null;
    final idx = msgs.indexWhere((m) => m['id'] == msgId);
    return idx != -1 ? msgs[idx] : null;
  }

  void _updateLastMessage(String convId) {
    final msgs = _messages[convId];
    final convIdx = _conversations.indexWhere((c) => c['id'] == convId);
    if (convIdx == -1) return;
    if (msgs != null && msgs.isNotEmpty) {
      final last = msgs.last;
      _conversations[convIdx]['last_message'] = last['content'];
      _conversations[convIdx]['last_message_at'] = last['sent_at'];
      _conversations[convIdx]['last_message_sender_name'] = last['sender_name'];
    } else {
      _conversations[convIdx]['last_message'] = null;
      _conversations[convIdx]['last_message_at'] = null;
      _conversations[convIdx]['last_message_sender_name'] = null;
    }
  }

  List<Map<String, String>> getAvailableContacts() => [
    {'id': 'off-001', 'name': 'Amina Juma', 'role': 'officer'},
    {'id': 'off-002', 'name': 'Baraka Mtui', 'role': 'officer'},
    {'id': 'off-003', 'name': 'Celestine Msigwa', 'role': 'officer'},
    {'id': 'off-004', 'name': 'Diana Kimaro', 'role': 'officer'},
    {'id': 'off-005', 'name': 'Emmanuel Tarimo', 'role': 'officer'},
    {'id': 'off-006', 'name': 'Fatuma Hassan', 'role': 'officer'},
    {'id': 'cust-001', 'name': 'Mbeya Central Pharmacy', 'role': 'customer'},
    {'id': 'cust-002', 'name': 'Sumbawanga Medical Store', 'role': 'customer'},
    {'id': 'cust-003', 'name': 'Tunduma Health Supplies', 'role': 'customer'},
    {'id': 'cust-004', 'name': 'Rukwa Pharmacy Ltd', 'role': 'customer'},
    {'id': 'cust-005', 'name': 'Kalambo Drug Store', 'role': 'customer'},
    {'id': 'cust-006', 'name': 'Mpanda Medical Center', 'role': 'customer'},
  ];

  List<ConversationModel> getAdminConversations() => _conversations
      .where(
        (c) => (c['participants'] as List).any(
          (p) => (p as Map)['id'] == kAdminId,
        ),
      )
      .map((c) => ConversationModel.fromJson(c))
      .toList();
}
