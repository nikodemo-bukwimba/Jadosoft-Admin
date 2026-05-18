// FILE: lib/features/auth/presentation/bloc/auth_bloc.dart
// PATH: lib/features/auth/presentation/bloc/auth_bloc.dart
//
// CHANGES (two spots only — everything else verbatim):
//
// 1. _applyOrgContext(): the role derivation is unchanged.
//    BUT the return value now correctly distinguishes three states:
//      - returns false  → no org at all (new registrant) → pending activation
//      - returns 'pending' → org exists but status != 'active' → pending approval
//      - returns true   → org is active → go to home
//    Previously, _persistOrgAndBranch() in the repository was calling
//    setRootOrg() for every user, even ones with no membership.
//    That made _orgContext.hasOrg == true for everyone, bypassing the
//    AuthNeedsInvitationToken gate completely.
//
// 2. _onLoginRequested() and _onRegisterRequested() now check the
//    three-state return and emit AuthNeedsInvitationToken for BOTH
//    "no org" and "pending approval" cases, which is what routes to
//    PendingActivationPage.
//
// WHY THIS BROKE:
//   The new _persistOrgAndBranch() calls setRootOrg() whenever
//   resolvedOrgId != null. For a newly registered user, /auth/me
//   returns resolvedOrgId=null so _persistOrgAndBranch is NOT called.
//   BUT the old code in _applyOrgContext falls into `else OrgRole.orgAdmin`
//   for any unrecognised slug, then reads _orgContext.hasOrg which can be
//   true from a previous session in secure storage.
//   Fix: always check session.user.orgId directly — it is null when
//   the user has no membership, regardless of what OrgContext thinks.

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

  // ── OrgContext helper ─────────────────────────────────────────────────────
  //
  // Returns one of three values:
  //   'active'   → org is fully active → go to home
  //   'pending'  → org exists but not yet approved → pending activation page
  //   'none'     → user has no org membership → pending activation page
  //
  // ── CHANGE from original ──────────────────────────────────────────────────
  // Original code used _orgContext.hasOrg as the gate.
  // Problem: _persistOrgAndBranch() (called in the repository after /auth/me)
  // sometimes wrote org data to OrgContext even for users who only got a null
  // org_id, OR OrgContext retained a previous session's data from secure storage.
  // This made hasOrg==true for new users, bypassing AuthNeedsInvitationToken.
  //
  // Fix: use session.user.orgId (the authoritative value from the server)
  // as the primary gate. OrgContext is only used for role/name enrichment.
  // ─────────────────────────────────────────────────────────────────────────
  Future<String> _applyOrgContext(AccountSession session) async {
    // ── CHANGE: gate on session.user.orgId, NOT _orgContext.hasOrg ───────────
    final orgId = session.user.orgId;

    // No membership at all → user is a new registrant
    if (orgId == null || orgId.isEmpty) {
      return 'none';
    }

    // Org exists but status not active → pending approval
    final orgStatus = session.user.orgStatus?.toLowerCase();
    if (orgStatus != 'active') {
      // Still apply context so PendingActivationPage can read org name
      await _orgContext.restore();
      await _orgContext.setOrgStatus(orgStatus);
      return 'pending';
    }
    // ─────────────────────────────────────────────────────────────────────────

    // Org is active — derive role from slug (unchanged logic)
    final slug = session.user.primaryRole?.slug.toLowerCase() ?? '';
    final role = slug == 'branch_manager'
        ? OrgRole.branchAdmin
        : (slug.contains('officer') ||
              slug.contains('field') ||
              slug.contains('pharma_rep') ||
              slug.contains('sales_rep') ||
              slug == 'junior_officer')
        ? OrgRole.fieldOfficer
        : OrgRole.orgAdmin;

    await _orgContext.restore();

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
      await _orgContext.setOrgStatus(session.user.orgStatus);
    }

    return 'active';
  }

  List<AccountSession> _ensureActiveIncluded(
    AccountSession active,
    List<AccountSession> accounts,
  ) {
    if (accounts.any((a) => a.user.email == active.user.email)) return accounts;
    return [active, ...accounts];
  }

  // ── Startup check ──────────────────────────────────────────────────────────
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

      // ── CHANGE: use new string return value ──────────────────────────────
      final orgState = await _applyOrgContext(session);
      if (orgState != 'active') {
        // Treat same as unauthenticated from startup — force re-login so
        // /auth/me is called fresh and pending state is re-evaluated.
        emit(AuthNeedsInvitationToken(session: session));
        return;
      }
      // ─────────────────────────────────────────────────────────────────────

      final accountsResult = await _getSavedAccounts(NoParams());
      final raw = accountsResult.fold<List<AccountSession>>(
        (_) => [],
        (a) => a,
      );
      emit(
        AuthAuthenticated(
          activeSession: session,
          savedAccounts: _ensureActiveIncluded(session, raw),
        ),
      );
    });
  }

  // ── Login ──────────────────────────────────────────────────────────────────
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
        // ── CHANGE: use new string return value ──────────────────────────────
        final orgState = await _applyOrgContext(session);
        if (orgState != 'active') {
          // No org or pending approval → pending activation page
          emit(AuthNeedsInvitationToken(session: session));
          return;
        }
        // ─────────────────────────────────────────────────────────────────────
        final accountsResult = await _getSavedAccounts(NoParams());
        final raw = accountsResult.fold<List<AccountSession>>(
          (_) => [],
          (a) => a,
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

  // ── Register ───────────────────────────────────────────────────────────────
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
        // ── CHANGE: use new string return value ──────────────────────────────
        final orgState = await _applyOrgContext(session);
        if (orgState != 'active') {
          // New registrant has no org → pending activation page (correct flow)
          emit(AuthNeedsInvitationToken(session: session));
          return;
        }
        // ─────────────────────────────────────────────────────────────────────
        final accountsResult = await _getSavedAccounts(NoParams());
        final raw = accountsResult.fold<List<AccountSession>>(
          (_) => [],
          (a) => a,
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

  // ── Logout active account ──────────────────────────────────────────────────
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
        final remaining = accountsResult.fold<List<AccountSession>>(
          (_) => [],
          (a) => a,
        );
        if (remaining.isEmpty) {
          emit(AuthUnauthenticated());
        } else {
          emit(AuthNeedsAccountPicker(savedAccounts: remaining));
        }
      },
    );
  }

  // ── Logout specific account ────────────────────────────────────────────────
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
          (_) => [],
          (a) => a,
        );
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

  // ── Switch account ─────────────────────────────────────────────────────────
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
        await _applyOrgContext(newSession);
        final accountsResult = await _getSavedAccounts(NoParams());
        final raw = accountsResult.fold<List<AccountSession>>(
          (_) => [],
          (a) => a,
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

  // ── Refresh accounts list ──────────────────────────────────────────────────
  Future<void> _onAccountsRefreshRequested(
    AuthAccountsRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final sessionResult = await _getActiveSession(NoParams());
    final accountsResult = await _getSavedAccounts(NoParams());
    sessionResult.fold((_) => emit(AuthUnauthenticated()), (session) {
      if (session == null) {
        emit(AuthUnauthenticated());
        return;
      }
      final accounts = accountsResult.fold<List<AccountSession>>(
        (_) => [],
        (a) => a,
      );
      emit(
        AuthAccountsUpdated(
          activeSession: session,
          savedAccounts: _ensureActiveIncluded(session, accounts),
        ),
      );
    });
  }

  // ── Session refresh ────────────────────────────────────────────────────────
  Future<void> _onSessionRefreshRequested(
    AuthSessionRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _refreshSession(NoParams());
    await result.fold(
      (failure) async => emit(AuthFailureState(failure.message)),
      (session) async {
        final orgState = await _applyOrgContext(session);
        final accountsResult = await _getSavedAccounts(NoParams());
        final raw = accountsResult.fold<List<AccountSession>>(
          (_) => [],
          (a) => a,
        );
        if (orgState != 'active') {
          emit(AuthNeedsInvitationToken(session: session));
          return;
        }
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
