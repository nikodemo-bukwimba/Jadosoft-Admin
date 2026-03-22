import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/officer_repository.dart';

class DeleteOfficerParams {
  final String id;
  const DeleteOfficerParams({required this.id});
}

class DeleteOfficerUseCase implements UseCase<void, DeleteOfficerParams> {
  final OfficerRepository repository;
  DeleteOfficerUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteOfficerParams p) =>
      repository.remove(p);
}
