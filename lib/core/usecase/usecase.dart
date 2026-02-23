// usecase.dart
// Abstract base for all use cases.
// Every use case: takes Params, returns Either<Failure, Type>.

import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {}
