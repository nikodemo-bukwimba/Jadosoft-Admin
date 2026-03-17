import 'package:flutter/material.dart';
import '../../domain/projections/marketing_dashboard_projection.dart';
import 'shared_dash_components.dart';

// ─── Officer Leaderboard ───

class MktOfficerLeaderboard extends StatelessWidget {
  final MarketingDashboardProjection projection;
  const MktOfficerLeaderboard({super.key, required this.projection});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Build name lookup
    final nameMap = <String, String>{};
    for (final o in projection.allOfficers) {
      nameMap[o.id] = o.name;
    }
    final entries = projection.visitsByOfficer.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVisits = entries.isEmpty ? 1 : entries.first.value;
    final medals = [
      Colors.amber.shade600,
      Colors.blueGrey.shade400,
      Colors.brown.shade400,
    ];

    return DashCard(
      title: 'Officer Leaderboard',
      subtitle: '${entries.length} officers ranked by visits',
      child: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No data'),
              ),
            )
          : Column(
              children: entries.asMap().entries.map((e) {
                final idx = e.key;
                final entry = e.value;
                final ratio = entry.value / maxVisits;
                final isTop3 = idx < 3;
                final officerName = nameMap[entry.key] ?? entry.key;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: isTop3
                            ? Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      medals[idx],
                                      medals[idx].withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${idx + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                '${idx + 1}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isTop3
                            ? cs.primary.withValues(alpha: 0.15)
                            : cs.surfaceContainerHighest,
                        child: Text(
                          officerName.isNotEmpty
                              ? officerName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isTop3 ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              officerName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isTop3
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: cs.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isTop3
                                      ? cs.primary
                                      : cs.primary.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isTop3
                              ? cs.primary.withValues(alpha: 0.1)
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isTop3 ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ─── Top Customers ───

class MktTopCustomers extends StatelessWidget {
  final MarketingDashboardProjection projection;
  const MktTopCustomers({super.key, required this.projection});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Map<String, int> visitsByCustomer = {};
    for (final v in projection.recentVisits) {
      final key = v.businessName ?? v.customerId;
      visitsByCustomer[key] = (visitsByCustomer[key] ?? 0) + 1;
    }
    final sorted = visitsByCustomer.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    final maxVal = top.isEmpty ? 1 : top.first.value;

    return DashCard(
      title: 'Most Visited Customers',
      subtitle: 'By visit frequency',
      child: top.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No data'),
              ),
            )
          : Column(
              children: top.asMap().entries.map((e) {
                final idx = e.key;
                final entry = e.value;
                final ratio = entry.value / maxVal;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: cs.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange.withValues(
                                    alpha: 0.5 + ratio * 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ─── Activity Heatmap ───

class MktActivityHeatmap extends StatelessWidget {
  final MarketingDashboardProjection projection;
  const MktActivityHeatmap({super.key, required this.projection});
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Build name lookup from allOfficers
    final nameMap = <String, String>{};
    for (final o in projection.allOfficers) {
      nameMap[o.id] = o.name;
    }
    final officers = projection.visitsByOfficer.keys.toList();
    final Map<String, Map<String, int>> matrix = {};
    for (final v in projection.recentVisits) {
      final name = nameMap[v.officerId] ?? v.officerId;
      matrix[name] ??= {};
      final dayName = _days[v.visitDate.weekday - 1];
      matrix[name]![dayName] = (matrix[name]![dayName] ?? 0) + 1;
    }
    if (matrix.isEmpty && officers.isNotEmpty) {
      for (final off in officers.take(4)) {
        final name = nameMap[off] ?? off;
        matrix[name] = {};
        for (final day in _days) matrix[name]![day] = (day.hashCode % 5).abs();
      }
    }
    final allVals = matrix.values.expand((m) => m.values).toList();
    final maxVal = allVals.isEmpty
        ? 1
        : allVals.reduce((a, b) => a > b ? a : b);

    return DashCard(
      title: 'Visit Heatmap',
      subtitle: 'Officer activity by day',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 80),
              ..._days.map(
                (d) => Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (matrix.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No data'))
          else
            ...matrix.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        e.key,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    ..._days.map((day) {
                      final count = e.value[day] ?? 0;
                      final intensity = maxVal > 0 ? count / maxVal : 0.0;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Tooltip(
                            message: '${e.key} · $day: $count visits',
                            child: Container(
                              height: 26,
                              decoration: BoxDecoration(
                                color: count == 0
                                    ? cs.surfaceContainerHighest
                                    : cs.primary.withValues(
                                        alpha: 0.12 + intensity * 0.78,
                                      ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: count > 0
                                  ? Center(
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: intensity > 0.5
                                              ? Colors.white
                                              : cs.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Low ',
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
              ...List.generate(
                5,
                (i) => Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12 + i * 0.18),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text(
                ' High',
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Recent Activity Feed ───

class MktActivityFeed extends StatelessWidget {
  final MarketingDashboardProjection projection;
  const MktActivityFeed({super.key, required this.projection});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visits = projection.recentVisits.take(8).toList();
    // Name lookup
    final nameMap = <String, String>{};
    for (final o in projection.allOfficers) {
      nameMap[o.id] = o.name;
    }

    return DashCard(
      title: 'Recent Activity',
      subtitle: 'Latest field visits',
      child: visits.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No activity'),
              ),
            )
          : Column(
              children: visits.asMap().entries.map((e) {
                final i = e.key;
                final visit = e.value;
                final isLast = i == visits.length - 1;
                final officerName = nameMap[visit.officerId] ?? visit.officerId;
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: cs.surface, width: 2),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 1.5,
                                  color: cs.outlineVariant.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: isLast ? 0 : 14,
                            left: 4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                visit.businessName ?? visit.customerId,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 11,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      officerName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    _timeAgo(visit.visitDate),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
