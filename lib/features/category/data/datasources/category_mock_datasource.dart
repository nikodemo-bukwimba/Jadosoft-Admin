// category_mock_datasource.dart
// ─────────────────────────────────────────────────────────────
// Mock implementation of CategoryRemoteDataSource.
// Uses in-memory list — all CRUD operations work without any API.
//
// To activate real API later:
//   1. Open injection_container.dart
//   2. Replace CategoryMockDataSource() with CategoryRemoteDataSourceImpl(dio: sl())
//   3. Done — no other changes needed.
// ─────────────────────────────────────────────────────────────

import '../models/category_model.dart';
import 'category_remote_datasource.dart';

class CategoryMockDataSource implements CategoryRemoteDataSource {
  /// Shared in-memory store — persists across BLoC rebuilds within same session.
  static final List<Map<String, dynamic>> _store = [
    {
      'id': 'cat-001',
      'name': 'Painkillers & Analgesics',
      'description':
          'Over-the-counter and prescription pain relief medications',
      'is_active': true,
    },
    {
      'id': 'cat-002',
      'name': 'Antibiotics',
      'description': 'Prescription antibacterial medications',
      'is_active': true,
    },
    {
      'id': 'cat-003',
      'name': 'Vitamins & Supplements',
      'description': 'Daily vitamins, minerals, and dietary supplements',
      'is_active': true,
    },
    {
      'id': 'cat-004',
      'name': 'First Aid',
      'description': 'Bandages, antiseptics, wound care supplies',
      'is_active': true,
    },
    {
      'id': 'cat-005',
      'name': 'Dermatology',
      'description': 'Skin care, creams, and topical treatments',
      'is_active': false,
    },
  ];

  static int _idCounter = 6;

  /// Simulates network latency — keeps UI loading states visible during dev.
  Future<void> _simulateDelay() =>
      Future.delayed(const Duration(milliseconds: 400));

  @override
  Future<List<CategoryModel>> getAll() async {
    await _simulateDelay();
    return _store.map((e) => CategoryModel.fromJson(e)).toList();
  }

  @override
  Future<CategoryModel> getById(String id) async {
    await _simulateDelay();
    final item = _store.firstWhere(
      (e) => e['id'] == id,
      orElse: () => throw Exception('Category not found'),
    );
    return CategoryModel.fromJson(item);
  }

  @override
  Future<CategoryModel> create(Map<String, dynamic> data) async {
    await _simulateDelay();
    final id = 'cat-${_idCounter.toString().padLeft(3, '0')}';
    _idCounter++;
    final newItem = {
      'id': id,
      'name': data['name'] ?? '',
      'description': data['description'],
      'is_active': data['is_active'] ?? false,
    };
    _store.add(newItem);
    return CategoryModel.fromJson(newItem);
  }

  @override
  Future<CategoryModel> update(String id, Map<String, dynamic> data) async {
    await _simulateDelay();
    final index = _store.indexWhere((e) => e['id'] == id);
    if (index == -1) throw Exception('Category not found');

    _store[index] = {
      ..._store[index],
      ...data,
      'id': id, // preserve original id
    };
    return CategoryModel.fromJson(_store[index]);
  }

  @override
  Future<void> delete(String id) async {
    await _simulateDelay();
    _store.removeWhere((e) => e['id'] == id);
  }
}
