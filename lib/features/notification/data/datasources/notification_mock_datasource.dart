import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';
import 'notification_remote_datasource.dart';

class NotificationMockDataSource implements NotificationRemoteDataSource {
  final List<Map<String, dynamic>> _store = [
    {
      'id': 'notif-001',
      'recipient_id': 'off-001',
      'recipient_type': 'officer',
      'channel': 'sms',
      'content':
          'Hello Amina, your weekly plan for 14–18 Oct has been approved by admin. Keep up the great work!',
      'template_id': 'tpl-plan-approved',
      'status': 'delivered',
      'sent_at': '2025-10-14T08:05:00.000Z',
      'delivered_at': '2025-10-14T08:05:12.000Z',
      'failure_reason': null,
      'created_at': '2025-10-14T08:04:50.000Z',
    },
    {
      'id': 'notif-002',
      'recipient_id': 'cust-001',
      'recipient_type': 'customer',
      'channel': 'whatsapp',
      'content':
          'Dear Dawa Bora Pharmacy, we have exciting new promotions on Amoxicillin and Paracetamol. Contact your officer for details.',
      'template_id': 'tpl-promo-broadcast',
      'status': 'delivered',
      'sent_at': '2025-10-13T09:30:00.000Z',
      'delivered_at': '2025-10-13T09:30:45.000Z',
      'failure_reason': null,
      'created_at': '2025-10-13T09:29:40.000Z',
    },
    {
      'id': 'notif-003',
      'recipient_id': 'off-002',
      'recipient_type': 'officer',
      'channel': 'sms',
      'content':
          'Hello Brian, your daily report for 13 Oct has been rejected. Feedback: Please provide more detail on customer discussions.',
      'template_id': 'tpl-report-rejected',
      'status': 'failed',
      'sent_at': null,
      'delivered_at': null,
      'failure_reason': 'Carrier error: number temporarily unreachable (Airtel TZ)',
      'created_at': '2025-10-13T17:10:00.000Z',
    },
    {
      'id': 'notif-004',
      'recipient_id': 'cust-002',
      'recipient_type': 'customer',
      'channel': 'whatsapp',
      'content':
          'Dear Afya Plus Chemist, your order #ORD-2025-0041 has been shipped and will arrive within 2 business days.',
      'template_id': 'tpl-order-shipped',
      'status': 'sent',
      'sent_at': '2025-10-14T10:15:00.000Z',
      'delivered_at': null,
      'failure_reason': null,
      'created_at': '2025-10-14T10:14:50.000Z',
    },
    {
      'id': 'notif-005',
      'recipient_id': 'off-003',
      'recipient_type': 'officer',
      'channel': 'in_app',
      'content':
          'You have a new customer assigned: Tiba Bora Dawa. Please schedule a visit within this week.',
      'template_id': null,
      'status': 'delivered',
      'sent_at': '2025-10-12T11:00:00.000Z',
      'delivered_at': '2025-10-12T11:00:02.000Z',
      'failure_reason': null,
      'created_at': '2025-10-12T10:59:55.000Z',
    },
    {
      'id': 'notif-006',
      'recipient_id': 'cust-003',
      'recipient_type': 'customer',
      'channel': 'sms',
      'content':
          'Dear Salama Pharmacy, special offer: 15% discount on all antibiotics this week only. Call us to place your order.',
      'template_id': 'tpl-promo-broadcast',
      'status': 'failed',
      'sent_at': null,
      'delivered_at': null,
      'failure_reason': 'Vodacom TZ: Invalid destination number format',
      'created_at': '2025-10-11T14:20:00.000Z',
    },
    {
      'id': 'notif-007',
      'recipient_id': 'off-001',
      'recipient_type': 'officer',
      'channel': 'in_app',
      'content':
          'Your daily report for 10 Oct has been approved. Admin feedback: Excellent work! The supply agreement follow-up is noted.',
      'template_id': 'tpl-report-approved',
      'status': 'delivered',
      'sent_at': '2025-10-11T08:30:00.000Z',
      'delivered_at': '2025-10-11T08:30:01.000Z',
      'failure_reason': null,
      'created_at': '2025-10-11T08:29:58.000Z',
    },
    {
      'id': 'notif-008',
      'recipient_id': 'cust-004',
      'recipient_type': 'customer',
      'channel': 'whatsapp',
      'content':
          'Dear Mji Mkuu Pharmacy, your order #ORD-2025-0038 has been delivered. Thank you for your business!',
      'template_id': 'tpl-order-delivered',
      'status': 'queued',
      'sent_at': null,
      'delivered_at': null,
      'failure_reason': null,
      'created_at': '2025-10-14T12:00:00.000Z',
    },
    {
      'id': 'notif-009',
      'recipient_id': 'off-004',
      'recipient_type': 'officer',
      'channel': 'sms',
      'content':
          'Reminder: You have 3 customers with no visit in the last 14 days. Please prioritise follow-ups this week.',
      'template_id': 'tpl-visit-reminder',
      'status': 'delivered',
      'sent_at': '2025-10-10T07:00:00.000Z',
      'delivered_at': '2025-10-10T07:00:30.000Z',
      'failure_reason': null,
      'created_at': '2025-10-10T06:59:45.000Z',
    },
    {
      'id': 'notif-010',
      'recipient_id': 'cust-005',
      'recipient_type': 'customer',
      'channel': 'whatsapp',
      'content':
          'Dear Uzima Dawa, we are introducing a new product line of vitamins and supplements. Ask your marketing officer for the full catalogue.',
      'template_id': 'tpl-promo-broadcast',
      'status': 'failed',
      'sent_at': null,
      'delivered_at': null,
      'failure_reason': 'WhatsApp Business API: Template not approved for this recipient region',
      'created_at': '2025-10-09T15:45:00.000Z',
    },
  ];

  int _idCounter = 11;

  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 400));

  @override
  Future<List<NotificationModel>> getAll() async {
    await _delay();
    final sorted = List<Map<String, dynamic>>.from(_store)
      ..sort((a, b) => (b['created_at'] as String)
          .compareTo(a['created_at'] as String));
    return sorted.map(NotificationModel.fromJson).toList();
  }

  @override
  Future<NotificationModel> getById(String id) async {
    await _delay();
    final item = _store.firstWhere(
      (e) => e['id'] == id,
      orElse: () => throw Exception('Notification not found'),
    );
    return NotificationModel.fromJson(item);
  }

  @override
  Future<NotificationModel> create(Map<String, dynamic> data) async {
    await _delay();
    final id = 'notif-${_idCounter.toString().padLeft(3, '0')}';
    _idCounter++;
    final newItem = {
      'id': id,
      'recipient_id': data['recipient_id'] ?? '',
      'recipient_type': data['recipient_type'] ?? 'officer',
      'channel': data['channel'] ?? 'in_app',
      'content': data['content'] ?? '',
      'template_id': data['template_id'],
      'status': 'queued',
      'sent_at': null,
      'delivered_at': null,
      'failure_reason': null,
      'created_at': DateTime.now().toIso8601String(),
    };
    _store.add(newItem);
    return NotificationModel.fromJson(newItem);
  }

  @override
  Future<NotificationModel> update(
      String id, Map<String, dynamic> data) async {
    await _delay();
    final index = _store.indexWhere((e) => e['id'] == id);
    if (index == -1) throw Exception('Notification not found');
    _store[index] = {..._store[index], ...data};
    return NotificationModel.fromJson(_store[index]);
  }

  @override
  Future<void> delete(String id) async {
    await _delay();
    _store.removeWhere((e) => e['id'] == id);
  }
}