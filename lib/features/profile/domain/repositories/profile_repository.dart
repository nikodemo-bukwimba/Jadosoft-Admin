// profile_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jadosoft_admin/core/error/failures.dart';
import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  /// Fetch own profile fresh from API — GET /user + GET /me/roles.
  Future<Either<Failure, ProfileEntity>> getOwnProfile();
}
