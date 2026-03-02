import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/overview_dashboard_cubit.dart';
import '../cubit/overview_dashboard_state.dart';
import '../widgets/overview_dashboard_metric_card.dart';

class OverviewDashboardDashboardPage extends StatelessWidget {
  const OverviewDashboardDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<OverviewDashboardCubit>().refresh(),
          ),
        ],
      ),
      body: BlocBuilder<OverviewDashboardCubit, OverviewDashboardState>(
        builder: (context, state) {
          if (state is OverviewDashboardLoading || state is OverviewDashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OverviewDashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<OverviewDashboardCubit>().refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is OverviewDashboardLoaded) {
            final projection = state.projection;
            return RefreshIndicator(
              onRefresh: () => context.read<OverviewDashboardCubit>().refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                OverviewDashboardMetricCard(
                  title: 'Orders',
                  value: projection.totalOrders.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                ),
                OverviewDashboardMetricCard(
                  title: 'Projects',
                  value: projection.totalProjects.toString(),
                  icon: Icons.folder,
                  color: Colors.green,
                ),
                OverviewDashboardMetricCard(
                  title: 'Revenue',
                  value: projection.revenue.toStringAsFixed(2),
                  icon: Icons.pie_chart_outline,
                  color: Colors.orange,
                ),
                OverviewDashboardMetricCard(
                  title: 'Projects By Status',
                  value: projection.projectsByStatus.length.toString() + ' groups',
                  icon: Icons.list_alt,
                  color: Colors.purple,
                ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text('Breakdown', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...projection.projectsByStatus.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            entry.value.toString(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),


                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Updated: ' + projection.generatedAt.toIso8601String().split('T').first,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
