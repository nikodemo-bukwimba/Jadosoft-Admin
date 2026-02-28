import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/h_e_l_l_o_entity.dart';
import '../repositories/hello_repository.dart';

class GetAllHelloUseCase implements UseCase<List<HelloEntity>, NoParams> {
  final HelloRepository repository;
  GetAllHelloUseCase(this.repository);

  @override
  Future<Either<Failure, List<HelloEntity>>> call(NoParams _) =>
      repository.getAll();
}
