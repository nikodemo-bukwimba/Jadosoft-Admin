// shell_page_home_tab.dart
// The Home tab placeholder widget.
//
// Extracted from the private _HomeTab class that lived inside shell_page.dart.
// This is a placeholder. Replace it with your actual home feature widget
// when you have one — or generate a proper Level 0 / Level 4 feature for it.
//
// When to replace this:
//   Option A: Generate a Level 4 aggregator feature named "home" or "overview"
//             and swap the HomeTab() reference in shell_nav_items.dart.
//   Option B: Build a custom home page directly here.
//
// This file is human territory — the generator never touches it.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../routes/app_router.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox.shrink();
        final user = state.activeSession.user;

        return Scaffold(
          appBar: AppBar(title: const Text('Home')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      _initials(user.displayName),
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome, ${user.name.split(' ').first}',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (user.primaryRole != null) ...[
                    const SizedBox(height: 12),
                    Chip(
                      label: Text(user.primaryRole!.name),
                      backgroundColor: scheme.secondaryContainer,
                    ),
                  ],
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Add another account'),
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRouter.accountPicker,
                      arguments: {'mode': 'add'},
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error.withOpacity(0.5)),
                    ),
                    onPressed: () =>
                        context.read<AuthBloc>().add(AuthLogoutRequested()),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Replace this with your home feature.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
