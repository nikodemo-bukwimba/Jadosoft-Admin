// lib/features/product/domain/usecases/get_products_with_promotions_usecase.dart
//
// Fetches products and active promotions in parallel, then applies
// client-side promotion pricing as a fallback layer.
//
// WHEN THIS IS USED
// ─────────────────────────────────────────────────────────────
// Dispatch ProductLoadWithPromotionsRequested from ProductBloc when you
// want guaranteed promotion-aware pricing regardless of whether the API
// decorates product responses server-side.
//
// WHEN NOT TO USE
// ─────────────────────────────────────────────────────────────
// If the API already returns effective_price on every product (production
// Nexora with PromotionPricingService active), the existing
// ProductLoadAllRequested path is sufficient — this use case becomes a
// no-op decorator (all products are skipped as server-decorated).
//
// DEPENDENCY FLOW
// ─────────────────────────────────────────────────────────────
//   ProductRepository   (existing)
//   PromotionRepository (existing, already registered)
//   ClientPromotionPricingService (new, pure-Dart, no side-effects)
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/services/client_promotion_pricing_service.dart';
import '../../../promotion/domain/repositories/promotion_repository.dart';

class GetProductsWithPromotionsUseCase
    implements UseCase<List<ProductEntity>, NoParams> {
  final ProductRepository _products;
  final PromotionRepository _promotions;
  final ClientPromotionPricingService _pricingService;

  const GetProductsWithPromotionsUseCase({
    required ProductRepository products,
    required PromotionRepository promotions,
    required ClientPromotionPricingService pricingService,
  })  : _products = products,
        _promotions = promotions,
        _pricingService = pricingService;

  @override
  Future<Either<Failure, List<ProductEntity>>> call(NoParams _) async {
    // Parallel fetch — promotion failure is non-fatal
    final results = await Future.wait([
      _products.getAll(),
      _promotions.getAll(),
    ]);

    final productResult = results[0] as Either<Failure, List<ProductEntity>>;
    final promotionResult = results[1] as Either<Failure, dynamic>;

    // Products are required; surface the failure if they failed
    if (productResult.isLeft()) return productResult;

    final products = productResult.getOrElse(() => const []);

    // Promotions are optional — if they fail, return plain products
    final promotions = promotionResult.fold(
      (_) => const [],
      (items) => items as List,
    );

    if (promotions.isEmpty) {
      return Right(products);
    }

    // Apply client-side pricing (no-op if server already decorated)
    final decorated = _pricingService.decorateProducts(
      products,
      List.from(promotions),
    );

    return Right(decorated);
  }
}