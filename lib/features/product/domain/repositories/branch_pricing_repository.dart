// lib/features/product/domain/repositories/branch_pricing_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/branch_variant_price_entity.dart';

abstract class BranchPricingRepository {
  /// List all variant price overrides set by [orgId].
  Future<Either<Failure, List<BranchVariantPriceEntity>>> listOverrides(
    String orgId,
  );

  /// Create or update the branch override price for [variantId] in [orgId].
  Future<Either<Failure, BranchVariantPriceEntity>> setOverride({
    required String orgId,
    required String variantId,
    required double price,
    String currency,
  });

  /// Remove the branch override — falls back to root base_price.
  Future<Either<Failure, void>> removeOverride({
    required String orgId,
    required String variantId,
  });
}