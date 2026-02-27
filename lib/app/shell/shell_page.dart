// shell_page.dart
// Navigation shell — the authenticated app scaffold.
//
// Responsibilities (and only these):
//   - Read AuthState to determine which tabs are visible
//   - Render IndexedStack for tab state preservation
//   - Render NavigationBar for tab switching
//   - React to auth state changes (logout → login, logout with accounts → picker)
//
// What does NOT belong here:
//   - Which tabs exist → see shell_nav_items.dart
//   - Tab page content → see shell_nav_items.dart + each feature
//   - The home placeholder → see shell_page_home_tab.dart
//   - Permission logic → see core/rbac/rbac_extensions.dart
//
// Moved from: features/shell/presentation/pages/shell_page.dart
// New location: app/shell/shell_page.dart
// Import path changes: ../../../../ → ../../

import 'package:fca/app/routes/app_router.dart';
import 'package:fca/core/rbac/rbac_extensions.dart';
import 'package:fca/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:fca/features/profile/presentation/bloc/profile_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

import 'shell_nav_items.dart';
import 'shell_tab_config.dart';

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
        // Full logout — no remaining accounts
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRouter.login);
        }
        // Logout with remaining accounts → show account picker
        if (state is AuthNeedsAccountPicker) {
          Navigator.of(context).pushReplacementNamed(AppRouter.accountPicker);
        }
      },
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final tabs = ShellNavItems.buildTabs(isAdmin: state.canViewDashboard);
        final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

        return Scaffold(
          body: IndexedStack(
            index: safeIndex,
            children: tabs.map((t) => t.page).toList(),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (index) => _onTabSelected(
              context,
              index: index,
              tabs: tabs,
              isAdmin: state.canViewDashboard,
            ),
            destinations: tabs
                .map(
                  (t) => NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.activeIcon),
                    label: t.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  void _onTabSelected(
    BuildContext context, {
    required int index,
    required List<ShellTabConfig> tabs,
    required bool isAdmin,
  }) {
    setState(() => _currentIndex = index);

    // Trigger profile load when the profile tab is tapped.
    // The profile tab is always the last tab in the list.
    final isProfileTab = index == tabs.length - 1;
    if (isProfileTab) {
      context.read<ProfileBloc>().add(ProfileLoadRequested());
    }
  }
}
