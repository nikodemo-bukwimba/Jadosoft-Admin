import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/visit_repository.dart';

class DeleteVisitParams {
  final String id;
  const DeleteVisitParams({required this.id});
}

class DeleteVisitUseCase implements UseCase<void, DeleteVisitParams> {
  final VisitRepository repository;
  DeleteVisitUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteVisitParams p) =>
      repository.delete(p.id);
}
