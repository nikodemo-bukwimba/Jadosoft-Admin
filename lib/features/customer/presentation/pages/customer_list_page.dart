import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/customer_entity.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../widgets/customer_card_tile.dart';
import '../widgets/customer_list_row.dart';
import '../widgets/customer_table_row.dart';

enum _ViewMode { cards, list, details }

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});
  @override State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  _ViewMode _viewMode = _ViewMode.cards;

  @override void initState() { super.initState(); context.read<CustomerBloc>().add(CustomerLoadAllRequested()); }
  void _navigateToDetail(String id) => context.push(AppRouter.customerDetailPath(id));
  void _deleteCustomer(String id, String name) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dc) => AlertDialog(
      title: const Text('Delete Customer?'), content: Text('Remove "$name"? This cannot be undone.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dc, false), child: const Text('Cancel')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(dc, true), child: const Text('Delete'))]));
    if (confirmed == true && mounted) { context.read<CustomerBloc>().add(CustomerDeleteRequested(id)); }
  }

  @override Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Customers'), actions: [_buildViewToggle(scheme), const SizedBox(width: 8)]),
      floatingActionButton: FloatingActionButton(onPressed: () => context.push(AppRouter.customerCreate), child: const Icon(Icons.store_outlined)),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            context.read<CustomerBloc>().add(CustomerLoadAllRequested());
          }
          if (state is CustomerFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: scheme.error));
          }
        },
        builder: (context, state) {
          if (state is CustomerLoading || state is CustomerInitial) return const Center(child: CircularProgressIndicator());
          if (state is CustomerEmpty) return _buildEmpty(context, scheme);
          if (state is CustomerFailure) return _buildError(context, scheme, state.message);
          if (state is CustomerListLoaded) return RefreshIndicator(
            onRefresh: () async => context.read<CustomerBloc>().add(CustomerLoadAllRequested()),
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
      padding: const EdgeInsets.all(2), child: Row(mainAxisSize: MainAxisSize.min, children: modes.map((m) {
        final sel = m.$1 == _viewMode;
        return Tooltip(message: m.$3, child: GestureDetector(onTap: () => setState(() => _viewMode = m.$1),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: sel ? scheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
            child: Icon(m.$2, size: 18, color: sel ? scheme.onPrimary : scheme.onSurfaceVariant))));
      }).toList()));
  }

  Widget _buildView(List<CustomerEntity> items) => switch (_viewMode) {
    _ViewMode.cards => _buildCardsView(items), _ViewMode.list => _buildListView(items), _ViewMode.details => _buildDetailsView(items),
  };

  Widget _buildCardsView(List<CustomerEntity> items) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1024) return GridView.builder(padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: w >= 1200 ? 3 : 2, childAspectRatio: 2.2, crossAxisSpacing: 12, mainAxisSpacing: 0),
      itemCount: items.length, itemBuilder: (_, i) => CustomerCardTile(item: items[i],
        onTap: () => _navigateToDetail(items[i].id), onDelete: () => _deleteCustomer(items[i].id, items[i].name)));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length,
      itemBuilder: (_, i) => CustomerCardTile(item: items[i],
        onTap: () => _navigateToDetail(items[i].id), onDelete: () => _deleteCustomer(items[i].id, items[i].name)));
  }

  Widget _buildListView(List<CustomerEntity> items) => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), itemCount: items.length,
    itemBuilder: (_, i) => CustomerListRow(item: items[i],
      onTap: () => _navigateToDetail(items[i].id), onDelete: () => _deleteCustomer(items[i].id, items[i].name)));

  Widget _buildDetailsView(List<CustomerEntity> items) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
        child: Row(children: [const SizedBox(width: 44), const SizedBox(width: 12),
          Expanded(flex: 3, child: Text('Name', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Type', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Phone', style: _headerStyle)),
          const SizedBox(width: 40)])),
      ...items.asMap().entries.map((e) => CustomerTableRow(item: e.value, isLast: e.key == items.length - 1,
        onTap: () => _navigateToDetail(e.value.id), onDelete: () => _deleteCustomer(e.value.id, e.value.name))),
    ]));
  }

  TextStyle get _headerStyle => TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Theme.of(context).colorScheme.onSurfaceVariant);

  Widget _buildEmpty(BuildContext context, ColorScheme scheme) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.store_outlined, size: 64, color: scheme.outlineVariant), const SizedBox(height: 16),
    Text('No customers yet.', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
    const SizedBox(height: 4), Text('Tap + to add your first customer.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))]));

  Widget _buildError(BuildContext context, ColorScheme scheme, String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.error_outline, size: 48, color: scheme.error), const SizedBox(height: 16), Text(msg, textAlign: TextAlign.center),
    const SizedBox(height: 16), FilledButton.icon(onPressed: () => context.read<CustomerBloc>().add(CustomerLoadAllRequested()),
      icon: const Icon(Icons.refresh), label: const Text('Retry'))]));
}
