import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/officer_entity.dart';
import '../repositories/officer_repository.dart';

class CreateOfficerParams {
  final String name;
  final String email;
  final String phone;
  final String role;

  const CreateOfficerParams({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });
}

class CreateOfficerUseCase implements UseCase<OfficerEntity, CreateOfficerParams> {
  final OfficerRepository repository;
  CreateOfficerUseCase(this.repository);

  @override
  Future<Either<Failure, OfficerEntity>> call(CreateOfficerParams p) async {
    // -- Validation gate --
    if (p.name.trim().isEmpty) {
      return const Left(ValidationFailure('Officer name is required'));
    }
    if (p.name.trim().length < 2) {
      return const Left(ValidationFailure('Name must be at least 2 characters'));
    }
    if (p.email.trim().isEmpty) {
      return const Left(ValidationFailure('Email is required'));
    }
    if (p.phone.trim().isEmpty) {
      return const Left(ValidationFailure('Phone number is required'));
    }
    if (p.role.trim().isEmpty) {
      return const Left(ValidationFailure('Role is required'));
    }

    return repository.create(
      OfficerEntity(
        id: '',
        name: p.name.trim(),
        email: p.email.trim(),
        phone: p.phone.trim(),
        role: p.role.trim(),
        status: '',
        createdAt: DateTime.now(),
      ),
    );
  }
}
