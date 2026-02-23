// shell_page.dart
// ─────────────────────────────────────────────────────────────
// BlocConsumer listener updated to handle AuthNeedsAccountPicker.
// "Add account" buttons now navigate to /account-picker?mode=add.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/injection_container.dart';
import '../../../../config/routes/app_router.dart';
import '../../../../core/rbac/rbac_extensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/pages/profile_page.dart';

// ── Home tab placeholder ──────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final scheme    = Theme.of(context).colorScheme;
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
                    radius:          48,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      _initials(user.displayName),
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color:      scheme.onPrimaryContainer,
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
                      label:           Text(user.primaryRole!.name),
                      backgroundColor: scheme.secondaryContainer,
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Add account — goes to picker in add mode
                  OutlinedButton.icon(
                    icon:  const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Add another account'),
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRouter.accountPicker,
                      arguments: {'mode': 'add'},
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon:  const Icon(Icons.logout, size: 18),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error.withOpacity(0.5)),
                    ),
                    onPressed: () => context
                        .read<AuthBloc>()
                        .add(AuthLogoutRequested()),
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
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ── Shell ─────────────────────────────────────────────────────
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRouter.login);
        }
        // Logout with remaining accounts → picker
        if (state is AuthNeedsAccountPicker) {
          Navigator.of(context)
              .pushReplacementNamed(AppRouter.accountPicker);
        }
      },
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAdmin  = state.canViewDashboard;
        final tabs     = _buildTabs(isAdmin);
        final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

        return Scaffold(
          body: IndexedStack(
            index:    safeIndex,
            children: tabs.map((t) => t.page).toList(),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
              final profileTabIndex = isAdmin ? 2 : 1;
              if (index == profileTabIndex) {
                context.read<ProfileBloc>().add(ProfileLoadRequested());
              }
            },
            destinations: tabs
                .map((t) => NavigationDestination(
                      icon:         Icon(t.icon),
                      selectedIcon: Icon(t.activeIcon),
                      label:        t.label,
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  List<_TabItem> _buildTabs(bool isAdmin) {
    final tabs = [
      const _TabItem(
        label:      'Home',
        icon:       Icons.home_outlined,
        activeIcon: Icons.home,
        page:       _HomeTab(),
      ),
    ];

    if (isAdmin) {
      tabs.add(_TabItem(
        label:      'Dashboard',
        icon:       Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        page:       BlocProvider(
          create: (_) => sl<ProfileBloc>(),
          child:  const DashboardPage(),
        ),
      ));
    }

    tabs.add(_TabItem(
      label:      'Profile',
      icon:       Icons.person_outline,
      activeIcon: Icons.person,
      page: BlocProvider(
        create: (_) => sl<ProfileBloc>()..add(ProfileLoadRequested()),
        child:  const ProfilePage(),
      ),
    ));

    return tabs;
  }
}

class _TabItem {
  final String   label;
  final IconData icon;
  final IconData activeIcon;
  final Widget   page;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
  });
}
