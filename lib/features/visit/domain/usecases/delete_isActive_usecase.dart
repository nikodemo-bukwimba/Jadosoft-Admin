// delete_isActive_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:fca/features/visit/domain/repositories/visit_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';

class DeleteVisitParams {
  final String id;
  const DeleteVisitParams({required this.id});
}

class DeleteVisitUseCase
    implements UseCase<void, DeleteVisitParams> {

  final VisitRepository repository;
  DeleteVisitUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteVisitParams params) async {
    if (params.id.isEmpty) {
      return const Left(ValidationFailure('Cannot delete: ID is required'));
    }

    // TODO: Add pre-delete domain checks here

    return repository.delete(params.id);
  }
}
