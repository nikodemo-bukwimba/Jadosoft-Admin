// switch_account_usecase.dart
// ─────────────────────────────────────────────────────────────
// Switches the active account to an already-stored session.
// Does NOT call the network — purely a local pointer change.
// If the target email is not stored, returns AuthFailure.
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/account_session.dart';
import '../repositories/auth_repository.dart';

class SwitchAccountParams {
  final String email;
  const SwitchAccountParams(this.email);
}

class SwitchAccountUseCase implements UseCase<AccountSession, SwitchAccountParams> {
  final AuthRepository _repository;
  SwitchAccountUseCase(this._repository);

  @override
  Future<Either<Failure, AccountSession>> call(SwitchAccountParams p) async {
    if (p.email.trim().isEmpty) {
      return const Left(ValidationFailure('Account email is required'));
    }
    return _repository.switchAccount(p.email.trim().toLowerCase());
  }
}
