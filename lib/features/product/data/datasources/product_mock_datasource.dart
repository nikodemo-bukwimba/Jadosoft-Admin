import '../../domain/entities/product_entity.dart';
import '../../domain/value_objects/product_status.dart';
import '../models/product_model.dart';
import 'product_remote_datasource.dart';

/// In-memory mock datasource for product development and testing.
class ProductMockDatasource implements ProductRemoteDatasource {
  final List<ProductModel> _products = List.from(_seedProducts);

  @override
  Future<List<ProductModel>> getAll({
    required String orgId,
    int page = 1,
    int perPage = 25,
    String? status,
    String? type,
    String? search,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    var filtered = List<ProductModel>.from(_products);

    if (status != null) {
      filtered = filtered
          .where((p) => p.status.name == status)
          .toList();
    }
    if (type != null) {
      filtered = filtered
          .where((p) => p.type.name == type)
          .toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    final start = (page - 1) * perPage;
    if (start >= filtered.length) return [];
    final end = (start + perPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  @override
  Future<ProductModel> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _products.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Product not found'),
    );
  }

  @override
  Future<ProductModel> create({
    required String orgId,
    required ProductModel product,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final created = ProductModel(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      name: product.name,
      description: product.description,
      type: product.type,
      sellerActorId: product.sellerActorId,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      price: product.price,
      currency: product.currency,
      sku: product.sku,
      imageUrl: product.imageUrl,
      imageUrls: product.imageUrls,
      status: ProductStatus.draft,
      isFeatured: false,
      isNew: true,
      isAvailable: true,
      trackInventory: product.trackInventory,
      requiresConfirmation: product.requiresConfirmation,
      defaultVariantId: 'var_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _products.insert(0, created);
    return created;
  }

  @override
  Future<ProductModel> update(ProductModel product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx == -1) throw Exception('Product not found');

    final updated = ProductModel(
      id: product.id,
      name: product.name,
      description: product.description,
      type: _products[idx].type,
      sellerActorId: _products[idx].sellerActorId,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      price: _products[idx].price,
      currency: _products[idx].currency,
      sku: _products[idx].sku,
      imageUrl: _products[idx].imageUrl,
      imageUrls: _products[idx].imageUrls,
      status: _products[idx].status,
      isFeatured: _products[idx].isFeatured,
      isNew: _products[idx].isNew,
      isAvailable: _products[idx].isAvailable,
      trackInventory: product.trackInventory,
      requiresConfirmation: product.requiresConfirmation,
      defaultVariantId: _products[idx].defaultVariantId,
      createdAt: _products[idx].createdAt,
      updatedAt: DateTime.now(),
    );
    _products[idx] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _products.removeWhere((p) => p.id == id);
  }

  @override
  Future<ProductModel> publish(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx == -1) throw Exception('Product not found');

    final published = ProductModel(
      id: _products[idx].id,
      name: _products[idx].name,
      description: _products[idx].description,
      type: _products[idx].type,
      sellerActorId: _products[idx].sellerActorId,
      categoryId: _products[idx].categoryId,
      categoryName: _products[idx].categoryName,
      price: _products[idx].price,
      currency: _products[idx].currency,
      sku: _products[idx].sku,
      imageUrl: _products[idx].imageUrl,
      imageUrls: _products[idx].imageUrls,
      status: ProductStatus.active,
      isFeatured: _products[idx].isFeatured,
      isNew: _products[idx].isNew,
      isAvailable: true,
      trackInventory: _products[idx].trackInventory,
      requiresConfirmation: _products[idx].requiresConfirmation,
      defaultVariantId: _products[idx].defaultVariantId,
      createdAt: _products[idx].createdAt,
      updatedAt: DateTime.now(),
    );
    _products[idx] = published;
    return published;
  }

  @override
  Future<ProductModel> archive(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx == -1) throw Exception('Product not found');

    final archived = ProductModel(
      id: _products[idx].id,
      name: _products[idx].name,
      description: _products[idx].description,
      type: _products[idx].type,
      sellerActorId: _products[idx].sellerActorId,
      categoryId: _products[idx].categoryId,
      categoryName: _products[idx].categoryName,
      price: _products[idx].price,
      currency: _products[idx].currency,
      sku: _products[idx].sku,
      imageUrl: _products[idx].imageUrl,
      imageUrls: _products[idx].imageUrls,
      status: ProductStatus.archived,
      isFeatured: false,
      isNew: false,
      isAvailable: false,
      trackInventory: _products[idx].trackInventory,
      requiresConfirmation: _products[idx].requiresConfirmation,
      defaultVariantId: _products[idx].defaultVariantId,
      createdAt: _products[idx].createdAt,
      updatedAt: DateTime.now(),
    );
    _products[idx] = archived;
    return archived;
  }

  // ── Seed data ─────────────────────────────────────────────────────

  static final List<ProductModel> _seedProducts = [
    ProductModel(
      id: 'mock_prod_001',
      name: 'Amoxicillin 500mg',
      description: 'Broad-spectrum antibiotic capsules, 30-count blister pack.',
      type: ProductType.physical,
      sellerActorId: 'mock_seller_001',
      categoryId: 'mock_cat_001',
      categoryName: 'Antibiotics',
      price: 15000.00,
      currency: 'TZS',
      sku: 'AMX-500-30',
      imageUrl: null,
      status: ProductStatus.active,
      isFeatured: true,
      isNew: false,
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ProductModel(
      id: 'mock_prod_002',
      name: 'Paracetamol 500mg',
      description: 'Analgesic and antipyretic tablets, 100-count bottle.',
      type: ProductType.physical,
      sellerActorId: 'mock_seller_001',
      categoryId: 'mock_cat_002',
      categoryName: 'Pain Relief',
      price: 8500.00,
      currency: 'TZS',
      sku: 'PCM-500-100',
      status: ProductStatus.active,
      isFeatured: false,
      isNew: false,
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    ProductModel(
      id: 'mock_prod_003',
      name: 'Metformin 850mg',
      description: 'Oral hypoglycaemic agent for type 2 diabetes management.',
      type: ProductType.physical,
      sellerActorId: 'mock_seller_001',
      categoryId: 'mock_cat_003',
      categoryName: 'Diabetes Care',
      price: 22000.00,
      currency: 'TZS',
      sku: 'MET-850-60',
      status: ProductStatus.draft,
      isFeatured: false,
      isNew: true,
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: 'mock_prod_004',
      name: 'Vitamin C 1000mg',
      description: 'Effervescent vitamin C tablets, orange flavour, 20-count tube.',
      type: ProductType.physical,
      sellerActorId: 'mock_seller_001',
      categoryId: 'mock_cat_004',
      categoryName: 'Vitamins & Supplements',
      price: 12000.00,
      currency: 'TZS',
      sku: 'VTC-1000-20',
      status: ProductStatus.archived,
      isFeatured: false,
      isNew: false,
      isAvailable: false,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      updatedAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
  ];
}
