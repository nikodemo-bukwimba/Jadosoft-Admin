// failures.dart
// Domain-layer error types returned via Either<Failure, T>.
// BLoCs and UI handle these — never raw exceptions.

abstract class Failure {
  final String message;
  const Failure(this.message);
}

class CacheFailure      extends Failure { const CacheFailure(super.message); }
class ServerFailure     extends Failure { const ServerFailure(super.message); }
class AuthFailure       extends Failure { const AuthFailure(super.message); }
class NetworkFailure    extends Failure { const NetworkFailure(super.message); }
class ValidationFailure extends Failure { const ValidationFailure(super.message); }
class GenericFailure    extends Failure { const GenericFailure(super.message); }
