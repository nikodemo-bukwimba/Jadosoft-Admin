import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/activity_log_entity.dart';
import '../bloc/activity_log_bloc.dart';
import '../bloc/activity_log_event.dart';
import '../bloc/activity_log_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ActivityLogDetailPage — Full audit entry view
// Read-only. Shows actor, action, entity, snapshot, IP, user agent.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityLogDetailPage extends StatelessWidget {
  final String id;
  const ActivityLogDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityLogBloc, ActivityLogState>(
      builder: (context, state) {
        if (state is ActivityLogLoading || state is ActivityLogInitial) {
          context.read<ActivityLogBloc>().add(ActivityLogLoadOneRequested(id));
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is ActivityLogFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Activity Log')),
            body: Center(child: Text(state.message)),
          );
        }
        if (state is ActivityLogDetailLoaded) {
          return _DetailScaffold(log: state.item);
        }
        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  final ActivityLogEntity log;
  const _DetailScaffold({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Log'), centerTitle: false),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Action banner ────────────────────────────────────────
                _ActionBanner(log: log),
                const SizedBox(height: 20),

                // ── Actor info ───────────────────────────────────────────
                _Section(
                  title: 'Actor',
                  icon: Icons.person_outline,
                  children: [
                    _Field('Name', log.actorName),
                    _Field('Role', log.actorRole),
                    _Field('Actor ID', log.actorId),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Event info ───────────────────────────────────────────
                _Section(
                  title: 'Event',
                  icon: Icons.bolt_outlined,
                  children: [
                    _Field('Action', _labelAction(log.action)),
                    _Field('Entity Type', _labelEntity(log.entityType)),
                    _Field('Entity ID', '#${log.entityId}'),
                    _Field('Occurred At', _formatFull(log.occurredAt)),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Entity snapshot ──────────────────────────────────────
                if (log.entitySnapshot != null &&
                    log.entitySnapshot!.isNotEmpty) ...[
                  _SnapshotCard(snapshot: log.entitySnapshot!),
                  const SizedBox(height: 16),
                ],

                // ── Technical info ───────────────────────────────────────
                if (log.ipAddress != null || log.userAgent != null)
                  _Section(
                    title: 'Technical',
                    icon: Icons.dns_outlined,
                    children: [
                      if (log.ipAddress != null)
                        _Field('IP Address', log.ipAddress!),
                      if (log.userAgent != null)
                        _Field('User Agent', log.userAgent!),
                    ],
                  ),

                const SizedBox(height: 32),

                // ── Log ID footer ────────────────────────────────────────
                Center(
                  child: Text(
                    'Log ID: ${log.id}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action banner
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBanner extends StatelessWidget {
  final ActivityLogEntity log;
  const _ActionBanner({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (color, icon) = _resolveAction(log.action);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.actorName} ${_labelAction(log.action).toLowerCase()} '
                  'a ${_labelEntity(log.entityType).toLowerCase()}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFull(log.occurredAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _resolveAction(String action) {
    switch (action) {
      case 'created':
        return (Colors.green, Icons.add_circle_outline);
      case 'updated':
        return (Colors.blue, Icons.edit_outlined);
      case 'deleted':
        return (Colors.red, Icons.delete_outline);
      case 'transitioned':
        return (Colors.orange, Icons.swap_horiz);
      case 'logged_in':
        return (Colors.teal, Icons.login);
      case 'logged_out':
        return (Colors.grey, Icons.logout);
      default:
        return (Colors.purple, Icons.history);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section card
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field row
// ─────────────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Entity snapshot card — pretty-prints the JSON snapshot
// ─────────────────────────────────────────────────────────────────────────────

class _SnapshotCard extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  const _SnapshotCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = _prettyPrint(snapshot);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.data_object, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Entity Snapshot',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  tooltip: 'Copy snapshot',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Snapshot copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Key-value rows
            ...snapshot.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        e.key,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _valueStr(e.value),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _prettyPrint(Map<String, dynamic> m) {
    final buf = StringBuffer('{\n');
    for (final e in m.entries) {
      buf.write('  "${e.key}": ${_valueStr(e.value)}\n');
    }
    buf.write('}');
    return buf.toString();
  }

  String _valueStr(dynamic v) {
    if (v == null) return 'null';
    if (v is String) return '"$v"';
    if (v is List) return '[${v.map(_valueStr).join(', ')}]';
    if (v is Map) return '{...}';
    return v.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _formatFull(DateTime dt) {
  final months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '${dt.day} ${months[dt.month]} ${dt.year} at $h:$m';
}

String _labelAction(String a) {
  const map = {
    'created': 'Created',
    'updated': 'Updated',
    'deleted': 'Deleted',
    'transitioned': 'Transitioned',
    'logged_in': 'Logged In',
    'logged_out': 'Logged Out',
  };
  return map[a] ?? a;
}

String _labelEntity(String e) {
  const map = {
    'session': 'Session',
    'officer': 'Officer',
    'customer': 'Customer',
    'product': 'Product',
    'category': 'Category',
    'promotion': 'Promotion',
    'visit': 'Visit',
    'weekly_plan': 'Weekly Plan',
    'daily_report': 'Daily Report',
    'order': 'Order',
    'notification': 'Notification',
  };
  return map[e] ?? e;
}
