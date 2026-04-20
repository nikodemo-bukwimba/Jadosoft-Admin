//Admin app
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/daily_report_entity.dart';
import '../../domain/value_objects/daily_report_status.dart';
import '../bloc/daily_report_bloc.dart';
import '../bloc/daily_report_event.dart';
import '../bloc/daily_report_state.dart';
import '../widgets/daily_report_card_tile.dart';
import '../widgets/daily_report_list_row.dart';

enum _DailyReportViewMode { cards, list, table }

class DailyReportListPage extends StatefulWidget {
  const DailyReportListPage({super.key});

  @override
  State<DailyReportListPage> createState() => _DailyReportListPageState();
}

class _DailyReportListPageState extends State<DailyReportListPage> {
  _DailyReportViewMode _viewMode = _DailyReportViewMode.cards;
  String _searchQuery = '';
  DailyReportStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    // Always reload when this page is created or returned to
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DailyReportBloc>().add(DailyReportLoadAllRequested());
      }
    });
  }

  List<DailyReportEntity> _applyFilters(List<DailyReportEntity> items) {
    var result = items;
    if (_filterStatus != null) {
      result = result
          .where(
            (e) => DailyReportStatusX.fromString(e.status) == _filterStatus,
          )
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (e) =>
                (e.officerName ?? '').toLowerCase().contains(q) ||
                (e.reportNumber ?? '').toLowerCase().contains(q) ||
                (e.keyOutcomes ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    result.sort((a, b) => b.reportDate.compareTo(a.reportDate));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reports'),
        centerTitle: false,
        actions: [
          PopupMenuButton<DailyReportStatus?>(
            icon: Badge(
              isLabelVisible: _filterStatus != null,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filter by status',
            onSelected: (value) => setState(() => _filterStatus = value),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All statuses')),
              ...DailyReportStatus.values.map(
                (s) => PopupMenuItem(value: s, child: Text(s.displayName)),
              ),
            ],
          ),
          _ViewToggle(
            current: _viewMode,
            onChanged: (v) => setState(() => _viewMode = v),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              hintText: 'Search by officer, report number…',
              leading: const Icon(Icons.search, size: 20),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          if (_filterStatus != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(_filterStatus!.displayName),
                    selected: true,
                    onSelected: (_) => setState(() => _filterStatus = null),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _filterStatus = null),
                  ),
                ],
              ),
            ),
          Expanded(
            child: BlocBuilder<DailyReportBloc, DailyReportState>(
              builder: (context, state) {
                if (state is DailyReportLoading ||
                    state is DailyReportInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is DailyReportFailure) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () => context.read<DailyReportBloc>().add(
                      DailyReportLoadAllRequested(),
                    ),
                  );
                }
                if (state is DailyReportEmpty) {
                  return _EmptyView(filterActive: _filterStatus != null);
                }
                if (state is DailyReportListLoaded) {
                  final filtered = _applyFilters(state.items);
                  if (filtered.isEmpty) {
                    return _EmptyView(filterActive: true);
                  }
                  return _buildContent(filtered, theme);
                }
                // Any other state (e.g. DetailLoaded briefly) — show spinner
                // initState will have already dispatched LoadAll
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<DailyReportEntity> items, ThemeData theme) {
    switch (_viewMode) {
      case _DailyReportViewMode.cards:
        return RefreshIndicator(
          onRefresh: () async => context.read<DailyReportBloc>().add(
            DailyReportLoadAllRequested(),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: items.length,
            itemBuilder: (_, i) => DailyReportCardTile(item: items[i]),
          ),
        );

      case _DailyReportViewMode.list:
        return RefreshIndicator(
          onRefresh: () async => context.read<DailyReportBloc>().add(
            DailyReportLoadAllRequested(),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
            itemBuilder: (_, i) => DailyReportListRow(item: items[i]),
          ),
        );

      case _DailyReportViewMode.table:
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DailyReportTableRow.header(context),
                  ...items.map((item) => DailyReportTableRow(item: item)),
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
  final _DailyReportViewMode current;
  final ValueChanged<_DailyReportViewMode> onChanged;

  const _ViewToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(context, _DailyReportViewMode.cards, Icons.view_agenda_outlined),
        _btn(context, _DailyReportViewMode.list, Icons.format_list_bulleted),
        _btn(context, _DailyReportViewMode.table, Icons.table_rows_outlined),
      ],
    );
  }

  Widget _btn(BuildContext ctx, _DailyReportViewMode mode, IconData icon) {
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

// ─── Empty & Error Views ───────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final bool filterActive;
  const _EmptyView({required this.filterActive});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            filterActive
                ? 'No reports match this filter'
                : 'No daily reports yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Reports submitted by officers will appear here.',
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
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
