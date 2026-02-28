import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/hello_repository.dart';

class DeleteHelloParams {
  final String id;
  const DeleteHelloParams({required this.id});
}

class DeleteHelloUseCase implements UseCase<void, DeleteHelloParams> {
  final HelloRepository repository;
  DeleteHelloUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteHelloParams p) =>
      repository.delete(p.id);
}
