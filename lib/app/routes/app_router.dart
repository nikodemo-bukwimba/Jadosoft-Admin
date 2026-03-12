// app_router.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/form_mode.dart';
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

// â”€â”€ GENERATOR FEATURE PAGE IMPORTS â€” append only â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
 
import '../../features/actor/presentation/pages/actor_list_page.dart';
import '../../features/actor/presentation/pages/actor_detail_page.dart';
import '../../features/actor/presentation/pages/actor_form_page.dart';
import '../../features/actor/presentation/bloc/actor_bloc.dart';
import '../../features/actor/presentation/bloc/actor_event.dart';
import '../../config/di/injection_container.dart';
// â”€â”€ END GENERATOR FEATURE PAGE IMPORTS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String accountPicker = '/account-picker';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';

  // â”€â”€ GENERATOR ROUTE CONSTANTS â€” append only â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    static const String actorList   = '/actors';
  static const String actorCreate = '/actors/create';
  static const String actorDetail = '/actors/:id';
  static const String actorEdit   = '/actors/:id/edit';

  /// Helpers for building concrete paths with a known id.
  static String actorDetailPath(String id) => '/actors/$id';
  static String actorEditPath(String id)   => '/actors/$id/edit';
  // â”€â”€ END GENERATOR ROUTE CONSTANTS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
              // No active email â€” user was just logged out
            } else if (authState is AuthAccountsUpdated) {
              initialAccounts = authState.savedAccounts;
              initialActiveEmail = authState.activeSession.user.email;
            }

            // Wrap with BlocProvider.value so the page sees the SAME BLoC
            // instance that the rest of the app uses. GoRouter's route
            // builders receive a context that may not inherit InheritedWidgets
            // from ancestors above the MaterialApp â€” explicit provision is
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
            // â”€â”€ GENERATOR ROUTES â€” append only â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
 
            
            // Actors routes (Level 1, generated 2026-03-10)
            GoRoute(
              path: actorList,
              builder: (_, __) => BlocProvider(
                create: (_) => sl<ActorBloc>()..add(ActorLoadAllRequested()),
                child: const ActorListPage(),
              ),
            ),
            GoRoute(
              path: actorCreate,
              builder: (_, __) => BlocProvider(
                create: (_) => sl<ActorBloc>(),
                child: const ActorFormPage(mode: ActorFormMode.create),
              ),
            ),
            GoRoute(
              path: actorDetail,
              builder: (_, state) {
                final id = state.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) => sl<ActorBloc>()..add(ActorLoadOneRequested(id)),
                  child: const ActorDetailPage(),
                );
              },
            ),
            GoRoute(
              path: actorEdit,
              builder: (_, state) {
                final id = state.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) => sl<ActorBloc>()..add(ActorLoadOneRequested(id)),
                  child: ActorFormPage(mode: ActorFormMode.edit, id: id),
                );
              },
            ),
            // â”€â”€ END GENERATOR ROUTES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
      // â”€â”€ Resolving â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      AuthInitial() => location == splash ? null : splash,
      AuthLoading() => isShellRoute ? splash : null,

      // â”€â”€ Authenticated â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // Only splash â†’ home. /login, /register, /account-picker are intentionally
      // NOT redirected so add-account and manual navigation work.
      AuthAuthenticated() => location == splash ? home : null,
      AuthAccountsUpdated() => location == splash ? home : null,

      // â”€â”€ Needs picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      AuthNeedsAccountPicker() => isAuthRoute ? null : accountPicker,

      // â”€â”€ Unauthenticated â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      AuthUnauthenticated() =>
        isShellRoute || location == splash ? login : null,

      // â”€â”€ Switching / failure â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      AuthSwitching() => null,
      AuthFailureState() => isShellRoute ? login : null,

      // â”€â”€ Catch-all â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      _ => isShellRoute ? login : null,
    };
  }
}

// â”€â”€ AuthRouterNotifier â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Splash screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
              'HMSCPPD',
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






























