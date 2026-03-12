import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/visit_entity.dart';
import '../repositories/visit_repository.dart';

class UpdateVisitParams {
  final VisitEntity entity;
  const UpdateVisitParams({required this.entity});
}

class UpdateVisitUseCase implements UseCase<VisitEntity, UpdateVisitParams> {
  final VisitRepository repository;
  UpdateVisitUseCase(this.repository);

  @override
  Future<Either<Failure, VisitEntity>> call(UpdateVisitParams p) async {
    return repository.update(p.entity);
  }
}
