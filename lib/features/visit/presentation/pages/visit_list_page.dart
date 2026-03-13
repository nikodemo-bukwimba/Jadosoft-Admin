import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/visit_entity.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';
import '../widgets/visit_card_tile.dart';
import '../widgets/visit_list_row.dart';

enum _ViewMode { cards, list, details }

class VisitListPage extends StatefulWidget {
  const VisitListPage({super.key});
  @override
  State<VisitListPage> createState() => _VisitListPageState();
}

class _VisitListPageState extends State<VisitListPage> {
  _ViewMode _viewMode = _ViewMode.cards;

  @override
  void initState() { super.initState(); context.read<VisitBloc>().add(VisitLoadAllRequested()); }

  void _nav(String id) => context.push(AppRouter.visitDetailPath(id));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Visit Monitoring'), actions: [_toggle(scheme), const SizedBox(width: 8)]),
      body: BlocConsumer<VisitBloc, VisitState>(
        listener: (c, s) {
          if (s is VisitOperationSuccess) { ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s.message))); c.read<VisitBloc>().add(VisitLoadAllRequested()); }
          if (s is VisitFailure) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s.message), backgroundColor: scheme.error));
        },
        builder: (c, s) {
          if (s is VisitLoading || s is VisitInitial) return const Center(child: CircularProgressIndicator());
          if (s is VisitEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.location_off_outlined, size: 64, color: scheme.outlineVariant), const SizedBox(height: 16),
            Text('No visits recorded yet.', style: Theme.of(c).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
          ]));
          if (s is VisitFailure) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error), const SizedBox(height: 16), Text(s.message),
            const SizedBox(height: 16), FilledButton.icon(onPressed: () => c.read<VisitBloc>().add(VisitLoadAllRequested()), icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ]));
          if (s is VisitListLoaded) return RefreshIndicator(
            onRefresh: () async => c.read<VisitBloc>().add(VisitLoadAllRequested()), child: _buildView(s.items));
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _toggle(ColorScheme scheme) {
    const m = [(_ViewMode.cards, Icons.dashboard_outlined, 'Cards'), (_ViewMode.list, Icons.view_list_outlined, 'List'), (_ViewMode.details, Icons.table_rows_outlined, 'Details')];
    return Container(decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.all(2),
      child: Row(mainAxisSize: MainAxisSize.min, children: m.map((e) {
        final sel = e.$1 == _viewMode;
        return Tooltip(message: e.$3, child: GestureDetector(onTap: () => setState(() => _viewMode = e.$1),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: sel ? scheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
            child: Icon(e.$2, size: 18, color: sel ? scheme.onPrimary : scheme.onSurfaceVariant))));
      }).toList()));
  }

  Widget _buildView(List<VisitEntity> items) => switch (_viewMode) {
    _ViewMode.cards => _cards(items), _ViewMode.list => _list(items), _ViewMode.details => _details(items),
  };

  Widget _cards(List<VisitEntity> items) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1024) return GridView.builder(padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: w >= 1200 ? 3 : 2, childAspectRatio: 2.2, crossAxisSpacing: 12, mainAxisSpacing: 0),
      itemCount: items.length, itemBuilder: (_, i) => VisitCardTile(item: items[i], onTap: () => _nav(items[i].id)));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length,
      itemBuilder: (_, i) => VisitCardTile(item: items[i], onTap: () => _nav(items[i].id)));
  }

  Widget _list(List<VisitEntity> items) => ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    itemCount: items.length, itemBuilder: (_, i) => VisitListRow(item: items[i], onTap: () => _nav(items[i].id)));

  Widget _details(List<VisitEntity> items) {
    final scheme = Theme.of(context).colorScheme;
    final hdr = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: scheme.onSurfaceVariant);
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
        child: Row(children: [const SizedBox(width: 40), const SizedBox(width: 12), Expanded(flex: 3, child: Text('Business', style: hdr)),
          Expanded(flex: 2, child: Text('Date', style: hdr)), Expanded(flex: 1, child: Text('Status', style: hdr))])),
      ...items.asMap().entries.map((e) => VisitTableRow(item: e.value, isLast: e.key == items.length - 1, onTap: () => _nav(e.value.id))),
    ]));
  }
}