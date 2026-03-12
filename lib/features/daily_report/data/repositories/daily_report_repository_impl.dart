import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/daily_report_entity.dart';
import '../../domain/repositories/daily_report_repository.dart';
import '../models/daily_report_model.dart';
import '../datasources/daily_report_remote_datasource.dart';

class DailyReportRepositoryImpl implements DailyReportRepository {
  final DailyReportRemoteDataSource _remoteDataSource;

  DailyReportRepositoryImpl({
    required DailyReportRemoteDataSource remoteDataSource,
  })  :         _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<DailyReportEntity>>> getAll() async {
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
  Future<Either<Failure, DailyReportEntity>> getById(String id) async {
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
  Future<Either<Failure, DailyReportEntity>> create(DailyReportEntity entity) async {
    try {
      final model = DailyReportModel.fromEntity(entity);
      final result = await _remoteDataSource.create(model.toJson());
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DailyReportEntity>> update(DailyReportEntity entity) async {
    try {
      final model = DailyReportModel.fromEntity(entity);
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
