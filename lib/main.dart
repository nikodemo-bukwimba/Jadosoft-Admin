// main.dart
// ─────────────────────────────────────────────────────────────
// Fix: The root BlocBuilder was reacting to EVERY AuthState change,
// pushing new routes on top of whatever the current page had already
// navigated to — causing duplicate pushes and back button appearing.
//
// Solution: Use a one-shot initialisation approach.
// The MaterialApp's `home` is a StatefulWidget (_AppGate) that
// reads the FIRST non-loading state from AuthBloc and navigates
// once, then never interferes again. All subsequent navigation is
// owned by individual page listeners.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config/di/injection_container.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  //await FlutterSecureStorage().deleteAll();
  runApp(const FcaApp());
}

class FcaApp extends StatelessWidget {
  const FcaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider<ProfileBloc>(create: (_) => sl<ProfileBloc>()),
      ],
      child: MaterialApp(
        title: 'FCA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        onGenerateRoute: AppRouter.generateRoute,
        // _AppGate navigates ONCE based on the first resolved auth state.
        // After that it never touches navigation again.
        home: const _AppGate(),
      ),
    );
  }
}

// ── App Gate ──────────────────────────────────────────────────
// Listens to AuthBloc exactly once to determine the initial route.
// Uses BlocListener (not BlocBuilder) so it never rebuilds the
// widget tree — it only triggers a one-time navigation.
class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // Only react to the FIRST state that is not loading/initial.
      // After navigation the listener stays alive but
      // pushNamedAndRemoveUntil inside each page handles everything.
      listenWhen: (previous, current) =>
          current is! AuthInitial && current is! AuthLoading,
      listener: (context, state) {
        final route = switch (state) {
          AuthAuthenticated() => AppRouter.home,
          AuthNeedsAccountPicker() => AppRouter.accountPicker,
          _ => AppRouter.login,
        };

        // Replace the splash with the resolved route.
        // Remove ALL routes so nothing sits under it.
        Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
      },
      // Show splash while the bloc is resolving the initial state.
      child: const _SplashScreen(),
    );
  }
}

// ── Splash ────────────────────────────────────────────────────
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
