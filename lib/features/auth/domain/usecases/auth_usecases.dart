// get_saved_accounts_usecase.dart
// Returns all AccountSessions stored on this device.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/account_session.dart';
import '../repositories/auth_repository.dart';

class GetSavedAccountsUseCase implements UseCase<List<AccountSession>, NoParams> {
  final AuthRepository _repository;
  GetSavedAccountsUseCase(this._repository);

  @override
  Future<Either<Failure, List<AccountSession>>> call(NoParams _) =>
      _repository.getSavedAccounts();
}

// ─────────────────────────────────────────────────────────────

// get_active_session_usecase.dart
// Returns the currently active AccountSession or null if not logged in.

class GetActiveSessionUseCase implements UseCase<AccountSession?, NoParams> {
  final AuthRepository _repository;
  GetActiveSessionUseCase(this._repository);

  @override
  Future<Either<Failure, AccountSession?>> call(NoParams _) =>
      _repository.getActiveSession();
}

// ─────────────────────────────────────────────────────────────

// refresh_session_usecase.dart
// Fetches fresh user + role data from API and updates stored session.
// Use after profile changes or on app resume.

class RefreshSessionUseCase implements UseCase<AccountSession, NoParams> {
  final AuthRepository _repository;
  RefreshSessionUseCase(this._repository);

  @override
  Future<Either<Failure, AccountSession>> call(NoParams _) =>
      _repository.refreshSession();
}

// ─────────────────────────────────────────────────────────────

// logout_account_usecase.dart
// Logs out a specific account by email (not necessarily the active one).

class LogoutAccountParams {
  final String email;
  const LogoutAccountParams(this.email);
}

class LogoutAccountUseCase implements UseCase<void, LogoutAccountParams> {
  final AuthRepository _repository;
  LogoutAccountUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(LogoutAccountParams p) =>
      _repository.logoutAccount(p.email);
}
