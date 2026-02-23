// login_usecase.dart  [R5 — Two-Gate Input Validation]
// ─────────────────────────────────────────────────────────────
// Security gate: validates ALL input before hitting the network.
// This gate runs for every caller regardless of origin.
// UI validation is UX-only and is never the sole defence.
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/account_session.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});
}

class LoginUseCase implements UseCase<AccountSession, LoginParams> {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  Future<Either<Failure, AccountSession>> call(LoginParams p) async {
    // ── Security gate (R5) ────────────────────────────────
    final emailTrimmed = p.email.trim().toLowerCase();

    if (emailTrimmed.isEmpty) {
      return const Left(ValidationFailure('Email is required'));
    }
    if (!_isValidEmail(emailTrimmed)) {
      return const Left(ValidationFailure('Enter a valid email address'));
    }
    if (p.password.isEmpty) {
      return const Left(ValidationFailure('Password is required'));
    }
    if (p.password.length < 8) {
      return const Left(ValidationFailure('Password must be at least 8 characters'));
    }

    return _repository.login(email: emailTrimmed, password: p.password);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
}
