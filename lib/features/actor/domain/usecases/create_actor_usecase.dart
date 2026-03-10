import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/actor_entity.dart';
import '../repositories/actor_repository.dart';

class CreateActorParams {
  final String displayName;
  final String status;

  const CreateActorParams({
    required this.displayName,
    required this.status,
  });
}

class CreateActorUseCase implements UseCase<ActorEntity, CreateActorParams> {
  final ActorRepository repository;
  CreateActorUseCase(this.repository);

  @override
  Future<Either<Failure, ActorEntity>> call(CreateActorParams p) async {
    // ── Validation gate ─────────────────────────────────
    if (p.displayName.trim().isEmpty) {
      return Left(ValidationFailure('Display name is required'));
    }
    if (p.displayName.length < 2) {
      return Left(ValidationFailure('Name must be at least 2 characters'));
    }
    if (p.status.trim().isEmpty) {
      return Left(ValidationFailure('Status is required'));
    }

    return repository.create(
      ActorEntity(
        id: '',
        displayName: p.displayName.trim(),
        status: p.status.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}
