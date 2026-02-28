import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/h_e_l_l_o_entity.dart';
import '../repositories/hello_repository.dart';

class CreateHelloParams {
  final String name;

  const CreateHelloParams({
    required this.name,
  });
}

class CreateHelloUseCase implements UseCase<HelloEntity, CreateHelloParams> {
  final HelloRepository repository;
  CreateHelloUseCase(this.repository);

  @override
  Future<Either<Failure, HelloEntity>> call(CreateHelloParams p) async {
    // ── Validation gate ─────────────────────────────────
    // No validation rules configured

    return repository.create(
      HelloEntity(
        id: '',
        name: p.name,
        createdAt: DateTime.now(),
      ),
    );
  }
}
