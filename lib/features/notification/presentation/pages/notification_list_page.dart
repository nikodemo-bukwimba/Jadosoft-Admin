import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/value_objects/notification_status.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notification_card_tile.dart';
import '../widgets/notification_list_row.dart';

enum _ViewMode { cards, list, table }

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  _ViewMode _viewMode = _ViewMode.cards;
  String _search = '';
  NotificationStatus? _filterStatus;
  String? _filterChannel;

  static const _channels = ['sms', 'whatsapp', 'in_app'];

  List<NotificationEntity> _apply(List<NotificationEntity> items) {
    var r = items;
    if (_filterStatus != null) {
      r = r
          .where((e) =>
              NotificationStatusX.fromString(e.status) == _filterStatus)
          .toList();
    }
    if (_filterChannel != null) {
      r = r.where((e) => e.channel == _filterChannel).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      r = r
          .where((e) =>
              e.recipientId.toLowerCase().contains(q) ||
              e.content.toLowerCase().contains(q) ||
              (e.templateId ?? '').toLowerCase().contains(q))
          .toList();
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          context
              .read<NotificationBloc>()
              .add(NotificationLoadAllRequested());
        }
        if (state is NotificationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          centerTitle: false,
          actions: [
            // Status filter
            PopupMenuButton<NotificationStatus?>(
              icon: Badge(
                isLabelVisible: _filterStatus != null,
                child: const Icon(Icons.filter_list),
              ),
              tooltip: 'Filter by status',
              onSelected: (v) => setState(() => _filterStatus = v),
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('All statuses')),
                ...NotificationStatus.values.map((s) => PopupMenuItem(
                      value: s,
                      child: Text(s.displayName),
                    )),
              ],
            ),
            // Channel filter
            PopupMenuButton<String?>(
              icon: Badge(
                isLabelVisible: _filterChannel != null,
                child: const Icon(Icons.cell_tower_outlined),
              ),
              tooltip: 'Filter by channel',
              onSelected: (v) => setState(() => _filterChannel = v),
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('All channels')),
                ..._channels.map((c) => PopupMenuItem(
                      value: c,
                      child: Text(_channelLabel(c)),
                    )),
              ],
            ),
            // View toggle
            _ViewToggle(
                current: _viewMode,
                onChanged: (v) => setState(() => _viewMode = v)),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SearchBar(
                hintText: 'Search by recipient, content…',
                leading: const Icon(Icons.search, size: 20),
                padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16)),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            // Active filter chips
            if (_filterStatus != null || _filterChannel != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    if (_filterStatus != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_filterStatus!.displayName),
                          selected: true,
                          onSelected: (_) =>
                              setState(() => _filterStatus = null),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () =>
                              setState(() => _filterStatus = null),
                        ),
                      ),
                    if (_filterChannel != null)
                      FilterChip(
                        label: Text(_channelLabel(_filterChannel!)),
                        selected: true,
                        onSelected: (_) =>
                            setState(() => _filterChannel = null),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () =>
                            setState(() => _filterChannel = null),
                      ),
                  ],
                ),
              ),
            // Content
            Expanded(
              child: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  if (state is NotificationLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is NotificationFailure) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => context
                          .read<NotificationBloc>()
                          .add(NotificationLoadAllRequested()),
                    );
                  }
                  if (state is NotificationEmpty) {
                    return const _EmptyView(filtered: false);
                  }
                  if (state is NotificationListLoaded) {
                    final items = _apply(state.items);
                    if (items.isEmpty) {
                      return const _EmptyView(filtered: true);
                    }
                    return _buildContent(items, theme);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<NotificationEntity> items, ThemeData theme) {
    switch (_viewMode) {
      case _ViewMode.cards:
        return RefreshIndicator(
          onRefresh: () async => context
              .read<NotificationBloc>()
              .add(NotificationLoadAllRequested()),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: items.length,
            itemBuilder: (_, i) => NotificationCardTile(item: items[i]),
          ),
        );

      case _ViewMode.list:
        return RefreshIndicator(
          onRefresh: () async => context
              .read<NotificationBloc>()
              .add(NotificationLoadAllRequested()),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
            itemBuilder: (_, i) => NotificationListRow(item: items[i]),
          ),
        );

      case _ViewMode.table:
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NotificationTableRow.header(),
                  ...items.map((e) => NotificationTableRow(item: e)),
                ],
              ),
            ),
          ),
        );
    }
  }

  String _channelLabel(String c) => switch (c) {
        'sms' => 'SMS',
        'whatsapp' => 'WhatsApp',
        'in_app' => 'In-App',
        _ => c,
      };
}

// ─── View Toggle ───────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final _ViewMode current;
  final ValueChanged<_ViewMode> onChanged;
  const _ViewToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(context, _ViewMode.cards, Icons.view_agenda_outlined),
        _btn(context, _ViewMode.list, Icons.format_list_bulleted),
        _btn(context, _ViewMode.table, Icons.table_rows_outlined),
      ],
    );
  }

  Widget _btn(BuildContext ctx, _ViewMode mode, IconData icon) {
    final selected = current == mode;
    return IconButton(
      icon: Icon(icon),
      color: selected
          ? Theme.of(ctx).colorScheme.primary
          : Theme.of(ctx).colorScheme.outline,
      iconSize: 20,
      onPressed: () => onChanged(mode),
      tooltip: mode.name,
    );
  }
}

// ─── Empty & Error ─────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final bool filtered;
  const _EmptyView({required this.filtered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            filtered
                ? 'No notifications match your filter'
                : 'No notifications yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'System notifications will appear here.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}