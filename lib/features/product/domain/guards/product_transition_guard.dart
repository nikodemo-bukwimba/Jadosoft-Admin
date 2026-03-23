import '../entities/product_entity.dart';
import '../value_objects/product_status.dart';

/// Defines valid transitions and guard logic for the product status machine.
///
/// Status machine:
///   draft → active   (publish)
///   active → archived (archive)
class ProductTransitionGuard {
  const ProductTransitionGuard();

  /// Returns `true` if the transition [name] is valid for [product].
  bool canTransition(ProductEntity product, String transitionName) {
    switch (transitionName) {
      case 'publish':
        return product.status == ProductStatus.draft;
      case 'archive':
        return product.status == ProductStatus.active;
      default:
        return false;
    }
  }

  /// Returns the target status for a given [transitionName], or null
  /// if the transition is unknown.
  ProductStatus? targetStatus(String transitionName) {
    switch (transitionName) {
      case 'publish':
        return ProductStatus.active;
      case 'archive':
        return ProductStatus.archived;
      default:
        return null;
    }
  }

  /// Returns all valid transition names for the given [status].
  List<String> availableTransitions(ProductStatus status) {
    switch (status) {
      case ProductStatus.draft:
        return ['publish'];
      case ProductStatus.active:
        return ['archive'];
      case ProductStatus.archived:
        return [];
    }
  }
}
