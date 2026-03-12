import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/officer_entity.dart';
import '../../domain/repositories/officer_repository.dart';
import '../models/officer_model.dart';
import '../datasources/officer_remote_datasource.dart';

class OfficerRepositoryImpl implements OfficerRepository {
  final OfficerRemoteDataSource _remoteDataSource;

  OfficerRepositoryImpl({
    required OfficerRemoteDataSource remoteDataSource,
  })  :         _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<OfficerEntity>>> getAll() async {
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
  Future<Either<Failure, OfficerEntity>> getById(String id) async {
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
  Future<Either<Failure, OfficerEntity>> create(OfficerEntity entity) async {
    try {
      final model = OfficerModel.fromEntity(entity);
      final result = await _remoteDataSource.create(model.toJson());
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OfficerEntity>> update(OfficerEntity entity) async {
    try {
      final model = OfficerModel.fromEntity(entity);
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
