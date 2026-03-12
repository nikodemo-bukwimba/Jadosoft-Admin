import '../models/customer_model.dart';
import 'customer_remote_datasource.dart';

class CustomerMockDataSource implements CustomerRemoteDataSource {
  static final List<Map<String, dynamic>> _store = [
    {
      'id': 'cust-001',
      'business_name': 'Mbeya City Pharmacy',
      'full_office_name': 'Mbeya City Pharmacy Ltd',
      'owner_name': 'Hassan Mwakyembe',
      'official_phone': '+255 752 100 001',
      'contact_person': 'Salma Abdallah',
      'contact_person_phone': '+255 712 200 001',
      'office_address': 'Karume Road, Mbeya CBD',
      'gps_lat': -8.9000,
      'gps_lng': 33.4500,
      'assigned_officer_id': 'off-001',
      'registration_date': '2024-04-10T08:00:00.000Z',
    },
    {
      'id': 'cust-002',
      'business_name': 'Uyole Medical Supplies',
      'full_office_name': 'Uyole Medical Supplies Co.',
      'owner_name': 'Rehema Mwambene',
      'official_phone': '+255 765 300 002',
      'contact_person': null,
      'contact_person_phone': null,
      'office_address': 'Uyole Junction, Mbeya',
      'gps_lat': -8.9200,
      'gps_lng': 33.4300,
      'assigned_officer_id': 'off-002',
      'registration_date': '2024-05-22T09:30:00.000Z',
    },
    {
      'id': 'cust-003',
      'business_name': 'Tukuyu Health Store',
      'full_office_name': null,
      'owner_name': 'Daniel Mwasambili',
      'official_phone': '+255 754 400 003',
      'contact_person': 'Peter Mwakibete',
      'contact_person_phone': '+255 783 500 003',
      'office_address': 'Market Street, Tukuyu',
      'gps_lat': -9.2550,
      'gps_lng': 33.6400,
      'assigned_officer_id': 'off-001',
      'registration_date': '2024-07-15T10:00:00.000Z',
    },
    {
      'id': 'cust-004',
      'business_name': 'Forest Hill Pharmacy',
      'full_office_name': 'Forest Hill Pharmacy & Wellness',
      'owner_name': 'Amani Mwakalyelye',
      'official_phone': '+255 745 600 004',
      'contact_person': 'Joyce Mwakatobe',
      'contact_person_phone': '+255 756 700 004',
      'office_address': 'Jacaranda Road, Mbeya',
      'gps_lat': -8.9100,
      'gps_lng': 33.4600,
      'assigned_officer_id': 'off-003',
      'registration_date': '2024-09-01T07:00:00.000Z',
    },
    {
      'id': 'cust-005',
      'business_name': 'Igawa Duka la Dawa',
      'full_office_name': null,
      'owner_name': 'Mwanaisha Lupembe',
      'official_phone': '+255 712 800 005',
      'contact_person': null,
      'contact_person_phone': null,
      'office_address': 'Igawa Trading Centre',
      'gps_lat': -8.7800,
      'gps_lng': 33.5100,
      'assigned_officer_id': 'off-006',
      'registration_date': '2025-01-20T08:30:00.000Z',
    },
    {
      'id': 'cust-006',
      'business_name': 'Soweto Health Point',
      'full_office_name': 'Soweto Health Point & Lab',
      'owner_name': 'Christopher Mwangoka',
      'official_phone': '+255 783 900 006',
      'contact_person': 'Flora Mwaipopo',
      'contact_person_phone': '+255 765 110 006',
      'office_address': 'Soweto Area, Mbeya',
      'gps_lat': -8.9050,
      'gps_lng': 33.4550,
      'assigned_officer_id': 'off-002',
      'registration_date': '2024-11-10T11:00:00.000Z',
    },
  ];

  static int _idCounter = 7;

  Future<void> _simulateDelay() =>
      Future.delayed(const Duration(milliseconds: 400));

  @override
  Future<List<CustomerModel>> getAll() async {
    await _simulateDelay();
    return _store.map((e) => CustomerModel.fromJson(e)).toList();
  }

  @override
  Future<CustomerModel> getById(String id) async {
    await _simulateDelay();
    final item = _store.firstWhere(
      (e) => e['id'] == id,
      orElse: () => throw Exception('Customer not found'),
    );
    return CustomerModel.fromJson(item);
  }

  @override
  Future<CustomerModel> create(Map<String, dynamic> data) async {
    await _simulateDelay();
    final id = _idCounter++;
    final newItem = {
      'id': 'cust-${id.toString().padLeft(3, '0')}',
      ...data,
      'registration_date': DateTime.now().toIso8601String(),
    };
    _store.add(newItem);
    return CustomerModel.fromJson(newItem);
  }

  @override
  Future<CustomerModel> update(String id, Map<String, dynamic> data) async {
    await _simulateDelay();
    final index = _store.indexWhere((e) => e['id'] == id);
    if (index == -1) throw Exception('Customer not found');
    _store[index] = {..._store[index], ...data, 'id': id, 'registration_date': _store[index]['registration_date']};
    return CustomerModel.fromJson(_store[index]);
  }

  @override
  Future<void> delete(String id) async {
    await _simulateDelay();
    _store.removeWhere((e) => e['id'] == id);
  }
}