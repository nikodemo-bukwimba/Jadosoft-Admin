// profile_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:fca/core/error/exceptions.dart';
import 'package:fca/core/error/failures.dart';
 
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;
  ProfileRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, ProfileEntity>> getOwnProfile() async {
    try {
      final profile = await _remote.getOwnProfile();
      return Right(profile);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }
}
