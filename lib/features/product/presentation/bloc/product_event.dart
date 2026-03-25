import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/create_product_usecase.dart';

abstract class ProductEvent {}

class ProductLoadAllRequested extends ProductEvent {}

class ProductLoadOneRequested extends ProductEvent {
  final String id;
  ProductLoadOneRequested(this.id);
}

class ProductCreateRequested extends ProductEvent {
  final CreateProductParams params;
  ProductCreateRequested(this.params);
}

class ProductUpdateRequested extends ProductEvent {
  final ProductEntity entity;
  ProductUpdateRequested(this.entity);
}

class ProductDeleteRequested extends ProductEvent {
  final String id;
  ProductDeleteRequested(this.id);
}

class ProductFormReset extends ProductEvent {}

class ProductPublishRequested extends ProductEvent {
  final String id;
  ProductPublishRequested(this.id);
}
class ProductFeatureRequested extends ProductEvent {
  final String id;
  ProductFeatureRequested(this.id);
}
class ProductUnfeatureRequested extends ProductEvent {
  final String id;
  ProductUnfeatureRequested(this.id);
}
class ProductArchiveRequested extends ProductEvent {
  final String id;
  ProductArchiveRequested(this.id);
}
