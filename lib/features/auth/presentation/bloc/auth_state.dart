// auth_state.dart
// ─────────────────────────────────────────────────────────────
// Added: AuthNeedsAccountPicker — emitted when user logs out but
// other saved accounts still exist. UI navigates to picker page.
// ─────────────────────────────────────────────────────────────

import 'package:equatable/equatable.dart';
import '../../domain/entities/account_session.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any check has run.
class AuthInitial extends AuthState {}

/// Any async operation in progress.
class AuthLoading extends AuthState {}

/// Account switch animation/transition in progress.
class AuthSwitching extends AuthState {}

/// User is authenticated with an active session.
class AuthAuthenticated extends AuthState {
  final AccountSession activeSession;
  final List<AccountSession> savedAccounts;

  const AuthAuthenticated({
    required this.activeSession,
    required this.savedAccounts,
  });

  @override
  List<Object?> get props => [activeSession.user.email, savedAccounts.length];
}

/// Accounts list changed (e.g. a non-active account was removed).
class AuthAccountsUpdated extends AuthState {
  final AccountSession activeSession;
  final List<AccountSession> savedAccounts;

  const AuthAccountsUpdated({
    required this.activeSession,
    required this.savedAccounts,
  });

  @override
  List<Object?> get props => [activeSession.user.email, savedAccounts.length];
}

/// No authenticated session — navigate to login.
class AuthUnauthenticated extends AuthState {}

/// Active account was logged out but other accounts are saved.
/// UI should navigate to AccountPickerPage instead of login.
class AuthNeedsAccountPicker extends AuthState {
  final List<AccountSession> savedAccounts;

  const AuthNeedsAccountPicker({required this.savedAccounts});

  @override
  List<Object?> get props => [savedAccounts.length];
}

/// An error message to display (shown via SnackBar or inline).
class AuthFailureState extends AuthState {
  final String message;

  const AuthFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
