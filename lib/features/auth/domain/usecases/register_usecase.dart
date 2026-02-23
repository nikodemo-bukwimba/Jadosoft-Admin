// register_usecase.dart  [R5 — Two-Gate Input Validation]
// ─────────────────────────────────────────────────────────────
// Security gate for registration. Validates before any network call.
// Mirrors the validation the Laravel backend also enforces (R8).
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/account_session.dart';
import '../repositories/auth_repository.dart';

class RegisterParams {
  final String  name;
  final String  email;
  final String  password;
  final String  passwordConfirmation;
  final String? phone;

  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.phone,
  });
}

class RegisterUseCase implements UseCase<AccountSession, RegisterParams> {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  @override
  Future<Either<Failure, AccountSession>> call(RegisterParams p) async {
    // ── Security gate (R5) ────────────────────────────────
    final nameTrimmed  = p.name.trim();
    final emailTrimmed = p.email.trim().toLowerCase();

    if (nameTrimmed.isEmpty) {
      return const Left(ValidationFailure('Name is required'));
    }
    if (nameTrimmed.length < 2) {
      return const Left(ValidationFailure('Name must be at least 2 characters'));
    }
    if (nameTrimmed.length > 100) {
      return const Left(ValidationFailure('Name is too long'));
    }
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
    if (p.password != p.passwordConfirmation) {
      return const Left(ValidationFailure('Passwords do not match'));
    }
    if (p.phone != null && p.phone!.isNotEmpty) {
      if (!_isValidPhone(p.phone!)) {
        return const Left(ValidationFailure('Enter a valid phone number'));
      }
    }

    return _repository.register(
      name:                 nameTrimmed,
      email:                emailTrimmed,
      password:             p.password,
      passwordConfirmation: p.passwordConfirmation,
      phone:                p.phone,
    );
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(email);

  bool _isValidPhone(String phone) =>
      RegExp(r'^\+?\d{7,15}$').hasMatch(phone.replaceAll(RegExp(r'[\s\-()]'), ''));
}
