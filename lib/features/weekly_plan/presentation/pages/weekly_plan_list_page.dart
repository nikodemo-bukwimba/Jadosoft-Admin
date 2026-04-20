import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/weekly_plan_entity.dart';
import '../bloc/weekly_plan_bloc.dart';
import '../bloc/weekly_plan_event.dart';
import '../bloc/weekly_plan_state.dart';
import '../widgets/weekly_plan_tiles.dart';

enum _ViewMode { cards, list, details }

class WeeklyPlanListPage extends StatefulWidget {
  const WeeklyPlanListPage({super.key});
  @override
  State<WeeklyPlanListPage> createState() => _WeeklyPlanListPageState();
}

class _WeeklyPlanListPageState extends State<WeeklyPlanListPage> {
  _ViewMode _viewMode = _ViewMode.cards;

  // In initState():
  @override
  void initState() {
    super.initState();
    context.read<WeeklyPlanBloc>().add(WeeklyPlanLoadAllRequested());
  }

  void _nav(String id) => context.push(AppRouter.weeklyPlanDetailPath(id));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Plans'),
        actions: [_toggle(scheme), const SizedBox(width: 8)],
      ),
      body: BlocConsumer<WeeklyPlanBloc, WeeklyPlanState>(
        listener: (c, s) {
          if (s is WeeklyPlanOperationSuccess) {
            ScaffoldMessenger.of(
              c,
            ).showSnackBar(SnackBar(content: Text(s.message)));
            c.read<WeeklyPlanBloc>().add(WeeklyPlanLoadAllRequested());
          }
          if (s is WeeklyPlanFailure)
            ScaffoldMessenger.of(c).showSnackBar(
              SnackBar(content: Text(s.message), backgroundColor: scheme.error),
            );
        },
        builder: (c, s) {
          if (s is WeeklyPlanLoading || s is WeeklyPlanInitial)
            return const Center(child: CircularProgressIndicator());
          if (s is WeeklyPlanEmpty)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: scheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No weekly plans submitted yet.',
                    style: Theme.of(c).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          if (s is WeeklyPlanFailure)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: scheme.error),
                  const SizedBox(height: 16),
                  Text(s.message),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => c.read<WeeklyPlanBloc>().add(
                      WeeklyPlanLoadAllRequested(),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          if (s is WeeklyPlanListLoaded)
            return RefreshIndicator(
              onRefresh: () async =>
                  c.read<WeeklyPlanBloc>().add(WeeklyPlanLoadAllRequested()),
              child: _buildView(s.items),
            );
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _toggle(ColorScheme scheme) {
    const m = [
      (_ViewMode.cards, Icons.dashboard_outlined, 'Cards'),
      (_ViewMode.list, Icons.view_list_outlined, 'List'),
      (_ViewMode.details, Icons.table_rows_outlined, 'Details'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: m.map((e) {
          final sel = e.$1 == _viewMode;
          return Tooltip(
            message: e.$3,
            child: GestureDetector(
              onTap: () => setState(() => _viewMode = e.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: sel ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  e.$2,
                  size: 18,
                  color: sel ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildView(List<WeeklyPlanEntity> items) => switch (_viewMode) {
    _ViewMode.cards => _cards(items),
    _ViewMode.list => _list(items),
    _ViewMode.details => _details(items),
  };

  Widget _cards(List<WeeklyPlanEntity> items) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1024)
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: w >= 1200 ? 3 : 2,
          childAspectRatio: 2.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 0,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) =>
            WeeklyPlanCardTile(item: items[i], onTap: () => _nav(items[i].id)),
      );
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) =>
          WeeklyPlanCardTile(item: items[i], onTap: () => _nav(items[i].id)),
    );
  }

  Widget _list(List<WeeklyPlanEntity> items) => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    itemCount: items.length,
    itemBuilder: (_, i) =>
        WeeklyPlanListRow(item: items[i], onTap: () => _nav(items[i].id)),
  );

  Widget _details(List<WeeklyPlanEntity> items) {
    final scheme = Theme.of(context).colorScheme;
    final hdr = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: scheme.onSurfaceVariant,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: Text('Week', style: hdr)),
                Expanded(flex: 1, child: Text('Targets', style: hdr)),
                Expanded(flex: 1, child: Text('Status', style: hdr)),
              ],
            ),
          ),
          ...items.asMap().entries.map(
            (e) => WeeklyPlanTableRow(
              item: e.value,
              isLast: e.key == items.length - 1,
              onTap: () => _nav(e.value.id),
            ),
          ),
        ],
      ),
    );
  }
}
