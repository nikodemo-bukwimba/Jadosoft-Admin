// notification_list_page.dart
// ─────────────────────────────────────────────────────────────
// Delivery Center — lists ProductUpdateDelivery records from
// the backend NotificationController.
//
// Filtering is done server-side via query params.
// No mock data. Status/channel filter chips fire
// NotificationFilterChanged → bloc re-fetches from API.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/value_objects/notification_status.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notification_card_tile.dart';
import '../widgets/notification_tiles.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  String? _statusFilter;
  String? _channelFilter;

  static const _statusOptions = [
    (label: 'All', value: null),
    (label: 'Queued', value: 'queued'),
    (label: 'Sent', value: 'sent'),
    (label: 'Delivered', value: 'delivered'),
    (label: 'Failed', value: 'failed'),
  ];

  static const _channelOptions = [
    (label: 'All', value: null),
    (label: 'SMS', value: 'sms'),
    (label: 'WhatsApp', value: 'whatsapp'),
    (label: 'In-App', value: 'in_app'),
  ];

  void _applyFilter({String? status, String? channel}) {
    setState(() {
      _statusFilter = status;
      _channelFilter = channel;
    });
    context.read<NotificationBloc>().add(
      NotificationFilterChanged(status: status, channel: channel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Center'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => context.read<NotificationBloc>().add(
              NotificationLoadAllRequested(
                status: _statusFilter,
                channel: _channelFilter,
              ),
            ),
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── KPI Banner ────────────────────────────────────
          BlocBuilder<NotificationBloc, NotificationState>(
            buildWhen: (_, s) =>
                s is NotificationListLoaded || s is NotificationEmpty,
            builder: (context, state) {
              if (state is! NotificationListLoaded) {
                return const SizedBox.shrink();
              }
              return _KpiBanner(items: state.items);
            },
          ),

          // ── Filter Bar ────────────────────────────────────
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusOptions.map((opt) {
                      final selected = _statusFilter == opt.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(opt.label),
                          selected: selected,
                          onSelected: (_) => _applyFilter(
                            status: opt.value,
                            channel: _channelFilter,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _channelOptions.map((opt) {
                      final selected = _channelFilter == opt.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(opt.label),
                          selected: selected,
                          onSelected: (_) => _applyFilter(
                            status: _statusFilter,
                            channel: opt.value,
                          ),
                          visualDensity: VisualDensity.compact,
                          avatar: opt.value != null
                              ? Icon(_channelIcon(opt.value!), size: 14)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Content ───────────────────────────────────────
          Expanded(
            child: BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state is NotificationLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is NotificationFailure) {
                  return _ErrorState(
                    message: state.message,
                    onRetry: () => context.read<NotificationBloc>().add(
                      NotificationLoadAllRequested(
                        status: _statusFilter,
                        channel: _channelFilter,
                      ),
                    ),
                  );
                }
                if (state is NotificationEmpty) {
                  return const _EmptyState();
                }
                if (state is NotificationListLoaded) {
                  if (isWide) {
                    return _TableView(items: state.items);
                  }
                  return _MobileListView(items: state.items);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _channelIcon(String channel) => switch (channel) {
    'sms' => Icons.sms_outlined,
    'whatsapp' => Icons.chat_outlined,
    _ => Icons.notifications_outlined,
  };
}

// ─── KPI Banner ────────────────────────────────────────────────────────────

class _KpiBanner extends StatelessWidget {
  final List<NotificationEntity> items;
  const _KpiBanner({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = items.length;
    final delivered = items
        .where(
          (e) =>
              NotificationStatusX.fromString(e.status) ==
              NotificationStatus.delivered,
        )
        .length;
    final failed = items
        .where(
          (e) =>
              NotificationStatusX.fromString(e.status) ==
              NotificationStatus.failed,
        )
        .length;
    final queued = items
        .where(
          (e) =>
              NotificationStatusX.fromString(e.status) ==
              NotificationStatus.queued,
        )
        .length;

    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _KpiChip(
            label: 'Total',
            value: '$total',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          _KpiChip(
            label: 'Delivered',
            value: '$delivered',
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          _KpiChip(label: 'Failed', value: '$failed', color: Colors.red),
          const SizedBox(width: 12),
          _KpiChip(label: 'Queued', value: '$queued', color: Colors.orange),
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile List View ──────────────────────────────────────────────────────

class _MobileListView extends StatelessWidget {
  final List<NotificationEntity> items;
  const _MobileListView({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, i) => NotificationCardTile(item: items[i]),
    );
  }
}

// ─── Table View ────────────────────────────────────────────────────────────

class _TableView extends StatelessWidget {
  final List<NotificationEntity> items;
  const _TableView({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const NotificationTableRow.header(),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => NotificationTableRow(item: items[i]),
          ),
        ),
      ],
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No deliveries found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try changing the filters or publish a promotion.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error State ───────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
