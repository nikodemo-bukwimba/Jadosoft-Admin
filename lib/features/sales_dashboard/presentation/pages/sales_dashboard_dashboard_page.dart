import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/sales_dashboard_cubit.dart';
import '../cubit/sales_dashboard_state.dart';
import '../widgets/sales_kpi_row.dart';
import '../widgets/sales_revenue_chart.dart';
import '../widgets/sales_charts.dart';

class SalesDashboardDashboardPage extends StatefulWidget {
  const SalesDashboardDashboardPage({super.key});
  @override
  State<SalesDashboardDashboardPage> createState() => _SalesDashboardDashboardPageState();
}

class _SalesDashboardDashboardPageState extends State<SalesDashboardDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesDashboardCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 840;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: BlocBuilder<SalesDashboardCubit, SalesDashboardState>(
        builder: (context, state) {
          return NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                pinned: true,
                floating: true,
                expandedHeight: 64,
                backgroundColor: cs.surface,
                surfaceTintColor: cs.surfaceTint,
                title: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.green.shade600, Colors.green.shade400]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.point_of_sale, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Sales Dashboard', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                ]),
                actions: [
                  IconButton(icon: const Icon(Icons.refresh_outlined), tooltip: 'Refresh',
                    onPressed: () => context.read<SalesDashboardCubit>().refresh()),
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

  Widget _buildBody(BuildContext context, SalesDashboardState state, bool isDesktop) {
    final cs = Theme.of(context).colorScheme;

    if (state is SalesDashboardLoading || state is SalesDashboardInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is SalesDashboardError) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 48, color: cs.error), const SizedBox(height: 12),
        Text(state.message), const SizedBox(height: 16),
        FilledButton.icon(onPressed: () => context.read<SalesDashboardCubit>().refresh(),
          icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]));
    }
    if (state is SalesDashboardLoaded) {
      final p = state.projection;
      return RefreshIndicator(
        onRefresh: () => context.read<SalesDashboardCubit>().refresh(),
        child: isDesktop ? _DesktopLayout(projection: p) : _PhoneLayout(projection: p),
      );
    }
    return const SizedBox.shrink();
  }
}

class _DesktopLayout extends StatelessWidget {
  final dynamic projection;
  const _DesktopLayout({required this.projection});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SalesKpiRow(projection: projection),
        const SizedBox(height: 20),
        // Revenue chart + Orders ring
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(flex: 3, child: SalesRevenueChart(projection: projection)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: SalesOrdersRing(projection: projection)),
        ])),
        const SizedBox(height: 20),
        // Recent orders + Payment summary
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(flex: 3, child: SalesRecentOrders(projection: projection)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: SalesPaymentSummary(projection: projection)),
        ])),
        const SizedBox(height: 20),
        // Product performance full width
        SalesProductPerformance(projection: projection),
        const SizedBox(height: 16),
        _Footer(generatedAt: projection.generatedAt),
      ]),
    );
  }
}

class _PhoneLayout extends StatelessWidget {
  final dynamic projection;
  const _PhoneLayout({required this.projection});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SalesKpiRow(projection: projection),
        const SizedBox(height: 16),
        SalesRevenueChart(projection: projection),
        const SizedBox(height: 16),
        SalesOrdersRing(projection: projection),
        const SizedBox(height: 16),
        SalesRecentOrders(projection: projection),
        const SizedBox(height: 16),
        SalesPaymentSummary(projection: projection),
        const SizedBox(height: 16),
        SalesProductPerformance(projection: projection),
        const SizedBox(height: 16),
        _Footer(generatedAt: projection.generatedAt),
      ]),
    );
  }
}

class _Footer extends StatelessWidget {
  final DateTime generatedAt;
  const _Footer({required this.generatedAt});
  @override
  Widget build(BuildContext context) => Center(child: Text(
    'Last updated: ${generatedAt.toIso8601String().replaceFirst('T', ' ').substring(0, 16)}',
    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6))));
}