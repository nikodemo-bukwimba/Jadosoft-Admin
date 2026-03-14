import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/promotion_entity.dart';
import '../../domain/value_objects/promotion_status.dart';
import '../bloc/promotion_bloc.dart';
import '../bloc/promotion_event.dart';
import '../bloc/promotion_state.dart';
import '../widgets/promotion_card_tile.dart';
import '../widgets/promotion_tiles.dart';

enum _ViewMode { cards, list, table }

class PromotionListPage extends StatefulWidget {
  const PromotionListPage({super.key});

  @override
  State<PromotionListPage> createState() => _PromotionListPageState();
}

class _PromotionListPageState extends State<PromotionListPage> {
  _ViewMode _viewMode = _ViewMode.cards;
  String _search = '';
  PromotionStatus? _filterStatus;

  List<PromotionEntity> _apply(List<PromotionEntity> items) {
    var r = items;
    if (_filterStatus != null) {
      r = r
          .where((e) =>
              PromotionStatusX.fromString(e.status) == _filterStatus)
          .toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      r = r
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              (e.description ?? '').toLowerCase().contains(q))
          .toList();
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<PromotionBloc, PromotionState>(
      listener: (context, state) {
        if (state is PromotionOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          context
              .read<PromotionBloc>()
              .add(PromotionLoadAllRequested());
        }
        if (state is PromotionFailure) {
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
          title: const Text('Promotions'),
          centerTitle: false,
          actions: [
            PopupMenuButton<PromotionStatus?>(
              icon: Badge(
                isLabelVisible: _filterStatus != null,
                child: const Icon(Icons.filter_list),
              ),
              tooltip: 'Filter by status',
              onSelected: (v) => setState(() => _filterStatus = v),
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: null, child: Text('All statuses')),
                ...PromotionStatus.values.map((s) => PopupMenuItem(
                      value: s,
                      child: Text(s.displayName),
                    )),
              ],
            ),
            _ViewToggle(
                current: _viewMode,
                onChanged: (v) => setState(() => _viewMode = v)),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/promotions/create'),
          icon: const Icon(Icons.add),
          label: const Text('New Promotion'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SearchBar(
                hintText: 'Search promotions…',
                leading: const Icon(Icons.search, size: 20),
                padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16)),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            if (_filterStatus != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(_filterStatus!.displayName),
                      selected: true,
                      onSelected: (_) =>
                          setState(() => _filterStatus = null),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () =>
                          setState(() => _filterStatus = null),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: BlocBuilder<PromotionBloc, PromotionState>(
                builder: (context, state) {
                  if (state is PromotionLoading) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  if (state is PromotionFailure) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => context
                          .read<PromotionBloc>()
                          .add(PromotionLoadAllRequested()),
                    );
                  }
                  if (state is PromotionEmpty) {
                    return const _EmptyView(filtered: false);
                  }
                  if (state is PromotionListLoaded) {
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

  Widget _buildContent(List<PromotionEntity> items, ThemeData theme) {
    switch (_viewMode) {
      case _ViewMode.cards:
        return RefreshIndicator(
          onRefresh: () async => context
              .read<PromotionBloc>()
              .add(PromotionLoadAllRequested()),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: items.length,
            itemBuilder: (_, i) => PromotionCardTile(item: items[i]),
          ),
        );
      case _ViewMode.list:
        return RefreshIndicator(
          onRefresh: () async => context
              .read<PromotionBloc>()
              .add(PromotionLoadAllRequested()),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 80, top: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
                height: 1, color: theme.colorScheme.outlineVariant),
            itemBuilder: (_, i) => PromotionListRow(item: items[i]),
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
                  PromotionTableRow.header(),
                  ...items.map((e) => PromotionTableRow(item: e)),
                ],
              ),
            ),
          ),
        );
    }
  }
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
          Icon(Icons.campaign_outlined,
              size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            filtered
                ? 'No promotions match your filter'
                : 'No promotions yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first promotion.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant,
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
          FilledButton.tonal(
              onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}