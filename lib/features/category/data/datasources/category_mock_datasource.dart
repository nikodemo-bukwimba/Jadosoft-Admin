import '../../../../core/network/paginated_response.dart';
import '../models/category_model.dart';
import 'category_remote_datasource.dart';

class CategoryMockDataSource implements CategoryRemoteDataSource {
  static final List<Map<String, dynamic>> _store = [
    {'id': 'cat-001', 'name': 'Painkillers & Analgesics', 'description': 'Over-the-counter and prescription pain relief medications', 'is_active': true},
    {'id': 'cat-002', 'name': 'Antibiotics', 'description': 'Prescription antibacterial medications', 'is_active': true},
    {'id': 'cat-003', 'name': 'Vitamins & Supplements', 'description': 'Daily vitamins, minerals, and dietary supplements', 'is_active': true},
    {'id': 'cat-004', 'name': 'First Aid', 'description': 'Bandages, antiseptics, wound care supplies', 'is_active': true},
    {'id': 'cat-005', 'name': 'Dermatology', 'description': 'Skin care, creams, and topical treatments', 'is_active': false},
  ];
  static int _idC = 6;
  Future<void> _d() => Future.delayed(const Duration(milliseconds: 400));

  @override Future<PaginatedResponse<CategoryModel>> getAll({String? search, int? perPage, int? page}) async {
    await _d(); var list = List<Map<String, dynamic>>.from(_store);
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((e) => (e['name'] ?? '').toString().toLowerCase().contains(q)).toList();
    }
    final items = list.map((e) => CategoryModel.fromJson(e)).toList();
    return PaginatedResponse(items: items, currentPage: page ?? 1, lastPage: 1, total: items.length, perPage: perPage ?? 50);
  }
  @override Future<CategoryModel> getById(String id) async {
    await _d(); return CategoryModel.fromJson(_store.firstWhere((e) => e['id'] == id, orElse: () => throw Exception('Not found'))); }
  @override Future<CategoryModel> create(Map<String, dynamic> data) async {
    await _d(); final id = 'cat-${(_idC++).toString().padLeft(3, '0')}';
    final item = {'id': id, 'name': data['name'] ?? '', 'description': data['description'], 'is_active': data['is_active'] ?? false};
    _store.add(item); return CategoryModel.fromJson(item); }
  @override Future<CategoryModel> update(String id, Map<String, dynamic> data) async {
    await _d(); final i = _store.indexWhere((e) => e['id'] == id); if (i == -1) throw Exception('Not found');
    _store[i] = {..._store[i], ...data, 'id': id}; return CategoryModel.fromJson(_store[i]); }
  @override Future<void> delete(String id) async { await _d(); _store.removeWhere((e) => e['id'] == id); }
}
