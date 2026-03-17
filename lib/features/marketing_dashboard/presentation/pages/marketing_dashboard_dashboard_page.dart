import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/marketing_dashboard_cubit.dart';
import '../cubit/marketing_dashboard_state.dart';
import '../widgets/mkt_charts.dart';
import '../widgets/mkt_tables.dart';

class MarketingDashboardDashboardPage extends StatefulWidget {
  const MarketingDashboardDashboardPage({super.key});
  @override
  State<MarketingDashboardDashboardPage> createState() =>
      _MarketingDashboardDashboardPageState();
}

class _MarketingDashboardDashboardPageState
    extends State<MarketingDashboardDashboardPage> {
  String _period = 'This Week';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketingDashboardCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 840;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: BlocBuilder<MarketingDashboardCubit, MarketingDashboardState>(
        builder: (context, state) {
          return NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: cs.surface,
                surfaceTintColor: cs.surfaceTint,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade400],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.campaign,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Marketing Dashboard',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_outlined),
                    tooltip: 'Refresh',
                    onPressed: () =>
                        context.read<MarketingDashboardCubit>().refresh(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
            body: _buildBody(context, state, isDesktop),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    MarketingDashboardState state,
    bool isDesktop,
  ) {
    final cs = Theme.of(context).colorScheme;
    if (state is MarketingDashboardLoading ||
        state is MarketingDashboardInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is MarketingDashboardError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(state.message),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  context.read<MarketingDashboardCubit>().refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state is MarketingDashboardLoaded) {
      final p = state.projection;
      return RefreshIndicator(
        onRefresh: () => context.read<MarketingDashboardCubit>().refresh(),
        child: isDesktop
            ? _DesktopLayout(projection: p, period: _period)
            : _PhoneLayout(projection: p, period: _period),
      );
    }
    return const SizedBox.shrink();
  }
}

class _DesktopLayout extends StatelessWidget {
  final dynamic projection;
  final String period;
  const _DesktopLayout({required this.projection, required this.period});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MktKpiRow(projection: projection),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: MktVisitsChart(projection: projection, period: period),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: MktComplianceRing(projection: projection),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: MktOfficerLeaderboard(projection: projection),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: MktTopCustomers(projection: projection),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: MktActivityHeatmap(projection: projection),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: MktActivityFeed(projection: projection),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Footer(generatedAt: projection.generatedAt),
        ],
      ),
    );
  }
}

class _PhoneLayout extends StatelessWidget {
  final dynamic projection;
  final String period;
  const _PhoneLayout({required this.projection, required this.period});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MktKpiRow(projection: projection),
          const SizedBox(height: 16),
          MktVisitsChart(projection: projection, period: period),
          const SizedBox(height: 16),
          MktComplianceRing(projection: projection),
          const SizedBox(height: 16),
          MktOfficerLeaderboard(projection: projection),
          const SizedBox(height: 16),
          MktTopCustomers(projection: projection),
          const SizedBox(height: 16),
          MktActivityHeatmap(projection: projection),
          const SizedBox(height: 16),
          MktActivityFeed(projection: projection),
          const SizedBox(height: 16),
          _Footer(generatedAt: projection.generatedAt),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final DateTime generatedAt;
  const _Footer({required this.generatedAt});
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'Last updated: ${generatedAt.toIso8601String().replaceFirst('T', ' ').substring(0, 16)}',
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    ),
  );
}
