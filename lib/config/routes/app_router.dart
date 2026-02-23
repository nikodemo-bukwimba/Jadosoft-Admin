// app_router.dart
import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/account_picker_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/shell/presentation/pages/shell_page.dart';

class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String accountPicker = '/account-picker';

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

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route "${settings.name}" not found')),
          ),
        );
    }
  }
}
