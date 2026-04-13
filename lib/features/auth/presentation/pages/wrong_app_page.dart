// wrong_app_page.dart
// Shown when a user logs into the wrong app for their role.
// Admin logging into officer app, or officer logging into admin app.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class WrongAppPage extends StatelessWidget {
  /// true  → officer/unknown role tried to open the ADMIN app
  /// false → admin role tried to open the OFFICER app
  final bool officerInAdminApp;

  const WrongAppPage({super.key, required this.officerInAdminApp});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.no_accounts_outlined,
                      size: 40,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Access Denied',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    officerInAdminApp
                        ? 'Your account does not have admin access.\n\n'
                          'Please use the Officer App to continue.'
                        : 'Admin accounts cannot log into the Officer App.\n\n'
                          'Please use the Admin App to continue.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  FilledButton.icon(
                    onPressed: () =>
                        context.read<AuthBloc>().add(AuthLogoutRequested()),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}