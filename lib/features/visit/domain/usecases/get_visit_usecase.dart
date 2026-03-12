import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/visit_entity.dart';
import '../repositories/visit_repository.dart';

class GetVisitParams {
  final String id;
  const GetVisitParams({required this.id});
}

class GetVisitUseCase implements UseCase<VisitEntity, GetVisitParams> {
  final VisitRepository repository;
  GetVisitUseCase(this.repository);

  @override
  Future<Either<Failure, VisitEntity>> call(GetVisitParams p) =>
      repository.getById(p.id);
}
