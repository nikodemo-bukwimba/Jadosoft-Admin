// get_profile_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:fca/core/error/failures.dart';
import 'package:fca/core/usecase/usecase.dart';
 
import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase implements UseCase<ProfileEntity, NoParams> {
  final ProfileRepository _repository;
  GetProfileUseCase(this._repository);

  @override
  Future<Either<Failure, ProfileEntity>> call(NoParams _) =>
      _repository.getOwnProfile();
}
