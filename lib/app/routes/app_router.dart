// app_router.dart
// ─────────────────────────────────────────────────────────────
// Single source of truth for all app navigation.
//
// MIGRATION: Replaced plain Navigator + onGenerateRoute with GoRouter.
// Reason: AdaptiveNavShell (customnav/) requires GoRouter — having two
// navigation systems in one app caused split state and back-stack bugs.
//
// Architecture:
//   ┌─────────────────────────────────────────────────────────┐
//   │  / (splash)      — shown while AuthBloc resolves        │
//   │  /login          ─┐                                     │
//   │  /register        ├─ Auth routes  (outside shell)       │
//   │  /account-picker ─┘                                     │
//   │  ShellRoute ──────────────────────────────────────────  │
//   │    /home          ─┐                                     │
//   │    /dashboard      ├─ Authenticated routes (inside shell)│
//   │    /profile       ─┘                                     │
//   └─────────────────────────────────────────────────────────┘
//
// Redirect is driven by AuthBloc state — no BlocListener needed
// inside individual pages for session changes.
//
// Adding a new feature route:
//   1. Add a static const String path constant below.
//   2. Add a GoRoute inside the ShellRoute routes list.
//   3. Add a NavItem in shell_nav_items.dart.
//   4. Add a feature import above.
//
// Generator appends between the boundary markers automatically.
// ─────────────────────────────────────────────────────────────

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
  // ── Route path constants ──────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String accountPicker = '/account-picker';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';

  // ── GENERATOR ROUTE CONSTANTS — append only ──────────────
  // ── END GENERATOR ROUTE CONSTANTS ────────────────────────

  // ── Router factory ────────────────────────────────────────
  /// Creates and returns the [GoRouter] instance.
  /// Call once from [FcaApp] and store it — do not recreate on rebuild.
  static GoRouter createRouter(AuthBloc authBloc) {
    final notifier = AuthRouterNotifier(authBloc);

    return GoRouter(
      initialLocation: splash,
      refreshListenable: notifier,
      redirect: (context, state) =>
          _redirect(authBloc.state, state.matchedLocation),
      routes: [
        // ── Splash ──────────────────────────────────────────
        GoRoute(path: splash, builder: (_, __) => const _SplashScreen()),

        // ── Auth routes (no shell) ───────────────────────────
        GoRoute(
          path: login,
          builder: (_, routeState) {
            final args = routeState.extra as Map<String, dynamic>?;
            return LoginPage(addAccount: args?['addAccount'] as bool? ?? false);
          },
        ),

        GoRoute(path: register, builder: (_, __) => const RegisterPage()),

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

        // ── Authenticated shell (AdaptiveNavShell) ───────────
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

      // ── 404 fallback ──────────────────────────────────────
      errorBuilder: (context, state) =>
          Scaffold(body: Center(child: Text('Route "${state.uri}" not found'))),
    );
  }

  // ── Redirect logic ────────────────────────────────────────
  // Pure function — easy to test independently.
  // Returns a path to redirect to, or null to allow the navigation.
  static String? _redirect(AuthState authState, String location) {
    final isAuthRoute = const {
      login,
      register,
      accountPicker,
    }.contains(location);

    final isShellRoute =
        location == home ||
        location == dashboard ||
        location == profile ||
        // Catch any generator-added shell routes
        (!isAuthRoute && location != splash);

    return switch (authState) {
      // Still resolving — hold on splash
      AuthInitial() => location == splash ? null : splash,
      AuthLoading() => location == splash ? null : splash,

      // Authenticated — push away from auth / splash to shell
      AuthAuthenticated() => isAuthRoute || location == splash ? home : null,

      // Needs picker — redirect anywhere except the picker itself
      AuthNeedsAccountPicker() =>
        location == accountPicker ? null : accountPicker,

      // Unauthenticated — redirect shell routes to login
      AuthUnauthenticated() =>
        isShellRoute || location == splash ? login : null,

      // Catch-all
      _ => isShellRoute ? login : null,
    };
  }
}

// ── AuthRouterNotifier ────────────────────────────────────────
// Wraps AuthBloc's stream as a ChangeNotifier so GoRouter's
// refreshListenable re-evaluates redirect on every auth change.
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
// Shown while AuthBloc resolves the initial session from storage.
// GoRouter redirect replaces it automatically once auth state resolves.
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
            // ── Brand mark ────────────────────────────────
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

            // ── App name ──────────────────────────────────
            Text(
              'FCA',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),

            // ── Spinner ───────────────────────────────────
            CircularProgressIndicator(color: scheme.primary, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}
