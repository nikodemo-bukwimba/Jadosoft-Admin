import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/officer_entity.dart';
import '../repositories/officer_repository.dart';
import '../../../../core/network/paginated_response.dart';

class GetAllOfficerUseCase implements UseCase<PaginatedResponse<OfficerEntity>, NoParams> {
  final OfficerRepository repository;
  GetAllOfficerUseCase(this.repository);

  @override
  Future<Either<Failure, List<OfficerEntity>>> call(NoParams _) =>
      repository.getAll();
}
