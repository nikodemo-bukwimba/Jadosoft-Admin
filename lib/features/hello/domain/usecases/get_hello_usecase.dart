import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/h_e_l_l_o_entity.dart';
import '../repositories/hello_repository.dart';

class GetHelloParams {
  final String id;
  const GetHelloParams({required this.id});
}

class GetHelloUseCase implements UseCase<HelloEntity, GetHelloParams> {
  final HelloRepository repository;
  GetHelloUseCase(this.repository);

  @override
  Future<Either<Failure, HelloEntity>> call(GetHelloParams p) =>
      repository.getById(p.id);
}
