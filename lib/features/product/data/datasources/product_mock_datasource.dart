// // product_mock_datasource.dart
// // ─────────────────────────────────────────────────────────────
// // Mock implementation of ProductRemoteDataSource.
// // In-memory store with real pharmacy product images.
// //
// // To activate real API later:
// //   1. Open injection_container.dart
// //   2. Replace ProductMockDataSource() with ProductRemoteDataSourceImpl(dio: sl())
// // ─────────────────────────────────────────────────────────────

// import '../models/product_model.dart';
// import 'product_remote_datasource.dart';

// class ProductMockDataSource implements ProductRemoteDataSource {
//   static final List<Map<String, dynamic>> _store = [
//     {
//       'id': 'prod-001',
//       'name': 'Paracetamol 500mg',
//       'description':
//           'Over-the-counter pain relief and fever reducer. Pack of 20 tablets. Take 1-2 tablets every 4-6 hours as needed.',
//       'price': 2500.0,
//       'category_id': 'cat-001',
//       'is_available': true,
//       'is_featured': false,
//       'is_new': false,
//       'status': 'active',
//       'image_url':
//           'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&h=400&fit=crop',
//       'created_at': '2025-06-15T08:00:00.000Z',
//     },
//     {
//       'id': 'prod-002',
//       'name': 'Amoxicillin 250mg',
//       'description':
//           'Prescription antibiotic capsules for bacterial infections. Pack of 21 capsules. Complete full course as directed.',
//       'price': 8500.0,
//       'category_id': 'cat-002',
//       'is_available': true,
//       'is_featured': true,
//       'is_new': false,
//       'status': 'featured',
//       'image_url':
//           'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=400&h=400&fit=crop',
//       'created_at': '2025-07-01T10:00:00.000Z',
//     },
//     {
//       'id': 'prod-003',
//       'name': 'Vitamin C 1000mg',
//       'description':
//           'Daily immune support supplement. 30 effervescent tablets. Dissolve one tablet in water daily.',
//       'price': 12000.0,
//       'category_id': 'cat-003',
//       'is_available': true,
//       'is_featured': false,
//       'is_new': true,
//       'status': 'active',
//       'image_url':
//           'https://images.unsplash.com/photo-1550572017-edd951aa8f72?w=400&h=400&fit=crop',
//       'created_at': '2025-09-20T12:00:00.000Z',
//     },
//     {
//       'id': 'prod-004',
//       'name': 'Ibuprofen 400mg',
//       'description':
//           'Anti-inflammatory pain relief tablets. Pack of 16. Take with food. Not for children under 12.',
//       'price': 3500.0,
//       'category_id': 'cat-001',
//       'is_available': false,
//       'is_featured': false,
//       'is_new': false,
//       'status': 'draft',
//       'image_url':
//           'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=400&h=400&fit=crop',
//       'created_at': '2025-10-05T09:00:00.000Z',
//     },
//     {
//       'id': 'prod-005',
//       'name': 'Sterile Bandage Roll 5cm',
//       'description':
//           'Sterile cotton bandage for wound dressing. 5cm x 4m roll. Suitable for all wound types.',
//       'price': 1500.0,
//       'category_id': 'cat-004',
//       'is_available': true,
//       'is_featured': false,
//       'is_new': false,
//       'status': 'active',
//       'image_url':
//           'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=400&h=400&fit=crop',
//       'created_at': '2025-08-12T14:00:00.000Z',
//     },
//     {
//       'id': 'prod-006',
//       'name': 'Hydrocortisone Cream 1%',
//       'description':
//           'Topical anti-itch and anti-inflammatory cream. 30g tube. Apply thin layer to affected area twice daily.',
//       'price': 6000.0,
//       'category_id': 'cat-005',
//       'is_available': true,
//       'is_featured': false,
//       'is_new': true,
//       'status': 'active',
//       'image_url':
//           'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=400&h=400&fit=crop',
//       'created_at': '2025-11-01T07:30:00.000Z',
//     },
//     {
//       'id': 'prod-007',
//       'name': 'Metformin 500mg',
//       'description':
//           'Diabetes management medication. Pack of 30 tablets. Take as prescribed by physician.',
//       'price': 4500.0,
//       'category_id': 'cat-002',
//       'is_available': false,
//       'is_featured': false,
//       'is_new': false,
//       'status': 'archived',
//       'image_url':
//           'https://images.unsplash.com/photo-1559757175-7cb057fba93c?w=400&h=400&fit=crop',
//       'created_at': '2025-03-10T11:00:00.000Z',
//     },
//     {
//       'id': 'prod-008',
//       'name': 'Omeprazole 20mg',
//       'description':
//           'Proton pump inhibitor for acid reflux and heartburn. Pack of 14 capsules.',
//       'price': 5500.0,
//       'category_id': 'cat-001',
//       'is_available': true,
//       'is_featured': true,
//       'is_new': true,
//       'status': 'featured',
//       'image_url':
//           'https://images.unsplash.com/photo-1585435557343-3b092031a831?w=400&h=400&fit=crop',
//       'created_at': '2025-12-01T06:00:00.000Z',
//     },
//   ];

//   static int _idCounter = 9;

//   Future<void> _simulateDelay() =>
//       Future.delayed(const Duration(milliseconds: 400));

//   @override
//   Future<List<ProductModel>> getAll() async {
//     await _simulateDelay();
//     return _store.map((e) => ProductModel.fromJson(e)).toList();
//   }

//   @override
//   Future<ProductModel> getById(String id) async {
//     await _simulateDelay();
//     final item = _store.firstWhere(
//       (e) => e['id'] == id,
//       orElse: () => throw Exception('Product not found'),
//     );
//     return ProductModel.fromJson(item);
//   }

//   @override
//   Future<ProductModel> create(Map<String, dynamic> data) async {
//     await _simulateDelay();
//     final id = _idCounter++;
//     final newItem = {
//       'id': 'prod-${id.toString().padLeft(3, '0')}',
//       'name': data['name'] ?? '',
//       'description': data['description'],
//       'price': data['price'] ?? 0.0,
//       'category_id': data['category_id'] ?? '',
//       'is_available': data['is_available'] ?? false,
//       'is_featured': data['is_featured'] ?? false,
//       'is_new': data['is_new'] ?? false,
//       'status': 'draft',
//       'image_url': data['image_url'],
//       'created_at': DateTime.now().toIso8601String(),
//     };
//     _store.add(newItem);
//     return ProductModel.fromJson(newItem);
//   }

//   @override
//   Future<ProductModel> update(String id, Map<String, dynamic> data) async {
//     await _simulateDelay();
//     final index = _store.indexWhere((e) => e['id'] == id);
//     if (index == -1) throw Exception('Product not found');
//     _store[index] = {
//       ..._store[index],
//       ...data,
//       'id': id,
//       'created_at': _store[index]['created_at'],
//     };
//     return ProductModel.fromJson(_store[index]);
//   }

//   @override
//   Future<void> delete(String id) async {
//     await _simulateDelay();
//     _store.removeWhere((e) => e['id'] == id);
//   }
// }
