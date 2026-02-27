// profile_page.dart
// Updates: BlocListener handles AuthNeedsAccountPicker state.
//          "Add another account" now navigates to /account-picker.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../core/rbac/permission_guard.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/widgets/account_switcher_sheet.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../domain/entities/profile_entity.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(ProfileLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Listen for auth state changes at the page level
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRouter.login);
        }
        if (state is AuthNeedsAccountPicker) {
          Navigator.of(context).pushReplacementNamed(AppRouter.accountPicker);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: 'Refresh',
              onPressed: () =>
                  context.read<ProfileBloc>().add(ProfileLoadRequested()),
            ),
          ],
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProfileError) {
              return _ErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<ProfileBloc>().add(ProfileLoadRequested()),
                scheme: scheme,
                textTheme: textTheme,
              );
            }

            if (state is ProfileLoaded) {
              return _ProfileContent(profile: state.profile);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ── Main content ──────────────────────────────────────────────
class _ProfileContent extends StatelessWidget {
  final ProfileEntity profile;
  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = profile.user;
    final permGroups = _groupPermissions(profile.permissions);

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<ProfileBloc>().add(ProfileLoadRequested()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroCard(user: user, scheme: scheme, textTheme: textTheme),
                const SizedBox(height: 16),

                _SectionCard(
                  title: 'Account Details',
                  icon: Icons.person_outline,
                  children: [
                    _DetailRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                      scheme: scheme,
                    ),
                    if (user.phone != null)
                      _DetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: user.phone!,
                        scheme: scheme,
                      ),
                    _DetailRow(
                      icon: user.isActive
                          ? Icons.verified_outlined
                          : Icons.warning_amber_outlined,
                      label: 'Email verified',
                      value: user.isActive ? 'Verified' : 'Not verified',
                      valueColor: user.isActive ? scheme.primary : scheme.error,
                      scheme: scheme,
                    ),
                    if (user.createdAt != null)
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Member since',
                        value: _formatDate(user.createdAt!),
                        scheme: scheme,
                      ),
                    _DetailRow(
                      icon: Icons.card_membership_outlined,
                      label: 'Subscription',
                      value: _capitalize(user.subscriptionStatus),
                      valueColor: user.hasActiveSubscription
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      scheme: scheme,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (profile.roles.isNotEmpty) ...[
                  _SectionCard(
                    title: 'Roles',
                    icon: Icons.shield_outlined,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.roles
                            .map((r) => _RoleChip(role: r, scheme: scheme))
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                if (permGroups.isNotEmpty) ...[
                  _PermissionsSection(
                    groups: permGroups,
                    scheme: scheme,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Account management ────────────────────────
                _SectionCard(
                  title: 'Account',
                  icon: Icons.manage_accounts_outlined,
                  children: [
                    // Add / switch accounts → goes to picker page
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.switch_account_outlined,
                        color: scheme.primary,
                      ),
                      title: const Text('Add or switch account'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRouter.accountPicker,
                        arguments: {'mode': 'add'},
                      ),
                    ),

                    const Divider(height: 24),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout, color: scheme.error),
                      title: Text(
                        'Sign out',
                        style: TextStyle(color: scheme.error),
                      ),
                      onTap: () => _confirmLogout(context, scheme),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, ColorScheme scheme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(AuthLogoutRequested());
    }
  }

  Map<String, List<PermissionEntity>> _groupPermissions(
    List<PermissionEntity> permissions,
  ) {
    final groups = <String, List<PermissionEntity>>{};
    for (final perm in permissions) {
      final group = perm.slug.split('.').first;
      groups.putIfAbsent(group, () => []).add(perm);
    }
    return groups;
  }

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]} ${dt.year}';

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

// ── Reusable sub-widgets (unchanged from previous version) ─────

class _HeroCard extends StatelessWidget {
  final UserEntity user;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _HeroCard({
    required this.user,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: scheme.primary.withOpacity(0.2),
              child: Text(
                _initials(user.displayName),
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer.withOpacity(0.75),
              ),
            ),
            if (user.primaryRole != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.primaryRole!.name,
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2)
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final ColorScheme scheme;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: valueColor ?? scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final RoleEntity role;
  final ColorScheme scheme;

  const _RoleChip({required this.role, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Text(
          role.name[0].toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
      label: Text(role.name),
      backgroundColor: scheme.surfaceContainerHighest,
    );
  }
}

class _PermissionsSection extends StatelessWidget {
  final Map<String, List<PermissionEntity>> groups;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _PermissionsSection({
    required this.groups,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.key_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Permissions',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    groups.values
                        .fold<int>(0, (sum, list) => sum + list.length)
                        .toString(),
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...groups.entries.map(
              (entry) => _PermissionGroup(
                group: entry.key,
                permissions: entry.value,
                scheme: scheme,
                textTheme: textTheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionGroup extends StatelessWidget {
  final String group;
  final List<PermissionEntity> permissions;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _PermissionGroup({
    required this.group,
    required this.permissions,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: permissions
                .map(
                  (p) => Tooltip(
                    message: p.name,
                    child: Chip(
                      label: Text(p.slug.split('.').last),
                      backgroundColor: scheme.secondaryContainer,
                      labelStyle: textTheme.labelSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
