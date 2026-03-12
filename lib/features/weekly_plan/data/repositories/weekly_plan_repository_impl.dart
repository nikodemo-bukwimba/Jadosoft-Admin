import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/weekly_plan_entity.dart';
import '../../domain/repositories/weekly_plan_repository.dart';
import '../models/weekly_plan_model.dart';
import '../datasources/weekly_plan_remote_datasource.dart';

class WeeklyPlanRepositoryImpl implements WeeklyPlanRepository {
  final WeeklyPlanRemoteDataSource _remoteDataSource;

  WeeklyPlanRepositoryImpl({
    required WeeklyPlanRemoteDataSource remoteDataSource,
  })  :         _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<WeeklyPlanEntity>>> getAll() async {
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
  Future<Either<Failure, WeeklyPlanEntity>> getById(String id) async {
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
  Future<Either<Failure, WeeklyPlanEntity>> create(WeeklyPlanEntity entity) async {
    try {
      final model = WeeklyPlanModel.fromEntity(entity);
      final result = await _remoteDataSource.create(model.toJson());
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WeeklyPlanEntity>> update(WeeklyPlanEntity entity) async {
    try {
      final model = WeeklyPlanModel.fromEntity(entity);
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
