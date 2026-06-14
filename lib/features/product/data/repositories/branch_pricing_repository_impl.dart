// lib/features/product/data/repositories/branch_pricing_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/branch_variant_price_entity.dart';
import '../../domain/repositories/branch_pricing_repository.dart';
import '../datasources/branch_pricing_remote_datasource.dart';

class BranchPricingRepositoryImpl implements BranchPricingRepository {
  final BranchPricingRemoteDataSource _remote;

  const BranchPricingRepositoryImpl({
    required BranchPricingRemoteDataSource remote,
  }) : _remote = remote;

  @override
  Future<Either<Failure, List<BranchVariantPriceEntity>>> listOverrides(
    String orgId,
  ) async {
    try {
      final result = await _remote.listOverrides(orgId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BranchVariantPriceEntity>> setOverride({
    required String orgId,
    required String variantId,
    required double price,
    String currency = 'TZS',
  }) async {
    try {
      final result = await _remote.setOverride(
        orgId: orgId,
        variantId: variantId,
        price: price,
        currency: currency,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeOverride({
    required String orgId,
    required String variantId,
  }) async {
    try {
      await _remote.removeOverride(orgId: orgId, variantId: variantId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}