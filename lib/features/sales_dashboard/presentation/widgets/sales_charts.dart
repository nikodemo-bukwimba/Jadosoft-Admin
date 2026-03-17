import 'package:flutter/material.dart';
import '../../domain/projections/sales_dashboard_projection.dart';
import '../../../marketing_dashboard/presentation/widgets/shared_dash_components.dart';

// ─── Orders By Status Ring ───

class SalesOrdersRing extends StatelessWidget {
  final SalesDashboardProjection projection;
  const SalesOrdersRing({super.key, required this.projection});

  static const _statusColors = {
    'draft': Colors.grey, 'confirmed': Colors.blue, 'shipped': Colors.orange,
    'delivered': Colors.green, 'cancelled': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = projection.totalOrders;
    final statuses = projection.ordersByStatus;
    // Add mock data if empty
    final displayStatuses = statuses.isEmpty
        ? {'confirmed': 12, 'shipped': 8, 'delivered': 25, 'draft': 3, 'cancelled': 2}
        : statuses;
    final displayTotal = displayStatuses.values.fold<int>(0, (a, b) => a + b);

    return DashCard(
      title: 'Orders by Status',
      subtitle: '$displayTotal total orders',
      child: Row(
        children: [
          // Ring
          Expanded(
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 130, height: 130,
                child: CustomPaint(painter: _MultiRingPainter(
                  segments: displayStatuses.entries.map((e) => _Segment(
                    value: e.value / displayTotal, color: _statusColors[e.key] ?? cs.primary)).toList(),
                  backgroundColor: cs.surfaceContainerHighest, strokeWidth: 16))),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$displayTotal', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                Text('orders', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ]),
            ]),
          ),
          const SizedBox(width: 16),
          // Legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: displayStatuses.entries.map((e) {
                final pct = displayTotal > 0 ? (e.value / displayTotal * 100).round() : 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(
                      color: _statusColors[e.key] ?? cs.primary, borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_capitalize(e.key), style: const TextStyle(fontSize: 12))),
                    Text('$pct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _Segment { final double value; final Color color; const _Segment({required this.value, required this.color}); }

class _MultiRingPainter extends CustomPainter {
  final List<_Segment> segments; final Color backgroundColor; final double strokeWidth;
  _MultiRingPainter({required this.segments, required this.backgroundColor, this.strokeWidth = 14});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    const startOffset = -3.14159 / 2;
    const fullSweep = 2 * 3.14159;

    canvas.drawCircle(center, radius, Paint()..color = backgroundColor..strokeWidth = strokeWidth..style = PaintingStyle.stroke);

    double currentAngle = startOffset;
    for (final seg in segments) {
      final sweep = fullSweep * seg.value;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, sweep, false,
        Paint()..color = seg.color..strokeWidth = strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.butt);
      currentAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MultiRingPainter old) => true;
}

// ─── Recent Orders Table ───

class SalesRecentOrders extends StatelessWidget {
  final SalesDashboardProjection projection;
  const SalesRecentOrders({super.key, required this.projection});

  static const _statusColors = {
    'draft': Colors.grey, 'confirmed': Colors.blue, 'shipped': Colors.orange,
    'delivered': Colors.green, 'cancelled': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final orders = projection.recentOrders;

    return DashCard(
      title: 'Recent Orders',
      subtitle: '${orders.length} latest',
      trailing: TextButton(onPressed: () {}, child: Text('View All', style: TextStyle(fontSize: 12, color: cs.primary))),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: orders.isEmpty
          ? Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('No orders yet', style: TextStyle(color: cs.onSurfaceVariant))))
          : Column(children: [
              // Header
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(children: [
                  Expanded(flex: 3, child: Text('Customer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant))),
                  Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant))),
                  Expanded(flex: 2, child: Text('Status', textAlign: TextAlign.end, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant))),
                ])),
              Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
              ...orders.take(5).map((o) => _OrderRow(
                customerId: o.customerId, amount: o.total, status: o.status,
                statusColor: _statusColors[o.status] ?? cs.outline, createdAt: o.createdAt)),
            ]),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String customerId; final double amount; final String status; final Color statusColor; final DateTime createdAt;
  const _OrderRow({required this.customerId, required this.amount, required this.status, required this.statusColor, required this.createdAt});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(children: [
        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(customerId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          Text(_timeAgo(createdAt), style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        ])),
        Expanded(flex: 2, child: Text('TZS ${_fmtCurrency(amount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        Expanded(flex: 2, child: Align(alignment: Alignment.centerRight,
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))))),
      ]),
    );
  }

  String _fmtCurrency(double v) { if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M'; if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K'; return v.toStringAsFixed(0); }
  String _timeAgo(DateTime dt) { final diff = DateTime.now().difference(dt); if (diff.inHours < 24) return '${diff.inHours}h ago'; return '${diff.inDays}d ago'; }
}

// ─── Payment Summary ───

class SalesPaymentSummary extends StatelessWidget {
  final SalesDashboardProjection projection;
  const SalesPaymentSummary({super.key, required this.projection});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final confirmed = projection.confirmedPayments;
    final total = projection.totalOrders;
    final pending = total - confirmed;
    final rate = total > 0 ? confirmed / total : 0.0;
    // Mock provider split
    final mpesaCount = (confirmed * 0.65).round();
    final airtelCount = confirmed - mpesaCount;

    return DashCard(
      title: 'Payment Overview',
      subtitle: 'Collection performance',
      child: Column(children: [
        // Ring + stats
        Row(children: [
          Stack(alignment: Alignment.center, children: [
            SizedBox(width: 100, height: 100, child: CustomPaint(painter: RingPainter(
              value: rate, color: rate >= 0.7 ? Colors.green : Colors.orange,
              backgroundColor: cs.surfaceContainerHighest, strokeWidth: 12))),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${(rate * 100).round()}%', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              Text('collected', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            ]),
          ]),
          const SizedBox(width: 20),
          Expanded(child: Column(children: [
            _PaymentStatRow(label: 'Confirmed', value: '$confirmed', color: Colors.green, icon: Icons.check_circle),
            const SizedBox(height: 8),
            _PaymentStatRow(label: 'Pending', value: '$pending', color: Colors.orange, icon: Icons.schedule),
          ])),
        ]),
        const SizedBox(height: 16),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        // Provider breakdown
        Row(children: [
          _ProviderChip(icon: Icons.phone_android, label: 'M-Pesa', count: mpesaCount, color: Colors.green.shade700),
          const SizedBox(width: 12),
          _ProviderChip(icon: Icons.phone_android, label: 'Airtel Money', count: airtelCount, color: Colors.red.shade600),
        ]),
      ]),
    );
  }
}

class _PaymentStatRow extends StatelessWidget {
  final String label; final String value; final Color color; final IconData icon;
  const _PaymentStatRow({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: color), const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 13)), const Spacer(),
    Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
  ]);
}

class _ProviderChip extends StatelessWidget {
  final IconData icon; final String label; final int count; final Color color;
  const _ProviderChip({required this.icon, required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.15))),
    child: Row(children: [
      Icon(icon, size: 18, color: color), const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        Text('$count payments', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ])),
    ])));
}

// ─── Product Performance ───

class SalesProductPerformance extends StatelessWidget {
  final SalesDashboardProjection projection;
  const SalesProductPerformance({super.key, required this.projection});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DashCard(
      title: 'Product Catalog',
      subtitle: '${projection.productCount} total products',
      child: Column(children: [
        Row(children: [
          _ProductStatCard(value: '${projection.productCount}', label: 'Total', icon: Icons.inventory_2_outlined, color: cs.primary),
          const SizedBox(width: 12),
          _ProductStatCard(value: '${projection.featuredProductCount}', label: 'Featured', icon: Icons.star_outline, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          _ProductStatCard(value: '${projection.productCount - projection.featuredProductCount}', label: 'Standard', icon: Icons.grid_view, color: Colors.teal),
        ]),
        const SizedBox(height: 16),
        // Featured ratio bar
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Featured ratio', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            Text('${projection.productCount > 0 ? (projection.featuredProductCount / projection.productCount * 100).round() : 0}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.amber.shade700)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: projection.productCount > 0 ? projection.featuredProductCount / projection.productCount : 0,
              minHeight: 8, backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade600))),
        ]),
      ]),
    );
  }
}

class _ProductStatCard extends StatelessWidget {
  final String value; final String label; final IconData icon; final Color color;
  const _ProductStatCard({required this.value, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Icon(icon, size: 22, color: color),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ])));
}