import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/h_e_l_l_o_entity.dart';
import '../repositories/hello_repository.dart';

class UpdateHelloParams {
  final HelloEntity entity;
  const UpdateHelloParams({required this.entity});
}

class UpdateHelloUseCase implements UseCase<HelloEntity, UpdateHelloParams> {
  final HelloRepository repository;
  UpdateHelloUseCase(this.repository);

  @override
  Future<Either<Failure, HelloEntity>> call(UpdateHelloParams p) async {
    return repository.update(p.entity);
  }
}
