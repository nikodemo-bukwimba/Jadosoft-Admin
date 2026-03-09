// dashboard_page.dart
// ─────────────────────────────────────────────────────────────
// Admin dashboard — shows real stats from GET /admin/dashboard.
//
// Data pipeline:
//   DashboardRemoteDataSource → DashboardRepository (cache-first)
//   → GetDashboardStatsUseCase → DashboardBloc → this page.
//
// Access:
//   Shell hides the tab via canViewDashboard (permission-gated).
//   This page self-guards as a second layer.
//
// States handled:
//   DashboardLoading  → full-screen spinner (first load)
//   DashboardLoaded   → stat cards + data (isRefreshing: overlay)
//   DashboardError    → error view OR stale data + error banner
//   DashboardInitial  → triggers load automatically
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/rbac/rbac_extensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<DashboardBloc>()..add(DashboardLoadRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Second-layer guard — page renders nothing if not permitted.
        if (authState is! AuthAuthenticated || !authState.canViewDashboard) {
          return const SizedBox.shrink();
        }

        return BlocProvider.value(
          value: _bloc,
          child: _DashboardScaffold(auth: authState),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Scaffold — owns the AppBar, RefreshIndicator, and state routing
// ─────────────────────────────────────────────────────────────
class _DashboardScaffold extends StatelessWidget {
  final AuthAuthenticated auth;
  const _DashboardScaffold({required this.auth});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listener: (context, state) {
          // Show error snackbar on refresh failure (stale data still visible)
          if (state is DashboardError && state.previousStats != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: scheme.onError,
                  onPressed: () => context.read<DashboardBloc>().add(
                    DashboardRefreshRequested(),
                  ),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          // ── First load ──────────────────────────────────
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Error with no previous data ─────────────────
          if (state is DashboardError && state.previousStats == null) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<DashboardBloc>().add(DashboardLoadRequested()),
            );
          }

          // ── Data available (loaded or error-with-stale) ─
          final stats = switch (state) {
            DashboardLoaded s => s.stats,
            DashboardError s => s.previousStats!,
            _ => null,
          };

          if (stats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final isRefreshing = state is DashboardLoaded && state.isRefreshing;

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<DashboardBloc>().add(DashboardRefreshRequested()),
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _WelcomeRow(
                            auth: auth,
                            scheme: scheme,
                            textTheme: textTheme,
                          ),
                          const SizedBox(height: 24),
                          _RoleBanner(
                            auth: auth,
                            scheme: scheme,
                            textTheme: textTheme,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Overview',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _StatCardGrid(
                            stats: stats,
                            scheme: scheme,
                            textTheme: textTheme,
                          ),
                          const SizedBox(height: 16),
                          _FetchedAtLabel(
                            fetchedAt: stats.fetchedAt,
                            scheme: scheme,
                            textTheme: textTheme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Refresh overlay ─────────────────────────
                if (isRefreshing)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      color: scheme.primary,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Welcome row
// ─────────────────────────────────────────────────────────────
class _WelcomeRow extends StatelessWidget {
  final AuthAuthenticated auth;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _WelcomeRow({
    required this.auth,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            auth.displayName.initials,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${auth.activeSession.user.name.split(' ').first}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                auth.primaryRoleName,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Role banner (display-only — uses isSuperAdmin for badge color)
// ─────────────────────────────────────────────────────────────
class _RoleBanner extends StatelessWidget {
  final AuthAuthenticated auth;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _RoleBanner({
    required this.auth,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isSA = auth.isSuperAdmin;
    final bgColor = isSA ? scheme.errorContainer : scheme.secondaryContainer;
    final fgColor = isSA
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;
    final roleIcon = isSA
        ? Icons.security
        : Icons.admin_panel_settings_outlined;
    final roleText = isSA
        ? 'Super Admin — full system access'
        : auth.primaryRoleName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(roleIcon, color: fgColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              roleText,
              style: textTheme.bodyMedium?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stat card grid — real data from DashboardStats
// ─────────────────────────────────────────────────────────────
class _StatCardGrid extends StatelessWidget {
  final DashboardStats stats;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _StatCardGrid({
    required this.stats,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        label: 'Total Users',
        value: _fmtInt(stats.totalUsers),
        icon: Icons.people_outline,
      ),
      (
        label: 'New This Month',
        value: _fmtInt(stats.newUsersThisMonth),
        icon: Icons.person_add_outlined,
      ),
      (
        label: 'Subscriptions',
        value: _fmtInt(stats.activeSubscriptions),
        icon: Icons.card_membership_outlined,
      ),
      (
        label: 'Pending Payments',
        value: _fmtInt(stats.pendingPayments),
        icon: Icons.payment_outlined,
      ),
      (
        label: 'Revenue (Month)',
        value: _fmtCurrency(stats.revenueThisMonth),
        icon: Icons.trending_up,
      ),
      (
        label: 'Total Revenue',
        value: _fmtCurrency(stats.totalRevenue),
        icon: Icons.attach_money,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600
            ? 3
            : constraints.maxWidth > 400
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: cards
              .map(
                (c) => _StatCard(
                  label: c.label,
                  value: c.value,
                  icon: c.icon,
                  scheme: scheme,
                  textTheme: textTheme,
                ),
              )
              .toList(),
        );
      },
    );
  }

  String _fmtInt(int? value) => value?.toString() ?? '—';

  String _fmtCurrency(double? value) {
    if (value == null) return '—';
    // Simple formatting — replace with intl NumberFormat if needed
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    }
    return '\$${value.toStringAsFixed(2)}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: scheme.primary, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Fetched-at label
// ─────────────────────────────────────────────────────────────
class _FetchedAtLabel extends StatelessWidget {
  final DateTime fetchedAt;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _FetchedAtLabel({
    required this.fetchedAt,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final h = fetchedAt.hour.toString().padLeft(2, '0');
    final m = fetchedAt.minute.toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(Icons.access_time, size: 12, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          'Last updated $h:$m',
          style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Error view (first-load failure, no stale data)
// ─────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard',
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
