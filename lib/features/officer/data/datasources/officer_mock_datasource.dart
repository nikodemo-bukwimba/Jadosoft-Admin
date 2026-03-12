import '../models/officer_model.dart';
import 'officer_remote_datasource.dart';

class OfficerMockDataSource implements OfficerRemoteDataSource {
  static final List<Map<String, dynamic>> _store = [
    {
      'id': 'off-001',
      'name': 'Celestine Msigwa',
      'email': 'celestine.msigwa@barickpharmacy.co.tz',
      'phone': '+255 754 321 001',
      'role': 'Senior Marketing Officer',
      'status': 'active',
      'created_at': '2024-03-15T08:00:00.000Z',
    },
    {
      'id': 'off-002',
      'name': 'Amina Mwakasege',
      'email': 'amina.mwakasege@barickpharmacy.co.tz',
      'phone': '+255 765 432 002',
      'role': 'Marketing Officer',
      'status': 'active',
      'created_at': '2024-06-01T09:00:00.000Z',
    },
    {
      'id': 'off-003',
      'name': 'Joseph Mwakyusa',
      'email': 'joseph.mwakyusa@barickpharmacy.co.tz',
      'phone': '+255 712 543 003',
      'role': 'Marketing Officer',
      'status': 'active',
      'created_at': '2024-08-20T10:00:00.000Z',
    },
    {
      'id': 'off-004',
      'name': 'Grace Mwakalinga',
      'email': 'grace.mwakalinga@barickpharmacy.co.tz',
      'phone': '+255 783 654 004',
      'role': 'Junior Marketing Officer',
      'status': 'suspended',
      'created_at': '2025-01-10T07:30:00.000Z',
    },
    {
      'id': 'off-005',
      'name': 'Baraka Kileo',
      'email': 'baraka.kileo@barickpharmacy.co.tz',
      'phone': '+255 745 765 005',
      'role': 'Marketing Officer',
      'status': 'deactivated',
      'created_at': '2023-11-05T11:00:00.000Z',
    },
    {
      'id': 'off-006',
      'name': 'Neema Mwaipopo',
      'email': 'neema.mwaipopo@barickpharmacy.co.tz',
      'phone': '+255 756 876 006',
      'role': 'Senior Marketing Officer',
      'status': 'active',
      'created_at': '2024-04-22T08:30:00.000Z',
    },
  ];

  static int _idCounter = 7;

  Future<void> _simulateDelay() =>
      Future.delayed(const Duration(milliseconds: 400));

  @override
  Future<List<OfficerModel>> getAll() async {
    await _simulateDelay();
    return _store.map((e) => OfficerModel.fromJson(e)).toList();
  }

  @override
  Future<OfficerModel> getById(String id) async {
    await _simulateDelay();
    final item = _store.firstWhere(
      (e) => e['id'] == id,
      orElse: () => throw Exception('Officer not found'),
    );
    return OfficerModel.fromJson(item);
  }

  @override
  Future<OfficerModel> create(Map<String, dynamic> data) async {
    await _simulateDelay();
    final id = _idCounter++;
    final newItem = {
      'id': 'off-${id.toString().padLeft(3, '0')}',
      'name': data['name'] ?? '',
      'email': data['email'] ?? '',
      'phone': data['phone'] ?? '',
      'role': data['role'] ?? '',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    };
    _store.add(newItem);
    return OfficerModel.fromJson(newItem);
  }

  @override
  Future<OfficerModel> update(String id, Map<String, dynamic> data) async {
    await _simulateDelay();
    final index = _store.indexWhere((e) => e['id'] == id);
    if (index == -1) throw Exception('Officer not found');
    _store[index] = {
      ..._store[index],
      ...data,
      'id': id,
      'created_at': _store[index]['created_at'],
    };
    return OfficerModel.fromJson(_store[index]);
  }

  @override
  Future<void> delete(String id) async {
    await _simulateDelay();
    _store.removeWhere((e) => e['id'] == id);
  }
}