import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/activity_log_entity.dart';
import '../../domain/repositories/activity_log_repository.dart';
import '../datasources/activity_log_remote_datasource.dart';

class ActivityLogRepositoryImpl implements ActivityLogRepository {
  final ActivityLogRemoteDataSource _remoteDataSource;

  ActivityLogRepositoryImpl({
    required ActivityLogRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<ActivityLogEntity>>> getAll() async {
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
  Future<Either<Failure, ActivityLogEntity>> getById(String id) async {
    try {
      final result = await _remoteDataSource.getById(id);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // Activity logs are written by the backend only — these are no-ops
  @override
  Future<Either<Failure, ActivityLogEntity>> create(ActivityLogEntity entity) async =>
      const Left(ValidationFailure('Activity logs are written by the backend only'));

  @override
  Future<Either<Failure, ActivityLogEntity>> update(ActivityLogEntity entity) async =>
      const Left(ValidationFailure('Activity logs are immutable'));

  @override
  Future<Either<Failure, void>> delete(String id) async =>
      const Left(ValidationFailure('Activity logs cannot be deleted'));
}