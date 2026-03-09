// app_router.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
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
            return LoginPage(addAccount: args?['addAccount'] as bool? ?? false);
          },
        ),

        GoRoute(
          path: register,
          builder: (_, routeState) {
            final args = routeState.extra as Map<String, dynamic>?;
            return RegisterPage(
              addAccount: args?['addAccount'] as bool? ?? false,
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
            return AccountPickerPage(mode: mode);
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

  static String? _redirect(AuthState authState, String location) {
    final isShellRoute = const {home, dashboard, profile}.contains(location);
    final isAuthRoute = const {
      login,
      register,
      accountPicker,
    }.contains(location);

    return switch (authState) {
      // ── Still resolving ──────────────────────────────────────────────────────
      AuthInitial() => location == splash ? null : splash,

      // ── Loading ──────────────────────────────────────────────────────────────
      AuthLoading() => isShellRoute ? splash : null,

      // ── Authenticated ────────────────────────────────────────────────────────
      // Only boot off the initial splash screen → home.
      //
      // /login and /register: intentionally NOT redirected so authenticated
      //   users can reach them for the add-account flow.
      //
      // /account-picker: intentionally NOT redirected so authenticated users
      //   can browse saved accounts and switch. The page's own BlocListener
      //   handles navigation to /home after a successful switch.
      //
      // After login / register success the page calls context.go(home) itself.
      AuthAuthenticated() => location == splash ? home : null,

      // ── Needs picker ─────────────────────────────────────────────────────────
      AuthNeedsAccountPicker() =>
        location == accountPicker ? null : accountPicker,

      // ── Unauthenticated ──────────────────────────────────────────────────────
      AuthUnauthenticated() =>
        isShellRoute || location == splash ? login : null,

      // ── Switching ────────────────────────────────────────────────────────────
      AuthSwitching() => null,

      // ── Failure ──────────────────────────────────────────────────────────────
      AuthFailureState() => isShellRoute ? login : null,

      // ── Accounts updated ─────────────────────────────────────────────────────
      // Treat same as authenticated — page handles its own navigation.
      AuthAccountsUpdated() => location == splash ? home : null,

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
