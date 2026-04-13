// auth_bloc.dart
// ─────────────────────────────────────────────────────────────
// FIX: OrgContext was never populated after login/session restore,
// causing every feature that calls orgContext.requireRootOrgId()
// to throw "Bad state: no org is set" and stay stuck on loading.
//
// Changes:
//   1. OrgContext injected as a dependency.
//   2. _applyOrgContext() called after every successful auth
//      (login, register, check, switch, refresh).
//   3. orgContext.restore() called in _onCheckRequested so a
//      returning user's org context is recovered from secure
//      storage without re-login.
//   4. orgContext.clear() called on logout.
//
// Org strategy: Barick Pharmacy is a single-org admin app.
// AppConstants.orgId is the root org ULID — used directly.
// Role is derived from the session's primaryRole slug.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/context/org_context.dart';
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
  final OrgContext _orgContext; // FIX: added

  AuthBloc({
    required LoginUseCase login,
    required RegisterUseCase register,
    required LogoutUseCase logout,
    required LogoutAccountUseCase logoutAccount,
    required SwitchAccountUseCase switchAccount,
    required GetActiveSessionUseCase getActiveSession,
    required GetSavedAccountsUseCase getSavedAccounts,
    required RefreshSessionUseCase refreshSession,
    required OrgContext orgContext, // FIX: added
  }) : _login = login,
       _register = register,
       _logout = logout,
       _logoutAccount = logoutAccount,
       _switchAccount = switchAccount,
       _getActiveSession = getActiveSession,
       _getSavedAccounts = getSavedAccounts,
       _refreshSession = refreshSession,
       _orgContext = orgContext, // FIX: added
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

  // ── FIX: populate OrgContext after every successful auth ──
  //
  // Barick Pharmacy is single-org: AppConstants.orgId is the root.
  // Role is derived from the session's primaryRole slug:
  //   'org_admin' / 'admin' → OrgRole.orgAdmin
  //   'branch_admin'        → OrgRole.branchAdmin
  //   anything else         → OrgRole.orgAdmin (admin app default)
  Future<void> _applyOrgContext(AccountSession session) async {
    final slug = session.user.primaryRole?.slug.toLowerCase() ?? '';

    final role = slug == 'branch_manager'
        ? OrgRole.branchAdmin
        : slug.contains('officer') || slug == 'junior_officer'
        ? OrgRole.fieldOfficer
        : OrgRole.orgAdmin; // owner, admin, super → orgAdmin

    await _orgContext.setRootOrg(
      id: AppConstants.orgId,
      name: 'Barick Pharmacy',
      role: role,
      actorId: session.user.actorId,
      actorName: session.user.name,
    );
  }

  // ── Helper ────────────────────────────────────────────────
  List<AccountSession> _ensureActiveIncluded(
    AccountSession active,
    List<AccountSession> accounts,
  ) {
    if (accounts.any((a) => a.user.email == active.user.email)) {
      return accounts;
    }
    return [active, ...accounts];
  }

  // ── Startup check ─────────────────────────────────────────
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // FIX: restore persisted org context so returning users don't
    // need to re-login for OrgContext to be populated.
    await _orgContext.restore();

    final sessionResult = await _getActiveSession(NoParams());

    await sessionResult.fold((_) async => emit(AuthUnauthenticated()), (
      session,
    ) async {
      if (session == null) {
        final accountsResult = await _getSavedAccounts(NoParams());
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

      // FIX: session exists but org context may not have been
      // restored yet (first cold start after login on a new device).
      if (!_orgContext.hasOrg) {
        await _applyOrgContext(session);
      }

      final accountsResult = await _getSavedAccounts(NoParams());
      final raw = accountsResult.fold<List<AccountSession>>(
        (_) => <AccountSession>[],
        (List<AccountSession> a) => a,
      );
      emit(
        AuthAuthenticated(
          activeSession: session,
          savedAccounts: _ensureActiveIncluded(session, raw),
        ),
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
        await _applyOrgContext(session); // FIX

        final accountsResult = await _getSavedAccounts(NoParams());
        final raw = accountsResult.fold<List<AccountSession>>(
          (_) => <AccountSession>[],
          (List<AccountSession> a) => a,
        );
        emit(
          AuthAuthenticated(
            activeSession: session,
            savedAccounts: _ensureActiveIncluded(session, raw),
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
        await _applyOrgContext(session); // FIX

        final accountsResult = await _getSavedAccounts(NoParams());
        final raw = accountsResult.fold<List<AccountSession>>(
          (_) => <AccountSession>[],
          (List<AccountSession> a) => a,
        );
        emit(
          AuthAuthenticated(
            activeSession: session,
            savedAccounts: _ensureActiveIncluded(session, raw),
          ),
        );
      },
    );
  }

  // ── Logout active account ─────────────────────────────────
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _logout(NoParams());

    await result.fold(
      (failure) async => emit(AuthFailureState(failure.message)),
      (_) async {
        await _orgContext.clear(); // FIX

        final accountsResult = await _getSavedAccounts(NoParams());
        final remaining = accountsResult.fold<List<AccountSession>>(
          (_) => <AccountSession>[],
          (List<AccountSession> a) => a,
        );

        if (remaining.isEmpty) {
          emit(AuthUnauthenticated());
        } else {
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
          await _orgContext.clear(); // FIX
          emit(AuthUnauthenticated());
          return;
        }

        final sessionResult = await _getActiveSession(NoParams());
        sessionResult.fold(
          (_) => emit(AuthNeedsAccountPicker(savedAccounts: remaining)),
          (session) {
            if (session == null) {
              emit(AuthNeedsAccountPicker(savedAccounts: remaining));
            } else {
              emit(
                AuthAccountsUpdated(
                  activeSession: session,
                  savedAccounts: _ensureActiveIncluded(session, remaining),
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
        await _applyOrgContext(newSession); // FIX

        final accountsResult = await _getSavedAccounts(NoParams());
        final raw = accountsResult.fold<List<AccountSession>>(
          (_) => <AccountSession>[],
          (List<AccountSession> a) => a,
        );
        emit(
          AuthAuthenticated(
            activeSession: newSession,
            savedAccounts: _ensureActiveIncluded(newSession, raw),
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

      final raw = accountsResult.fold<List<AccountSession>>(
        (_) => <AccountSession>[],
        (List<AccountSession> a) => a,
      );
      emit(
        AuthAccountsUpdated(
          activeSession: session,
          savedAccounts: _ensureActiveIncluded(session, raw),
        ),
      );
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
        await _applyOrgContext(session); // FIX

        final accountsResult = await _getSavedAccounts(NoParams());
        final raw = accountsResult.fold<List<AccountSession>>(
          (_) => <AccountSession>[],
          (List<AccountSession> a) => a,
        );
        emit(
          AuthAuthenticated(
            activeSession: session,
            savedAccounts: _ensureActiveIncluded(session, raw),
          ),
        );
      },
    );
  }
}
