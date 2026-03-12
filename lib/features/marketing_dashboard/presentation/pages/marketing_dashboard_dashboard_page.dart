import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/marketing_dashboard_cubit.dart';
import '../cubit/marketing_dashboard_state.dart';
import '../widgets/marketing_dashboard_metric_card.dart';

class MarketingDashboardDashboardPage extends StatelessWidget {
  const MarketingDashboardDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketing Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<MarketingDashboardCubit>().refresh(),
          ),
        ],
      ),
      body: BlocBuilder<MarketingDashboardCubit, MarketingDashboardState>(
        builder: (context, state) {
          if (state is MarketingDashboardLoading ||
              state is MarketingDashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MarketingDashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        context.read<MarketingDashboardCubit>().refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is MarketingDashboardLoaded) {
            final projection = state.projection;
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<MarketingDashboardCubit>().refresh(),
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
                        MarketingDashboardMetricCard(
                          title: 'Total Visits',
                          value: projection.totalVisits.toString(),
                          icon: Icons.place,
                          color: Colors.blue,
                        ),
                        MarketingDashboardMetricCard(
                          title: 'Visits by Officer',
                          value: '${projection.visitsByOfficer.length} groups',
                          icon: Icons.attach_money,
                          color: Colors.green,
                        ),
                        MarketingDashboardMetricCard(
                          title: 'Plan Compliance Rate',
                          value: projection.planComplianceRate.toStringAsFixed(
                            1,
                          ),
                          icon: Icons.check_circle,
                          color: Colors.orange,
                        ),
                        MarketingDashboardMetricCard(
                          title: 'Reports Submitted',
                          value: projection.dailyReportSubmissionRate
                              .toString(),
                          icon: Icons.summarize,
                          color: Colors.purple,
                        ),
                        MarketingDashboardMetricCard(
                          title: 'Total Customers',
                          value: projection.totalCustomers.toString(),
                          icon: Icons.store,
                          color: Colors.red,
                        ),
                        MarketingDashboardMetricCard(
                          title: 'Customers Visited This Month',
                          value: projection.customersVisitedThisMonth
                              .toString(),
                          icon: Icons.calendar_today,
                          color: Colors.teal,
                        ),
                        MarketingDashboardMetricCard(
                          title: 'Recent Visits',
                          value: '${projection.recentVisits.length} items',
                          icon: Icons.show_chart,
                          color: Colors.amber,
                        ),
                        MarketingDashboardMetricCard(
                          title: 'Active Officers',
                          value: projection.activeOfficers.toString(),
                          icon: Icons.badge,
                          color: Colors.indigo,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Breakdown',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...projection.visitsByOfficer.entries.map(
                      (entry) => Padding(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                entry.value.toString(),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Recent Visits',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...projection.recentVisits.map(
                      (item) => Card(
                        child: ListTile(
                          title: Text(item.businessName ?? ''),
                          dense: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Updated: ${projection.generatedAt.toIso8601String().split('T').first}',
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
