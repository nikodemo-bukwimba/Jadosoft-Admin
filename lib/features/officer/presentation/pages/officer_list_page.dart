import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/officer_entity.dart';
import '../bloc/officer_bloc.dart';
import '../bloc/officer_event.dart';
import '../bloc/officer_state.dart';
import '../widgets/officer_card_tile.dart';
import '../widgets/officer_list_row.dart';
import '../widgets/officer_table_row.dart';

enum _ViewMode { cards, list, details }

class OfficerListPage extends StatefulWidget {
  const OfficerListPage({super.key});
  @override
  State<OfficerListPage> createState() => _OfficerListPageState();
}

class _OfficerListPageState extends State<OfficerListPage> {
  _ViewMode _viewMode = _ViewMode.cards;

  @override
  void initState() { super.initState(); context.read<OfficerBloc>().add(OfficerLoadAllRequested()); }

  void _navigateToDetail(String userId) => context.push(AppRouter.officerDetailPath(userId));
  void _deleteOfficer(String userId, String name) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Remove Officer?'), content: Text('Remove "$name"? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
      ],
    ));
    if (confirmed == true && mounted) context.read<OfficerBloc>().add(OfficerDeleteRequested(userId));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Marketing Officers'), actions: [_buildViewToggle(scheme), const SizedBox(width: 8)]),
      floatingActionButton: FloatingActionButton(onPressed: () => context.push(AppRouter.officerCreate), child: const Icon(Icons.person_add)),
      body: BlocConsumer<OfficerBloc, OfficerState>(
        listener: (context, state) {
          if (state is OfficerOperationSuccess) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            context.read<OfficerBloc>().add(OfficerLoadAllRequested()); }
          if (state is OfficerFailure) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: scheme.error));
        },
        builder: (context, state) {
          if (state is OfficerLoading || state is OfficerInitial) return const Center(child: CircularProgressIndicator());
          if (state is OfficerEmpty) return _buildEmpty(context, scheme);
          if (state is OfficerFailure) return _buildError(context, scheme, state.message);
          if (state is OfficerListLoaded) return RefreshIndicator(
            onRefresh: () async => context.read<OfficerBloc>().add(OfficerLoadAllRequested()),
            child: _buildView(state.items));
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildViewToggle(ColorScheme scheme) {
    const modes = [(_ViewMode.cards, Icons.dashboard_outlined, 'Cards'), (_ViewMode.list, Icons.view_list_outlined, 'List'),
      (_ViewMode.details, Icons.table_rows_outlined, 'Details')];
    return Container(decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(2),
      child: Row(mainAxisSize: MainAxisSize.min, children: modes.map((m) {
        final selected = m.$1 == _viewMode;
        return Tooltip(message: m.$3, child: GestureDetector(onTap: () => setState(() => _viewMode = m.$1),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: selected ? scheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
            child: Icon(m.$2, size: 18, color: selected ? scheme.onPrimary : scheme.onSurfaceVariant))));
      }).toList()));
  }

  Widget _buildView(List<OfficerEntity> items) => switch (_viewMode) {
    _ViewMode.cards => _buildCardsView(items), _ViewMode.list => _buildListView(items), _ViewMode.details => _buildDetailsView(items),
  };

  Widget _buildCardsView(List<OfficerEntity> items) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return GridView.builder(padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: width >= 1200 ? 3 : 2, childAspectRatio: 2.4, crossAxisSpacing: 12, mainAxisSpacing: 0),
      itemCount: items.length, itemBuilder: (_, i) => OfficerCardTile(item: items[i],
        onTap: () => _navigateToDetail(items[i].userId), onDelete: () => _deleteOfficer(items[i].userId, items[i].displayName)));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length,
      itemBuilder: (_, i) => OfficerCardTile(item: items[i],
        onTap: () => _navigateToDetail(items[i].userId), onDelete: () => _deleteOfficer(items[i].userId, items[i].displayName)));
  }

  Widget _buildListView(List<OfficerEntity> items) => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), itemCount: items.length,
    itemBuilder: (_, i) => OfficerListRow(item: items[i],
      onTap: () => _navigateToDetail(items[i].userId), onDelete: () => _deleteOfficer(items[i].userId, items[i].displayName)));

  Widget _buildDetailsView(List<OfficerEntity> items) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
        child: Row(children: [const SizedBox(width: 44), const SizedBox(width: 12),
          Expanded(flex: 3, child: Text('Name', style: _headerStyle)), Expanded(flex: 2, child: Text('Role', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Phone', style: _headerStyle)), Expanded(flex: 1, child: Text('Status', style: _headerStyle)),
          const SizedBox(width: 40)])),
      ...items.asMap().entries.map((e) => OfficerTableRow(item: e.value, isLast: e.key == items.length - 1,
        onTap: () => _navigateToDetail(e.value.userId), onDelete: () => _deleteOfficer(e.value.userId, e.value.displayName))),
    ]));
  }

  TextStyle get _headerStyle => TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Theme.of(context).colorScheme.onSurfaceVariant);

  Widget _buildEmpty(BuildContext context, ColorScheme scheme) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.people_outline, size: 64, color: scheme.outlineVariant), const SizedBox(height: 16),
    Text('No officers yet.', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
    const SizedBox(height: 4), Text('Tap + to add your first officer.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
  ]));

  Widget _buildError(BuildContext context, ColorScheme scheme, String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.error_outline, size: 48, color: scheme.error), const SizedBox(height: 16), Text(msg, textAlign: TextAlign.center),
    const SizedBox(height: 16), FilledButton.icon(onPressed: () => context.read<OfficerBloc>().add(OfficerLoadAllRequested()),
      icon: const Icon(Icons.refresh), label: const Text('Retry')),
  ]));
}
