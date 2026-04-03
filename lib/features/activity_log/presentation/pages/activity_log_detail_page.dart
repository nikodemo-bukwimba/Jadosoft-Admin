import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../data/datasources/activity_log_mock_datasource.dart';
import '../../domain/entities/activity_log_entity.dart';
import '../bloc/activity_log_bloc.dart';
import '../bloc/activity_log_event.dart';
import '../bloc/activity_log_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ActivityLogDetailPage — Full audit entry view
// Read-only. Shows actor, action, entity, smart snapshot, actor history.
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

// ─────────────────────────────────────────────────────────────────────────────
// Detail scaffold
// ─────────────────────────────────────────────────────────────────────────────

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

                // ── Entity snapshot — smart rendering ────────────────────
                if (log.entitySnapshot != null &&
                    log.entitySnapshot!.isNotEmpty) ...[
                  _SmartSnapshotCard(
                    snapshot: log.entitySnapshot!,
                    action: log.action,
                    entityType: log.entityType,
                  ),
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

                const SizedBox(height: 24),

                // ── Other activities by the same actor ───────────────────
                _ActorActivitiesPanel(currentLog: log),

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
// Smart Snapshot Card
// Renders the entity_snapshot with semantic context instead of raw JSON.
// ─────────────────────────────────────────────────────────────────────────────

class _SmartSnapshotCard extends StatefulWidget {
  final Map<String, dynamic> snapshot;
  final String action;
  final String entityType;
  const _SmartSnapshotCard({
    required this.snapshot,
    required this.action,
    required this.entityType,
  });
  @override
  State<_SmartSnapshotCard> createState() => _SmartSnapshotCardState();
}

class _SmartSnapshotCardState extends State<_SmartSnapshotCard> {
  bool _showRaw = false;

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
            // Header row
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
                // Toggle raw/pretty
                TextButton.icon(
                  onPressed: () => setState(() => _showRaw = !_showRaw),
                  icon: Icon(
                    _showRaw ? Icons.table_rows_outlined : Icons.code,
                    size: 14,
                  ),
                  label: Text(_showRaw ? 'Pretty' : 'Raw'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  tooltip: 'Copy snapshot',
                  onPressed: () {
                    final text = _prettyJson(widget.snapshot);
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
            const SizedBox(height: 12),
            if (_showRaw)
              _RawSnapshotView(snapshot: widget.snapshot)
            else
              _PrettySnapshotView(
                snapshot: widget.snapshot,
                action: widget.action,
                entityType: widget.entityType,
              ),
          ],
        ),
      ),
    );
  }

  String _prettyJson(Map<String, dynamic> m) {
    final buf = StringBuffer('{\n');
    for (final e in m.entries) {
      buf.write('  "${e.key}": ${_valStr(e.value)}\n');
    }
    buf.write('}');
    return buf.toString();
  }

  String _valStr(dynamic v) {
    if (v == null) return 'null';
    if (v is String) return '"$v"';
    if (v is List) return '[${v.map(_valStr).join(', ')}]';
    if (v is Map) return '{...}';
    return v.toString();
  }
}

// ── Pretty view ───────────────────────────────────────────────────────────────

class _PrettySnapshotView extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final String action;
  final String entityType;
  const _PrettySnapshotView({
    required this.snapshot,
    required this.action,
    required this.entityType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // ── Transition: from_status → to_status ──────────────────────────────
    if (snapshot.containsKey('from_status') &&
        snapshot.containsKey('to_status')) {
      return _buildTransitionView(context, theme, scheme);
    }

    // ── Field update: field + old_value + new_value ──────────────────────
    if (snapshot.containsKey('field') &&
        snapshot.containsKey('old_value') &&
        snapshot.containsKey('new_value')) {
      return _buildFieldUpdateView(context, theme, scheme);
    }

    // ── Auth/session ─────────────────────────────────────────────────────
    if (entityType == 'session') {
      return _buildSessionView(context, theme, scheme);
    }

    // ── Default: rich key-value with contextual icons ────────────────────
    return _buildKeyValueView(context, theme, scheme);
  }

  Widget _buildTransitionView(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    final from = snapshot['from_status']?.toString() ?? '';
    final to = snapshot['to_status']?.toString() ?? '';
    final extra = Map<String, dynamic>.from(snapshot)
      ..remove('from_status')
      ..remove('to_status');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status flow pill row
        Row(
          children: [
            _StatusChip(label: from, isNew: false),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                Icons.arrow_forward,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ),
            _StatusChip(label: to, isNew: true),
          ],
        ),
        if (extra.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...extra.entries.map(
            (e) => _KvRow(
              label: _humanKey(e.key),
              value: e.value,
              icon: _iconForKey(e.key),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFieldUpdateView(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    final field = snapshot['field']?.toString() ?? '';
    final oldVal = snapshot['old_value']?.toString() ?? '';
    final newVal = snapshot['new_value']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_outlined, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              'Field updated: ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              _humanKey(field),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ValueBox(
                label: 'Before',
                value: oldVal,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: _ValueBox(
                label: 'After',
                value: newVal,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionView(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: snapshot.entries.map((e) {
        return _KvRow(
          label: _humanKey(e.key),
          value: e.value,
          icon: e.key == 'ip'
              ? Icons.wifi
              : e.key == 'device'
              ? Icons.devices
              : e.key == 'duration_minutes'
              ? Icons.timer_outlined
              : Icons.info_outline,
        );
      }).toList(),
    );
  }

  Widget _buildKeyValueView(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: snapshot.entries
          .map(
            (e) => _KvRow(
              label: _humanKey(e.key),
              value: e.value,
              icon: _iconForKey(e.key),
            ),
          )
          .toList(),
    );
  }

  String _humanKey(String key) => key
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  IconData _iconForKey(String key) {
    switch (key) {
      case 'name':
      case 'officer':
      case 'recipient':
        return Icons.person_outline;
      case 'email':
        return Icons.email_outlined;
      case 'phone':
        return Icons.phone_outlined;
      case 'status':
        return Icons.circle_outlined;
      case 'role':
        return Icons.badge_outlined;
      case 'customer':
      case 'business_name':
      case 'customer_id':
        return Icons.store_outlined;
      case 'address':
        return Icons.location_on_outlined;
      case 'total':
        return Icons.payments_outlined;
      case 'channels':
        return Icons.campaign_outlined;
      case 'feedback':
      case 'reason':
        return Icons.comment_outlined;
      case 'date':
      case 'week':
        return Icons.calendar_today_outlined;
      case 'title':
        return Icons.title;
      case 'channel':
        return Icons.send_outlined;
      case 'items_count':
        return Icons.list_alt_outlined;
      case 'source':
        return Icons.input_outlined;
      case 'target_count':
        return Icons.people_outline;
      default:
        return Icons.label_outline;
    }
  }
}

// ── Raw view ──────────────────────────────────────────────────────────────────

class _RawSnapshotView extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  const _RawSnapshotView({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _prettyJson(snapshot),
        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }

  String _prettyJson(Map<String, dynamic> m) {
    final buf = StringBuffer('{\n');
    for (final e in m.entries) {
      buf.write('  "${e.key}": ${_valStr(e.value)}\n');
    }
    buf.write('}');
    return buf.toString();
  }

  String _valStr(dynamic v) {
    if (v == null) return 'null';
    if (v is String) return '"$v"';
    if (v is List) return '[${v.map(_valStr).join(', ')}]';
    if (v is Map) return '{...}';
    return v.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Actor Activities Panel — loads all logs, filters by actorId, excludes self
// ─────────────────────────────────────────────────────────────────────────────

class _ActorActivitiesPanel extends StatefulWidget {
  final ActivityLogEntity currentLog;
  const _ActorActivitiesPanel({required this.currentLog});
  @override
  State<_ActorActivitiesPanel> createState() => _ActorActivitiesPanelState();
}

class _ActorActivitiesPanelState extends State<_ActorActivitiesPanel> {
  late Future<List<ActivityLogEntity>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ActivityLogEntity>> _load() async {
    final all = await ActivityLogMockDataSource().getAll();
    return all
        .where(
          (e) =>
              e.actorId == widget.currentLog.actorId &&
              e.id != widget.currentLog.id,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FutureBuilder<List<ActivityLogEntity>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final others = snap.data!;
        if (others.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Other activities by ${widget.currentLog.actorName}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${others.length} entries',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...others.map((log) => _ActorActivityTile(log: log)),
          ],
        );
      },
    );
  }
}

class _ActorActivityTile extends StatelessWidget {
  final ActivityLogEntity log;
  const _ActorActivityTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (color, icon) = _resolveAction(log.action);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () =>
            context.pushReplacement(AppRouter.activityLogDetailPath(log.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _labelAction(log.action),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _labelEntity(log.entityType),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${log.entityId} · ${_formatRelative(log.occurredAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
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
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isNew;
  const _StatusChip({required this.label, required this.isNew});

  @override
  Widget build(BuildContext context) {
    final color = isNew ? _colorForStatus(label) : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _colorForStatus(String s) {
    switch (s) {
      case 'active':
      case 'approved':
      case 'delivered':
      case 'reviewed':
      case 'featured':
        return Colors.green;
      case 'suspended':
      case 'rejected':
      case 'failed':
      case 'flagged':
        return Colors.red;
      case 'pending':
      case 'draft':
      case 'submitted':
      case 'queued':
        return Colors.orange;
      case 'shipped':
      case 'confirmed':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }
}

class _ValueBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ValueBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final IconData icon;
  const _KvRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final display = _display(value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              display,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _display(dynamic v) {
    if (v == null) return '—';
    if (v is List) return v.join(', ');
    if (v is double) return v.toStringAsFixed(2);
    return v.toString();
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
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _formatFull(DateTime dt) {
  const months = [
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

String _formatRelative(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
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
