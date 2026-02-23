// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return switch (state) {
              AuthLoading() => const _SplashScreen(),
              AuthInitial() => const _SplashScreen(),
              AuthAuthenticated() => const _RouteToHome(),
              AuthNeedsAccountPicker() => const _RouteToAccountPicker(),
              _ => const _RouteToLogin(),
            };
          },
        ),
      ),
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

// ── Route redirectors ─────────────────────────────────────────
class _RouteToHome extends StatefulWidget {
  const _RouteToHome();
  @override
  State<_RouteToHome> createState() => _RouteToHomeState();
}

class _RouteToHomeState extends State<_RouteToHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pushReplacementNamed(AppRouter.home);
    });
  }

  @override
  Widget build(BuildContext context) => const _SplashScreen();
}

class _RouteToLogin extends StatefulWidget {
  const _RouteToLogin();
  @override
  State<_RouteToLogin> createState() => _RouteToLoginState();
}

class _RouteToLoginState extends State<_RouteToLogin> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pushReplacementNamed(AppRouter.login);
    });
  }

  @override
  Widget build(BuildContext context) => const _SplashScreen();
}

class _RouteToAccountPicker extends StatefulWidget {
  const _RouteToAccountPicker();
  @override
  State<_RouteToAccountPicker> createState() => _RouteToAccountPickerState();
}

class _RouteToAccountPickerState extends State<_RouteToAccountPicker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.accountPicker);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const _SplashScreen();
}
