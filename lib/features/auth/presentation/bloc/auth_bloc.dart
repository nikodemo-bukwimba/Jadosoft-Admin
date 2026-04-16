// auth_bloc.dart
// ─────────────────────────────────────────────────────────────
// FIX: _applyOrgContext() no longer uses AppConstants.orgId.
// Instead it reads the org_id already stored in OrgContext by
// AuthRepositoryImpl after the /auth/me call. This means branch
// members and officers get the correct org scope automatically.
//
// The role derivation from slug covers all org roles in use:
//   owner, org_admin, manager, staff, viewer → orgAdmin
//   branch_manager                           → branchAdmin
//   officer, field_*, pharma_rep, sales_rep  → fieldOfficer
// ─────────────────────────────────────────────────────────────

import 'package:flutter_bloc/flutter_bloc.dart';
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
  final OrgContext _orgContext;

  AuthBloc({
    required LoginUseCase login,
    required RegisterUseCase register,
    required LogoutUseCase logout,
    required LogoutAccountUseCase logoutAccount,
    required SwitchAccountUseCase switchAccount,
    required GetActiveSessionUseCase getActiveSession,
    required GetSavedAccountsUseCase getSavedAccounts,
    required RefreshSessionUseCase refreshSession,
    required OrgContext orgContext,
  }) : _login = login,
       _register = register,
       _logout = logout,
       _logoutAccount = logoutAccount,
       _switchAccount = switchAccount,
       _getActiveSession = getActiveSession,
       _getSavedAccounts = getSavedAccounts,
       _refreshSession = refreshSession,
       _orgContext = orgContext,
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

  // ── OrgContext helper ─────────────────────────────────────
  // The repository already called setRootOrg() with the resolved
  // org_id after /auth/me. Here we only update the role + actor
  // fields that come from the session, leaving org_id untouched.
  Future<void> _applyOrgContext(AccountSession session) async {
    final slug = session.user.primaryRole?.slug.toLowerCase() ?? '';

    final role = slug == 'branch_manager'
        ? OrgRole.branchAdmin
        : (slug.contains('officer') ||
               slug.contains('field') ||
               slug.contains('pharma_rep') ||
               slug.contains('sales_rep') ||
               slug == 'junior_officer')
            ? OrgRole.fieldOfficer
            : OrgRole.orgAdmin; // owner, org_admin, manager, staff, viewer

    // OrgContext already has the correct org_id from the repository.
    // Restore it to ensure in-memory state matches storage.
    await _orgContext.restore();

    // Only update if the context has an org_id (set by repository).
    // If it doesn't (brand new user, no membership), leave as-is —
    // the router will send them to /pending-activation.
    if (_orgContext.hasOrg) {
      await _orgContext.setRootOrg(
        id: _orgContext.rootOrgId!,
        name: _orgContext.rootOrgName ?? 'Barick Pharmacy',
        role: role,
        actorId: session.user.actorId,
        actorName: session.user.name.isNotEmpty
            ? session.user.name
            : session.user.email,
      );
    }
  }

  List<AccountSession> _ensureActiveIncluded(
    AccountSession active,
    List<AccountSession> accounts,
  ) {
    if (accounts.any((a) => a.user.email == active.user.email)) return accounts;
    return [active, ...accounts];
  }

  // ── Startup check ─────────────────────────────────────────
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _orgContext.restore();

    final sessionResult = await _getActiveSession(NoParams());

    await sessionResult.fold((_) async => emit(AuthUnauthenticated()), (
      session,
    ) async {
      if (session == null) {
        final accountsResult = await _getSavedAccounts(NoParams());
        final saved = accountsResult.fold<List<AccountSession>>(
          (_) => <AccountSession>[],
          (a) => a,
        );
        if (saved.isNotEmpty) {
          emit(AuthNeedsAccountPicker(savedAccounts: saved));
        } else {
          emit(AuthUnauthenticated());
        }
        return;
      }

      if (!_orgContext.hasOrg) await _applyOrgContext(session);

      final accountsResult = await _getSavedAccounts(NoParams());
      final raw = accountsResult.fold<List<AccountSession>>((_) => [], (a) => a);
      emit(AuthAuthenticated(
        activeSession: session,
        savedAccounts: _ensureActiveIncluded(session, raw),
      ));
    });
  }

  // ── Login ─────────────────────────────────────────────────
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _login(LoginParams(email: event.email, password: event.password));
    await result.fold(
      (failure) async => emit(AuthFailureState(failure.message)),
      (session) async {
        await _applyOrgContext(session);
        final accountsResult = await _getSavedAccounts(NoParams());
        final raw = accountsResult.fold<List<AccountSession>>((_) => [], (a) => a);
        emit(AuthAuthenticated(
          activeSession: session,
          savedAccounts: _ensureActiveIncluded(session, raw),
        ));
      },
    );
  }

  // ── Register ──────────────────────────────────────────────
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _register(RegisterParams(
      name: event.name,
      email: event.email,
      password: event.password,
      passwordConfirmation: event.passwordConfirmation,
      phone: event.phone,
    ));
    await result.fold(
      (failure) async => emit(AuthFailureState(failure.message)),
      (session) async {
        await _applyOrgContext(session);
        final accountsResult = await _getSavedAccounts(NoParams());
        final raw = accountsResult.fold<List<AccountSession>>((_) => [], (a) => a);
        emit(AuthAuthenticated(
          activeSession: session,
          savedAccounts: _ensureActiveIncluded(session, raw),
        ));
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
        await _orgContext.clear();
        final accountsResult = await _getSavedAccounts(NoParams());
        final remaining = accountsResult.fold<List<AccountSession>>((_) => [], (a) => a);
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
        final remaining = accountsResult.fold<List<AccountSession>>((_) => [], (a) => a);
        if (remaining.isEmpty) {
          await _orgContext.clear();
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
              emit(AuthAccountsUpdated(
                activeSession: session,
                savedAccounts: _ensureActiveIncluded(session, remaining),
              ));
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
        sessionResult.fold((_) => emit(AuthFailureState(failure.message)), (session) {
          if (session == null) {
            emit(AuthUnauthenticated());
          } else {
            emit(AuthFailureState(failure.message));
          }
        });
      },
      (newSession) async {
        await _applyOrgContext(newSession);
        final accountsResult = await _getSavedAccounts(NoParams());
        final raw = accountsResult.fold<List<AccountSession>>((_) => [], (a) => a);
        emit(AuthAuthenticated(
          activeSession: newSession,
          savedAccounts: _ensureActiveIncluded(newSession, raw),
        ));
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
        final saved = accountsResult.fold<List<AccountSession>>((_) => [], (a) => a);
        if (saved.isNotEmpty) {
          emit(AuthNeedsAccountPicker(savedAccounts: saved));
        } else {
          emit(AuthUnauthenticated());
        }
        return;
      }
      final raw = accountsResult.fold<List<AccountSession>>((_) => [], (a) => a);
      emit(AuthAccountsUpdated(
        activeSession: session,
        savedAccounts: _ensureActiveIncluded(session, raw),
      ));
    });
  }

  // ── Session refresh ───────────────────────────────────────
  Future<void> _onSessionRefreshRequested(
    AuthSessionRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _refreshSession(NoParams());
    await result.fold(
      (failure) async => emit(AuthFailureState(failure.message)),
      (session) async {
        await _applyOrgContext(session);
        final accountsResult = await _getSavedAccounts(NoParams());
        final raw = accountsResult.fold<List<AccountSession>>((_) => [], (a) => a);
        emit(AuthAuthenticated(
          activeSession: session,
          savedAccounts: _ensureActiveIncluded(session, raw),
        ));
      },
    );
  }
}