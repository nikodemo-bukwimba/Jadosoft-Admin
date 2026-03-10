// app_router.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/domain/entities/account_session.dart';
import '../../features/auth/presentation/pages/account_picker_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../shell/shell_page.dart';
import '../shell/shell_page_home_tab.dart';

// ── GENERATOR FEATURE PAGE IMPORTS — append only ─────────────────────────────

// ── END GENERATOR FEATURE PAGE IMPORTS ───────────────────────────────────────

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String accountPicker = '/account-picker';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';

  // ── GENERATOR ROUTE CONSTANTS — append only ──────────────

  // ── END GENERATOR ROUTE CONSTANTS ────────────────────────

  static GoRouter createRouter(AuthBloc authBloc) {
    final notifier = AuthRouterNotifier(authBloc);

    return GoRouter(
      initialLocation: splash,
      refreshListenable: notifier,
      redirect: (context, state) =>
          _redirect(authBloc.state, state.matchedLocation),
      routes: [
        GoRoute(path: splash, builder: (_, __) => const _SplashScreen()),

        GoRoute(
          path: login,
          builder: (_, routeState) {
            final args = routeState.extra as Map<String, dynamic>?;
            return BlocProvider.value(
              value: authBloc,
              child: LoginPage(
                addAccount: args?['addAccount'] as bool? ?? false,
              ),
            );
          },
        ),

        GoRoute(
          path: register,
          builder: (_, routeState) {
            final args = routeState.extra as Map<String, dynamic>?;
            return BlocProvider.value(
              value: authBloc,
              child: RegisterPage(
                addAccount: args?['addAccount'] as bool? ?? false,
              ),
            );
          },
        ),

        GoRoute(
          path: accountPicker,
          builder: (_, routeState) {
            final args = routeState.extra as Map<String, dynamic>?;
            final mode = args?['mode'] == 'add'
                ? AccountPickerMode.add
                : AccountPickerMode.picker;

            // Read the CURRENT state of the BLoC synchronously at route
            // build time. This is the same authBloc instance that drives
            // the redirect, so it's guaranteed to reflect the state that
            // caused the navigation to this route.
            final authState = authBloc.state;
            List<AccountSession> initialAccounts = [];
            String? initialActiveEmail;

            if (authState is AuthAuthenticated) {
              initialAccounts = authState.savedAccounts;
              initialActiveEmail = authState.activeSession.user.email;
            } else if (authState is AuthNeedsAccountPicker) {
              initialAccounts = authState.savedAccounts;
              // No active email — user was just logged out
            } else if (authState is AuthAccountsUpdated) {
              initialAccounts = authState.savedAccounts;
              initialActiveEmail = authState.activeSession.user.email;
            }

            // Wrap with BlocProvider.value so the page sees the SAME BLoC
            // instance that the rest of the app uses. GoRouter's route
            // builders receive a context that may not inherit InheritedWidgets
            // from ancestors above the MaterialApp — explicit provision is
            // the safe pattern (same as AccountSwitcherSheet.show).
            return BlocProvider.value(
              value: authBloc,
              child: AccountPickerPage(
                mode: mode,
                initialAccounts: initialAccounts,
                initialActiveEmail: initialActiveEmail,
              ),
            );
          },
        ),

        ShellRoute(
          builder: (context, state, child) => ShellPage(child: child),
          routes: [
            GoRoute(path: home, builder: (_, __) => const HomeTab()),
            GoRoute(path: dashboard, builder: (_, __) => const DashboardPage()),
            GoRoute(path: profile, builder: (_, __) => const ProfilePage()),
            // ── GENERATOR ROUTES — append only ───────────────



            // ── END GENERATOR ROUTES ─────────────────────────
          ],
        ),
      ],

      errorBuilder: (context, state) =>
          Scaffold(body: Center(child: Text('Route "${state.uri}" not found'))),
    );
  }

  static const _authRoutes = {login, register, accountPicker};
  static String? _redirect(AuthState authState, String location) {
    final isAuthRoute = _authRoutes.contains(location);
    final isShellRoute = !isAuthRoute && location != splash;

    return switch (authState) {
      // ── Resolving ────────────────────────────────────────────────────────────
      AuthInitial() => location == splash ? null : splash,
      AuthLoading() => isShellRoute ? splash : null,

      // ── Authenticated ────────────────────────────────────────────────────────
      // Only splash → home. /login, /register, /account-picker are intentionally
      // NOT redirected so add-account and manual navigation work.
      AuthAuthenticated() => location == splash ? home : null,
      AuthAccountsUpdated() => location == splash ? home : null,

      // ── Needs picker ─────────────────────────────────────────────────────────
      AuthNeedsAccountPicker() => isAuthRoute ? null : accountPicker,

      // ── Unauthenticated ──────────────────────────────────────────────────────
      AuthUnauthenticated() =>
        isShellRoute || location == splash ? login : null,

      // ── Switching / failure ──────────────────────────────────────────────────
      AuthSwitching() => null,
      AuthFailureState() => isShellRoute ? login : null,

      // ── Catch-all ────────────────────────────────────────────────────────────
      _ => isShellRoute ? login : null,
    };
  }
}

// ── AuthRouterNotifier ────────────────────────────────────────
class AuthRouterNotifier extends ChangeNotifier {
  AuthRouterNotifier(AuthBloc authBloc) {
    _subscription = authBloc.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ── Splash screen ─────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 36,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'FCA',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: scheme.primary, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}


