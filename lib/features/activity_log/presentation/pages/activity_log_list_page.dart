import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/activity_log_entity.dart';
import '../bloc/activity_log_bloc.dart';
import '../bloc/activity_log_event.dart';
import '../bloc/activity_log_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ActivityLogListPage — Read-only audit trail
// Filters: search, action type, entity type, date range
// ─────────────────────────────────────────────────────────────────────────────

class ActivityLogListPage extends StatefulWidget {
  const ActivityLogListPage({super.key});

  @override
  State<ActivityLogListPage> createState() => _ActivityLogListPageState();
}

class _ActivityLogListPageState extends State<ActivityLogListPage> {
  String _search = '';
  String? _filterAction;
  String? _filterEntity;

  static const _actions = [
    'logged_in', 'logged_out', 'created', 'updated',
    'deleted', 'transitioned',
  ];

  static const _entities = [
    'session', 'officer', 'customer', 'product', 'category',
    'promotion', 'visit', 'weekly_plan', 'daily_report',
    'order', 'notification',
  ];

  List<ActivityLogEntity> _apply(List<ActivityLogEntity> all) {
    var result = all;
    if (_filterAction != null) {
      result = result.where((e) => e.action == _filterAction).toList();
    }
    if (_filterEntity != null) {
      result = result.where((e) => e.entityType == _filterEntity).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result.where((e) =>
        e.actorName.toLowerCase().contains(q) ||
        e.action.toLowerCase().contains(q) ||
        e.entityType.toLowerCase().contains(q) ||
        e.entityId.toLowerCase().contains(q) ||
        (e.ipAddress?.toLowerCase().contains(q) ?? false),
      ).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: () => context
                .read<ActivityLogBloc>()
                .add(ActivityLogLoadAllRequested()),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + filters ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search actor, action, entity...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12,
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 8),
                // Action filter
                PopupMenuButton<String?>(
                  icon: Icon(
                    Icons.bolt_outlined,
                    color: _filterAction != null ? scheme.primary : null,
                  ),
                  tooltip: 'Filter by action',
                  onSelected: (v) => setState(() => _filterAction = v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('All actions')),
                    ..._actions.map((a) => PopupMenuItem(
                      value: a,
                      child: Row(children: [
                        _ActionIcon(action: a, size: 16),
                        const SizedBox(width: 8),
                        Text(_labelAction(a)),
                      ]),
                    )),
                  ],
                ),
                // Entity filter
                PopupMenuButton<String?>(
                  icon: Icon(
                    Icons.category_outlined,
                    color: _filterEntity != null ? scheme.primary : null,
                  ),
                  tooltip: 'Filter by entity',
                  onSelected: (v) => setState(() => _filterEntity = v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('All entities')),
                    ..._entities.map((e) => PopupMenuItem(
                      value: e,
                      child: Text(_labelEntity(e)),
                    )),
                  ],
                ),
              ],
            ),
          ),

          // ── Active filter chips ───────────────────────────────────────
          if (_filterAction != null || _filterEntity != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  if (_filterAction != null)
                    _FilterChip(
                      label: _labelAction(_filterAction!),
                      onRemove: () => setState(() => _filterAction = null),
                    ),
                  if (_filterEntity != null)
                    _FilterChip(
                      label: _labelEntity(_filterEntity!),
                      onRemove: () => setState(() => _filterEntity = null),
                    ),
                ],
              ),
            ),

          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<ActivityLogBloc, ActivityLogState>(
              builder: (context, state) {
                if (state is ActivityLogLoading || state is ActivityLogInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ActivityLogFailure) {
                  return Center(child: Text(state.message));
                }
                if (state is ActivityLogEmpty) {
                  return const Center(child: Text('No activity logs found.'));
                }

                List<ActivityLogEntity> items = [];
                if (state is ActivityLogListLoaded) items = state.items;

                final filtered = _apply(items);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No logs match the filter.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 56),
                  itemBuilder: (_, i) => _LogRow(
                    log: filtered[i],
                    onTap: () => context.push(
                      AppRouter.activityLogDetailPath(filtered[i].id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log row
// ─────────────────────────────────────────────────────────────────────────────

class _LogRow extends StatelessWidget {
  final ActivityLogEntity log;
  final VoidCallback onTap;

  const _LogRow({required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = _formatTime(log.occurredAt);

    return ListTile(
      leading: _ActionIcon(action: log.action),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${log.actorName} ${_labelAction(log.action)} '
              '${_labelEntity(log.entityType)}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${_labelEntity(log.entityType)} · #${log.entityId.split('-').last.toUpperCase()}'
        '${log.ipAddress != null ? ' · ${log.ipAddress}' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action icon with colour coding
// ─────────────────────────────────────────────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  final String action;
  final double size;

  const _ActionIcon({required this.action, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _resolve(action, Theme.of(context).colorScheme);
    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: size, color: color),
    );
  }

  (IconData, Color) _resolve(String action, ColorScheme s) {
    switch (action) {
      case 'created':     return (Icons.add_circle_outline, Colors.green);
      case 'updated':     return (Icons.edit_outlined, Colors.blue);
      case 'deleted':     return (Icons.delete_outline, Colors.red);
      case 'transitioned':return (Icons.swap_horiz, Colors.orange);
      case 'logged_in':   return (Icons.login, Colors.teal);
      case 'logged_out':  return (Icons.logout, Colors.grey);
      default:            return (Icons.history, s.primary);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active filter chip
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onRemove,
        backgroundColor: scheme.primaryContainer.withValues(alpha: 0.4),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Label helpers
// ─────────────────────────────────────────────────────────────────────────────

String _labelAction(String a) {
  const map = {
    'created': 'Created', 'updated': 'Updated', 'deleted': 'Deleted',
    'transitioned': 'Transitioned', 'logged_in': 'Logged In',
    'logged_out': 'Logged Out',
  };
  return map[a] ?? a;
}

String _labelEntity(String e) {
  const map = {
    'session': 'Session', 'officer': 'Officer', 'customer': 'Customer',
    'product': 'Product', 'category': 'Category', 'promotion': 'Promotion',
    'visit': 'Visit', 'weekly_plan': 'Weekly Plan',
    'daily_report': 'Daily Report', 'order': 'Order',
    'notification': 'Notification',
  };
  return map[e] ?? e;
}