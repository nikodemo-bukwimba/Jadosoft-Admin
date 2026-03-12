import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/sales_dashboard_cubit.dart';
import '../cubit/sales_dashboard_state.dart';
import '../widgets/sales_dashboard_metric_card.dart';

class SalesDashboardDashboardPage extends StatelessWidget {
  const SalesDashboardDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<SalesDashboardCubit>().refresh(),
          ),
        ],
      ),
      body: BlocBuilder<SalesDashboardCubit, SalesDashboardState>(
        builder: (context, state) {
          if (state is SalesDashboardLoading || state is SalesDashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SalesDashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<SalesDashboardCubit>().refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is SalesDashboardLoaded) {
            final projection = state.projection;
            return RefreshIndicator(
              onRefresh: () => context.read<SalesDashboardCubit>().refresh(),
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
                SalesDashboardMetricCard(
                  title: 'Total Orders',
                  value: projection.totalOrders.toString(),
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                ),
                SalesDashboardMetricCard(
                  title: 'Total Revenue',
                  value: projection.totalRevenue.toStringAsFixed(2),
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
                SalesDashboardMetricCard(
                  title: 'Avg Order Value',
                  value: projection.averageOrderValue.toStringAsFixed(1),
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
                SalesDashboardMetricCard(
                  title: 'Orders by Status',
                  value: projection.ordersByStatus.length.toString() + ' groups',
                  icon: Icons.list_alt,
                  color: Colors.purple,
                ),
                SalesDashboardMetricCard(
                  title: 'Confirmed Payments',
                  value: projection.confirmedPayments.toString(),
                  icon: Icons.verified,
                  color: Colors.red,
                ),
                SalesDashboardMetricCard(
                  title: 'Recent Orders',
                  value: projection.recentOrders.length.toString() + ' items',
                  icon: Icons.bar_chart,
                  color: Colors.teal,
                ),
                SalesDashboardMetricCard(
                  title: 'Total Products',
                  value: projection.productCount.toString(),
                  icon: Icons.inventory_2,
                  color: Colors.amber,
                ),
                SalesDashboardMetricCard(
                  title: 'Featured Products',
                  value: projection.featuredProductCount.toString(),
                  icon: Icons.star,
                  color: Colors.indigo,
                ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text('Breakdown', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...projection.ordersByStatus.entries.map((entry) => Padding(
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

                  const SizedBox(height: 24),
                  Text('Recent Orders', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...projection.recentOrders.map((item) => Card(
                    child: ListTile(
                      title: Text(item.customerId),
                      dense: true,
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
