import '../models/visit_model.dart';
import 'visit_remote_datasource.dart';

class VisitMockDataSource implements VisitRemoteDataSource {
  static final List<Map<String, dynamic>> _store = [
    {
      'id': 'vis-001', 'customer_id': 'cust-001', 'officer_id': 'off-001',
      'visit_date': '2026-03-10T09:30:00.000Z', 'business_name': 'Mbeya City Pharmacy',
      'owner_phone': '+255 752 100 001', 'contact_person_phone': '+255 712 200 001',
      'business_phone': '+255 252 500 100',
      'notes': 'Owner interested in bulk order of Paracetamol. Discussed Q2 pricing.',
      'gps_lat': -8.9000, 'gps_lng': 33.4500,
      'image_urls': ['https://images.unsplash.com/photo-1576602976047-174e57a47881?w=200'],
      'document_urls': <String>[], 'promoted_product_ids': ['prod-001', 'prod-003'],
      'discussion_summary': 'Reviewed new Vitamin C line. Owner placed tentative order for 50 units.',
      'status': 'pending', 'created_at': '2026-03-10T09:30:00.000Z',
    },
    {
      'id': 'vis-002', 'customer_id': 'cust-002', 'officer_id': 'off-002',
      'visit_date': '2026-03-09T14:00:00.000Z', 'business_name': 'Uyole Medical Supplies',
      'owner_phone': '+255 765 300 002', 'contact_person_phone': null, 'business_phone': null,
      'notes': 'Routine check. Stock levels adequate.',
      'gps_lat': -8.9200, 'gps_lng': 33.4300,
      'image_urls': <String>[], 'document_urls': <String>[], 'promoted_product_ids': ['prod-002'],
      'discussion_summary': 'Presented Amoxicillin restock offer. Owner will confirm next week.',
      'status': 'reviewed', 'created_at': '2026-03-09T14:00:00.000Z',
    },
    {
      'id': 'vis-003', 'customer_id': 'cust-003', 'officer_id': 'off-001',
      'visit_date': '2026-03-08T10:00:00.000Z', 'business_name': 'Tukuyu Health Store',
      'owner_phone': '+255 754 400 003', 'contact_person_phone': '+255 783 500 003',
      'business_phone': null,
      'notes': 'GPS location mismatch — officer logged from 15km away. Needs verification.',
      'gps_lat': -9.1000, 'gps_lng': 33.5000,
      'image_urls': <String>[], 'document_urls': <String>[], 'promoted_product_ids': <String>[],
      'discussion_summary': 'Brief visit. Contact person was absent.',
      'status': 'flagged', 'created_at': '2026-03-08T10:00:00.000Z',
    },
    {
      'id': 'vis-004', 'customer_id': 'cust-004', 'officer_id': 'off-003',
      'visit_date': '2026-03-11T08:15:00.000Z', 'business_name': 'Forest Hill Pharmacy',
      'owner_phone': '+255 745 600 004', 'contact_person_phone': '+255 756 700 004',
      'business_phone': '+255 252 500 104',
      'notes': 'New product demo for Hydrocortisone cream. Very positive reception.',
      'gps_lat': -8.9100, 'gps_lng': 33.4600,
      'image_urls': ['https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=200'],
      'document_urls': <String>[], 'promoted_product_ids': ['prod-006', 'prod-005'],
      'discussion_summary': 'Owner ordered 20 units. Delivery requested by Friday.',
      'status': 'pending', 'created_at': '2026-03-11T08:15:00.000Z',
    },
    {
      'id': 'vis-005', 'customer_id': 'cust-006', 'officer_id': 'off-006',
      'visit_date': '2026-03-07T11:45:00.000Z', 'business_name': 'Soweto Health Point',
      'owner_phone': '+255 783 900 006', 'contact_person_phone': '+255 765 110 006',
      'business_phone': null, 'notes': 'Follow-up on previous order. Payment confirmed.',
      'gps_lat': -8.9050, 'gps_lng': 33.4550,
      'image_urls': <String>[], 'document_urls': <String>[], 'promoted_product_ids': ['prod-008'],
      'discussion_summary': 'Collected payment receipt. Discussed Omeprazole restocking.',
      'status': 'reviewed', 'created_at': '2026-03-07T11:45:00.000Z',
    },
  ];

  static int _idCounter = 6;
  Future<void> _simulateDelay() => Future.delayed(const Duration(milliseconds: 400));

  @override
  Future<List<VisitModel>> getAll() async {
    await _simulateDelay();
    return _store.map((e) => VisitModel.fromJson(e)).toList();
  }
  @override
  Future<VisitModel> getById(String id) async {
    await _simulateDelay();
    return VisitModel.fromJson(_store.firstWhere((e) => e['id'] == id, orElse: () => throw Exception('Visit not found')));
  }
  @override
  Future<VisitModel> create(Map<String, dynamic> data) async {
    await _simulateDelay();
    final id = _idCounter++;
    final n = {'id': 'vis-${id.toString().padLeft(3, '0')}', ...data, 'status': 'pending', 'created_at': DateTime.now().toIso8601String()};
    _store.add(n);
    return VisitModel.fromJson(n);
  }
  @override
  Future<VisitModel> update(String id, Map<String, dynamic> data) async {
    await _simulateDelay();
    final i = _store.indexWhere((e) => e['id'] == id);
    if (i == -1) throw Exception('Visit not found');
    _store[i] = {..._store[i], ...data, 'id': id, 'created_at': _store[i]['created_at']};
    return VisitModel.fromJson(_store[i]);
  }
  @override
  Future<void> delete(String id) async { await _simulateDelay(); _store.removeWhere((e) => e['id'] == id); }
}