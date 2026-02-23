// auth_bloc.dart
// ─────────────────────────────────────────────────────────────
// Key change: logout now emits AuthNeedsAccountPicker when other
// saved accounts exist, instead of going straight to login.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/account_session.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/switch_account_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;
  final LogoutAccountUseCase _logoutAccount;
  final SwitchAccountUseCase _switchAccount;
  final GetActiveSessionUseCase _getActiveSession;
  final GetSavedAccountsUseCase _getSavedAccounts;
  final RefreshSessionUseCase _refreshSession;

  AuthBloc({
    required LoginUseCase login,
    required RegisterUseCase register,
    required LogoutUseCase logout,
    required LogoutAccountUseCase logoutAccount,
    required SwitchAccountUseCase switchAccount,
    required GetActiveSessionUseCase getActiveSession,
    required GetSavedAccountsUseCase getSavedAccounts,
    required RefreshSessionUseCase refreshSession,
  }) : _login = login,
       _register = register,
       _logout = logout,
       _logoutAccount = logoutAccount,
       _switchAccount = switchAccount,
       _getActiveSession = getActiveSession,
       _getSavedAccounts = getSavedAccounts,
       _refreshSession = refreshSession,
       super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthLogoutAccountRequested>(_onLogoutAccountRequested);
    on<AuthSwitchAccountRequested>(_onSwitchAccountRequested);
    on<AuthAccountsRefreshRequested>(_onAccountsRefreshRequested);
    on<AuthSessionRefreshRequested>(_onSessionRefreshRequested);
  }

  // ── Startup check ─────────────────────────────────────────
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final sessionResult = await _getActiveSession(NoParams());

    await sessionResult.fold((_) async => emit(AuthUnauthenticated()), (
      session,
    ) async {
      if (session == null) {
        // No active session — check if any accounts are saved
        final accountsResult = await _getSavedAccounts(NoParams());
        final saved = accountsResult.fold<List<AccountSession>>(
          (_) => <AccountSession>[],
          (List<AccountSession> a) => a,
        );
        if (saved.isNotEmpty) {
          // Accounts exist but none active — show picker
          emit(AuthNeedsAccountPicker(savedAccounts: saved));
        } else {
          emit(AuthUnauthenticated());
        }
        return;
      }

      final accountsResult = await _getSavedAccounts(NoParams());
      final savedAccounts = accountsResult.fold<List<AccountSession>>(
        (_) => <AccountSession>[session],
        (List<AccountSession> a) => a,
      );
      emit(
        AuthAuthenticated(activeSession: session, savedAccounts: savedAccounts),
      );
    });
  }

  // ── Login ─────────────────────────────────────────────────
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _login(
      LoginParams(email: event.email, password: event.password),
    );

    await result.fold(
      (failure) async => emit(AuthFailureState(failure.message)),
      (session) async {
        final accountsResult = await _getSavedAccounts(NoParams());
        final savedAccounts = accountsResult.fold<List<AccountSession>>(
          (_) => <AccountSession>[session],
          (List<AccountSession> a) => a,
        );
        emit(
          AuthAuthenticated(
            activeSession: session,
            savedAccounts: savedAccounts,
          ),
        );
      },
    );
  }

  // ── Register ──────────────────────────────────────────────
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _register(
      RegisterParams(
        name: event.name,
        email: event.email,
        password: event.password,
        passwordConfirmation: event.passwordConfirmation,
        phone: event.phone,
      ),
    );

    await result.fold(
      (failure) async => emit(AuthFailureState(failure.message)),
      (session) async {
        final accountsResult = await _getSavedAccounts(NoParams());
        final savedAccounts = accountsResult.fold<List<AccountSession>>(
          (_) => <AccountSession>[session],
          (List<AccountSession> a) => a,
        );
        emit(
          AuthAuthenticated(
            activeSession: session,
            savedAccounts: savedAccounts,
          ),
        );
      },
    );
  }

  // ── Logout active account ─────────────────────────────────
  // KEY CHANGE: emits AuthNeedsAccountPicker if other accounts remain.
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _logout(NoParams());

    await result.fold(
      (failure) async => emit(AuthFailureState(failure.message)),
      (_) async {
        final accountsResult = await _getSavedAccounts(NoParams());
        final remaining = accountsResult.fold<List<AccountSession>>(
          (_) => <AccountSession>[],
          (List<AccountSession> a) => a,
        );

        if (remaining.isEmpty) {
          // No other accounts → go to login
          emit(AuthUnauthenticated());
        } else {
          // Other accounts exist → show picker
          emit(AuthNeedsAccountPicker(savedAccounts: remaining));
        }
      },
    );
  }

  // ── Logout specific account ───────────────────────────────
  Future<void> _onLogoutAccountRequested(
    AuthLogoutAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _logoutAccount(LogoutAccountParams(event.email));

    await result.fold(
      (failure) async => emit(AuthFailureState(failure.message)),
      (_) async {
        final accountsResult = await _getSavedAccounts(NoParams());
        final remaining = accountsResult.fold<List<AccountSession>>(
          (_) => <AccountSession>[],
          (List<AccountSession> a) => a,
        );

        if (remaining.isEmpty) {
          emit(AuthUnauthenticated());
          return;
        }

        // Check if there's still an active session
        final sessionResult = await _getActiveSession(NoParams());
        sessionResult.fold(
          (_) => emit(AuthNeedsAccountPicker(savedAccounts: remaining)),
          (session) {
            if (session == null) {
              // The removed account was the active one — show picker
              emit(AuthNeedsAccountPicker(savedAccounts: remaining));
            } else {
              // Active account untouched — just update the list
              emit(
                AuthAccountsUpdated(
                  activeSession: session,
                  savedAccounts: remaining,
                ),
              );
            }
          },
        );
      },
    );
  }

  // ── Switch account ────────────────────────────────────────
  Future<void> _onSwitchAccountRequested(
    AuthSwitchAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthSwitching());

    final result = await _switchAccount(SwitchAccountParams(event.email));

    await result.fold(
      (failure) async {
        final sessionResult = await _getActiveSession(NoParams());
        sessionResult.fold((_) => emit(AuthFailureState(failure.message)), (
          session,
        ) {
          if (session == null) {
            emit(AuthUnauthenticated());
          } else {
            emit(AuthFailureState(failure.message));
          }
        });
      },
      (newSession) async {
        final accountsResult = await _getSavedAccounts(NoParams());
        final savedAccounts = accountsResult.fold<List<AccountSession>>(
          (_) => <AccountSession>[newSession],
          (List<AccountSession> a) => a,
        );
        emit(
          AuthAuthenticated(
            activeSession: newSession,
            savedAccounts: savedAccounts,
          ),
        );
      },
    );
  }

  // ── Refresh accounts list ─────────────────────────────────
  Future<void> _onAccountsRefreshRequested(
    AuthAccountsRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final sessionResult = await _getActiveSession(NoParams());
    final accountsResult = await _getSavedAccounts(NoParams());

    sessionResult.fold((_) => emit(AuthUnauthenticated()), (session) {
      if (session == null) {
        final saved = accountsResult.fold<List<AccountSession>>(
          (_) => <AccountSession>[],
          (List<AccountSession> a) => a,
        );
        if (saved.isNotEmpty) {
          emit(AuthNeedsAccountPicker(savedAccounts: saved));
        } else {
          emit(AuthUnauthenticated());
        }
        return;
      }

      final saved = accountsResult.fold<List<AccountSession>>(
        (_) => <AccountSession>[session],
        (List<AccountSession> a) => a,
      );
      emit(AuthAccountsUpdated(activeSession: session, savedAccounts: saved));
    });
  }

  // ── Refresh active session from API ───────────────────────
  Future<void> _onSessionRefreshRequested(
    AuthSessionRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _refreshSession(NoParams());

    await result.fold(
      (failure) async => emit(AuthFailureState(failure.message)),
      (session) async {
        final accountsResult = await _getSavedAccounts(NoParams());
        final savedAccounts = accountsResult.fold<List<AccountSession>>(
          (_) => <AccountSession>[session],
          (List<AccountSession> a) => a,
        );
        emit(
          AuthAuthenticated(
            activeSession: session,
            savedAccounts: savedAccounts,
          ),
        );
      },
    );
  }
}
