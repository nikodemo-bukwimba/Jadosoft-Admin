import 'package:flutter/material.dart';
import '../../domain/projections/sales_dashboard_projection.dart';
import '../../../marketing_dashboard/presentation/widgets/shared_dash_components.dart';

class SalesKpiRow extends StatelessWidget {
  final SalesDashboardProjection projection;
  const SalesKpiRow({super.key, required this.projection});

  String _fmtCurrency(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 840;
    final paymentRate = projection.totalOrders > 0
        ? (projection.confirmedPayments / projection.totalOrders * 100).round()
        : 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isDesktop ? 1.6 : 1.4,
      children: [
        KpiCard(
          title: 'Total Orders',
          value: projection.totalOrders.toString(),
          delta: 'this period',
          deltaPositive: true,
          icon: Icons.shopping_bag_outlined,
          color: Colors.blue.shade600,
        ),
        KpiCard(
          title: 'Total Revenue',
          value: _fmtCurrency(projection.totalRevenue),
          prefix: 'TZS',
          delta: 'this period',
          deltaPositive: true,
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.green.shade600,
        ),
        KpiCard(
          title: 'Avg Order Value',
          value: _fmtCurrency(projection.averageOrderValue),
          prefix: 'TZS',
          delta: 'per order',
          deltaPositive: true,
          icon: Icons.receipt_long_outlined,
          color: Colors.orange.shade600,
        ),
        KpiCard(
          title: 'Payment Rate',
          value: '$paymentRate%',
          delta: paymentRate >= 80 ? 'Healthy' : 'Low',
          deltaPositive: paymentRate >= 80,
          icon: Icons.verified_outlined,
          color: Colors.purple.shade600,
        ),
      ],
    );
  }
}