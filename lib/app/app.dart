// app.dart
// ─────────────────────────────────────────────────────────────
// Root application widget.
//
// Responsibilities:
//   - Own the AuthBloc and GoRouter lifetimes (created once, disposed once)
//   - Provide global BLoCs via MultiBlocProvider
//   - Wire MaterialApp.router to the GoRouter instance
//
// Why StatefulWidget:
//   The GoRouter and AuthBloc must outlive rebuilds and be disposed cleanly.
//   Creating them in build() would recreate on every rebuild — a subtle bug.
//
// MIGRATION NOTE:
//   Previously main.dart contained HMSCPPD (StatelessWidget) with
//   MaterialApp + onGenerateRoute. That approach is replaced here with
//   MaterialApp.router so GoRouter drives all navigation.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../config/di/injection_container.dart';
import '../config/theme/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';
import 'routes/app_router.dart';

class HMSCPPD extends StatefulWidget {
  const HMSCPPD({super.key});

  @override
  State<HMSCPPD> createState() => _HMSCPPDState();
}

class _HMSCPPDState extends State<HMSCPPD> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // ── Boot order matters ──────────────────────────────────
    // 1. Resolve AuthBloc from DI and immediately fire the session check.
    // 2. Pass the bloc to the router so its redirect can read auth state
    //    synchronously (no async gap on first frame).
    _authBloc = sl<AuthBloc>()..add(AuthCheckRequested());
    _router = AppRouter.createRouter(_authBloc);
  }

  @override
  void dispose() {
    // Router disposes its AuthRouterNotifier internally via GoRouter.dispose().
    _router.dispose();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // AuthBloc is provided as .value because we own its lifecycle above.
        BlocProvider<AuthBloc>.value(value: _authBloc),

        // ProfileBloc is stateless between sessions — safe to recreate.
        BlocProvider<ProfileBloc>(create: (_) => sl<ProfileBloc>()),
      ],
      child: MaterialApp.router(
        title: 'The Dashboard',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}
