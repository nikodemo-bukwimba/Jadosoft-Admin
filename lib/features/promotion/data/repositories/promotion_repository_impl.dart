import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/promotion_entity.dart';
import '../../domain/repositories/promotion_repository.dart';
import '../models/promotion_model.dart';
import '../datasources/promotion_remote_datasource.dart';

class PromotionRepositoryImpl implements PromotionRepository {
  final PromotionRemoteDataSource _remoteDataSource;

  PromotionRepositoryImpl({
    required PromotionRemoteDataSource remoteDataSource,
  })  :         _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<PromotionEntity>>> getAll() async {
    try {
      final result = await _remoteDataSource.getAll();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PromotionEntity>> getById(String id) async {
    try {
      final result = await _remoteDataSource.getById(id);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PromotionEntity>> create(PromotionEntity entity) async {
    try {
      final model = PromotionModel.fromEntity(entity);
      final result = await _remoteDataSource.create(model.toJson());
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PromotionEntity>> update(PromotionEntity entity) async {
    try {
      final model = PromotionModel.fromEntity(entity);
      final result = await _remoteDataSource.update(entity.id, model.toJson());
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await _remoteDataSource.delete(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }
}
