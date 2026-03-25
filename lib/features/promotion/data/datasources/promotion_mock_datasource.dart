import '../../domain/entities/promotion_entity.dart';
import '../models/promotion_model.dart';
import 'promotion_remote_datasource.dart';

class PromotionMockDataSource implements PromotionRemoteDataSource {
  final List<Map<String, dynamic>> _store = [
    {
      'id': 'promo-001',
      'title': 'October Antibiotics Campaign',
      'description':
          'Special discounts on all antibiotic products for October. Target pharmacies in Mbeya and surrounding regions.',
      'product_ids': ['prod-001', 'prod-002', 'prod-003'],
      'start_date': '2025-10-01T00:00:00.000Z',
      'end_date': '2025-10-31T23:59:59.000Z',
      'channels': ['sms', 'whatsapp'],
      'status': 'active',
      'target_count': 24,
      'broadcast_sent_at': '2025-10-01T08:00:00.000Z',
      'created_at': '2025-09-28T10:00:00.000Z',
    },
    {
      'id': 'promo-002',
      'title': 'New Vitamins & Supplements Line',
      'description':
          'Introducing our new range of vitamins and dietary supplements. Inform all customers about the new catalogue.',
      'product_ids': ['prod-004', 'prod-005'],
      'start_date': '2025-10-14T00:00:00.000Z',
      'end_date': '2025-10-28T23:59:59.000Z',
      'channels': ['whatsapp'],
      'status': 'active',
      'target_count': 24,
      'broadcast_sent_at': '2025-10-14T09:00:00.000Z',
      'created_at': '2025-10-10T14:30:00.000Z',
    },
    {
      'id': 'promo-003',
      'title': 'September Malaria Season Promo',
      'description':
          'Promotional pricing on malaria prevention and treatment products ahead of the rainy season.',
      'product_ids': ['prod-002', 'prod-006'],
      'start_date': '2025-09-01T00:00:00.000Z',
      'end_date': '2025-09-30T23:59:59.000Z',
      'channels': ['sms', 'whatsapp'],
      'status': 'ended',
      'target_count': 21,
      'broadcast_sent_at': '2025-09-01T07:30:00.000Z',
      'created_at': '2025-08-27T09:00:00.000Z',
    },
    {
      'id': 'promo-004',
      'title': 'Ramadhan Health Package',
      'description':
          'Special health package pricing for pharmacies during Ramadhan. Includes vitamins, supplements and ORS products.',
      'product_ids': ['prod-004', 'prod-005', 'prod-007'],
      'start_date': '2025-11-01T00:00:00.000Z',
      'end_date': '2025-11-30T23:59:59.000Z',
      'channels': ['sms', 'whatsapp'],
      'status': 'draft',
      'target_count': 0,
      'broadcast_sent_at': null,
      'created_at': '2025-10-12T16:00:00.000Z',
    },
    {
      'id': 'promo-005',
      'title': 'Flash Sale — Pain Relief Products',
      'description': 'One-week flash sale on pain relief and anti-inflammatory products.',
      'product_ids': ['prod-001', 'prod-003'],
      'start_date': '2025-10-07T00:00:00.000Z',
      'end_date': '2025-10-14T23:59:59.000Z',
      'channels': ['sms'],
      'status': 'cancelled',
      'target_count': 0,
      'broadcast_sent_at': null,
      'created_at': '2025-10-05T11:00:00.000Z',
    },
  ];

  // Mock product name lookup (mirrors product mock data)
  static const Map<String, String> _productNames = {
    'prod-001': 'Amoxicillin 500mg Capsules',
    'prod-002': 'Artemether/Lumefantrine 20/120mg',
    'prod-003': 'Ibuprofen 400mg Tablets',
    'prod-004': 'Vitamin C 1000mg Effervescent',
    'prod-005': 'Multivitamin & Minerals Complex',
    'prod-006': 'Metronidazole 400mg Tablets',
    'prod-007': 'Oral Rehydration Salts (ORS)',
  };

  static String productName(String id) =>
      _productNames[id] ?? id;

  // Simulated total customer count for broadcast
  static const int _totalCustomers = 24;

  int _idCounter = 6;

  Future<void> _delay() =>
      Future.delayed(const Duration(milliseconds: 450));

  /// Simulates the L3 workflow broadcast side effect.
  /// In production the backend calls SMS + WhatsApp gateways.
  /// Returns a summary of what would be sent.
  Map<String, dynamic> _simulateBroadcast(
      List<String> channels, List<String> productIds) {
    return {
      'target_count': _totalCustomers,
      'broadcast_sent_at': DateTime.now().toIso8601String(),
      'channels_dispatched': channels,
      'products_included': productIds.length,
      'sms_queued': channels.contains('sms') ? _totalCustomers : 0,
      'whatsapp_queued':
          channels.contains('whatsapp') ? _totalCustomers : 0,
    };
  }

  @override
  Future<List<PromotionModel>> getAll() async {
    await _delay();
    final sorted = List<Map<String, dynamic>>.from(_store)
      ..sort((a, b) => (b['created_at'] as String)
          .compareTo(a['created_at'] as String));
    return sorted.map(PromotionModel.fromJson).toList();
  }

  @override
  Future<PromotionModel> getById(String id) async {
    await _delay();
    final item = _store.firstWhere(
      (e) => e['id'] == id,
      orElse: () => throw Exception('Promotion not found'),
    );
    return PromotionModel.fromJson(item);
  }

  @override
  Future<PromotionModel> create(Map<String, dynamic> data) async {
    await _delay();
    final id = 'promo-${_idCounter.toString().padLeft(3, '0')}';
    _idCounter++;
    final newItem = {
      'id': id,
      'title': data['title'] ?? '',
      'description': data['description'],
      'product_ids': data['product_ids'] ?? [],
      'start_date': data['start_date'] ??
          DateTime.now().toIso8601String(),
      'end_date': data['end_date'] ??
          DateTime.now()
              .add(const Duration(days: 7))
              .toIso8601String(),
      'channels': data['channels'] ?? ['sms'],
      'status': 'draft',
      'target_count': 0,
      'broadcast_sent_at': null,
      'created_at': DateTime.now().toIso8601String(),
    };
    _store.add(newItem);
    return PromotionModel.fromJson(newItem);
  }

  @override
  Future<PromotionModel> update(
      String id, Map<String, dynamic> data) async {
    await _delay();
    final index = _store.indexWhere((e) => e['id'] == id);
    if (index == -1) throw Exception('Promotion not found');

    // L3 Workflow: if transitioning to active, simulate broadcast
    if (data['status'] == 'active') {
      final broadcast = _simulateBroadcast(
        List<String>.from(
            _store[index]['channels'] as List? ?? []),
        List<String>.from(
            _store[index]['product_ids'] as List? ?? []),
      );
      data = {
        ...data,
        'target_count': broadcast['target_count'],
        'broadcast_sent_at': broadcast['broadcast_sent_at'],
      };
    }

    _store[index] = {..._store[index], ...data};
    return PromotionModel.fromJson(_store[index]);
  }

  @override
  Future<void> delete(String id) async {
    await _delay();
    _store.removeWhere((e) => e['id'] == id);
  }

    @override
  Future<PromotionModel> publish(String id) async {
    await _delay();
    final index = _store.indexWhere((e) => e['id'] == id);
    if (index == -1) throw Exception('Promotion not found');
 
    final broadcast = _simulateBroadcast(
      List<String>.from(_store[index]['channels'] as List? ?? []),
      List<String>.from(_store[index]['product_ids'] as List? ?? []),
    );
 
    _store[index] = {
      ..._store[index],
      'status': 'active',
      'target_count': broadcast['target_count'],
      'broadcast_sent_at': broadcast['broadcast_sent_at'],
    };
    return PromotionModel.fromJson(Map.from(_store[index]));
  }
}