// auth_repository.dart
// ─────────────────────────────────────────────────────────────
// Abstract interface — domain layer depends only on this.
// The data layer provides the concrete implementation.
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/account_session.dart';

abstract class AuthRepository {
  // ── Remote operations ─────────────────────────────────────

  /// Authenticate with the API. On success, stores the session
  /// locally and sets it as the active account.
  Future<Either<Failure, AccountSession>> login({
    required String email,
    required String password,
  });

  /// Register a new user. On success, logs in automatically.
  Future<Either<Failure, AccountSession>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  });

  /// Revoke the active account's Sanctum token on the server,
  /// then remove it from local storage.
  Future<Either<Failure, void>> logout();

  /// Revoke a specific account's token (by email) and remove it.
  Future<Either<Failure, void>> logoutAccount(String email);

  // ── Local / multi-account operations ─────────────────────

  /// Returns all accounts currently stored on this device.
  Future<Either<Failure, List<AccountSession>>> getSavedAccounts();

  /// Returns the currently active account session, or null.
  Future<Either<Failure, AccountSession?>> getActiveSession();

  /// Switch the active account to the one with this email.
  /// The target account must already be stored locally.
  Future<Either<Failure, AccountSession>> switchAccount(String email);

  /// Fetch fresh user data + roles from the API for the active account
  /// and update the stored session.
  Future<Either<Failure, AccountSession>> refreshSession();
}
