// app_router.dart
// App navigation — the single source of truth for all named routes.
//
// Uses Flutter's Navigator with MaterialPageRoute (not GoRouter).
// All route name constants live here. All route → widget mappings live here.
//
// Moved from: config/routes/app_router.dart
// New location: app/routes/app_router.dart
//
// Import path changes:
//   Old shell import: '../shell/features/shell/shell_page.dart'
//   New shell import: '../shell/shell_page.dart'   ← shell is no longer a feature
//
// Adding a new feature route:
//   1. Add a static const String for the route path.
//   2. Add a case in generateRoute() returning the feature's page.
//   3. If the feature needs a shell tab, also update shell_nav_items.dart.
//
// Generator appends new route constants and cases between the boundary markers.

// ── GENERATOR FEATURE PAGE IMPORTS — append only ─────────────────────────────
// ── END GENERATOR FEATURE PAGE IMPORTS ───────────────────────────────────────
import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/account_picker_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../shell/shell_page.dart';

// ── GENERATOR FEATURE PAGE IMPORTS — append only ─────────────────────────────
// ── END GENERATOR FEATURE PAGE IMPORTS ───────────────────────────────────────

class AppRouter {
  // ── Route path constants ──────────────────────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String accountPicker = '/account-picker';

  // ── GENERATOR ROUTE CONSTANTS — append only ───────────────────────────────────
  // ── END GENERATOR ROUTE CONSTANTS ────────────────────────────────────────────

  // ── Route factory ─────────────────────────────────────────────────────────
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        final args = settings.arguments as Map<String, dynamic>?;
        final addAccount = args?['addAccount'] as bool? ?? false;
        return MaterialPageRoute(
          builder: (_) => LoginPage(addAccount: addAccount),
          settings: settings,
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
          settings: settings,
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const ShellPage(),
          settings: settings,
        );

      case accountPicker:
        final args = settings.arguments as Map<String, dynamic>?;
        final mode = args?['mode'] == 'add'
            ? AccountPickerMode.add
            : AccountPickerMode.picker;
        return MaterialPageRoute(
          builder: (_) => AccountPickerPage(mode: mode),
          settings: settings,
        );

      // ── GENERATOR ROUTES — append only ─────────────────────────

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route "${settings.name}" not found')),
          ),
        );
    }
  }
}
 