import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/project_entity.dart';
import '../repositories/project_repository.dart';

class CreateProjectParams {
  final String name;
  final String? description;
  final double? budget;
  final bool isPublic;
  final DateTime? startDate;

  const CreateProjectParams({
    required this.name,
    this.description,
    this.budget,
    required this.isPublic,
    this.startDate,
  });
}

class CreateProjectUseCase implements UseCase<ProjectEntity, CreateProjectParams> {
  final ProjectRepository repository;
  CreateProjectUseCase(this.repository);

  @override
  Future<Either<Failure, ProjectEntity>> call(CreateProjectParams p) async {
    // ── Validation gate ─────────────────────────────────
    if (p.name.trim().isEmpty) {
      return const Left(ValidationFailure('Project name is required'));
    }
    if (p.name.trim().length < 3) {
      return const Left(ValidationFailure('Name must be at least 3 characters'));
    }

    return repository.create(
      ProjectEntity(
        id: '',
        name: p.name.trim(),
        description: p.description?.trim(),
        budget: p.budget,
        isPublic: p.isPublic,
        startDate: p.startDate,
        createdAt: DateTime.now(),
      ),
    );
  }
}
