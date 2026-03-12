import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/visit_entity.dart';
import '../repositories/visit_repository.dart';

class GetAllVisitUseCase implements UseCase<List<VisitEntity>, NoParams> {
  final VisitRepository repository;
  GetAllVisitUseCase(this.repository);

  @override
  Future<Either<Failure, List<VisitEntity>>> call(NoParams _) =>
      repository.getAll();
}
