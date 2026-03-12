import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';
import '../widgets/visit_card.dart';

class VisitListPage extends StatefulWidget {
  const VisitListPage({super.key});

  @override
  State<VisitListPage> createState() => _VisitListPageState();
}

class _VisitListPageState extends State<VisitListPage> {
  @override
  void initState() {
    super.initState();
    context.read<VisitBloc>().add(VisitLoadAllRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Visitss')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .pushNamed('/visits/create')
            .then((_) => context.read<VisitBloc>().add(VisitLoadAllRequested())),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<VisitBloc, VisitState>(
        listener: (context, state) {
          if (state is VisitOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<VisitBloc>().add(VisitLoadAllRequested());
          }
          if (state is VisitFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: scheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is VisitLoading || state is VisitInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VisitEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: scheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No visits recorded yet.', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            );
          }
          if (state is VisitFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<VisitBloc>().add(VisitLoadAllRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is VisitListLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<VisitBloc>().add(VisitLoadAllRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (_, i) => VisitCard(
                  item: state.items[i],
                  onTap: () => Navigator.of(context)
                      .pushNamed('/visits/detail', arguments: {'id': state.items[i].id})
                      .then((_) => context.read<VisitBloc>().add(VisitLoadAllRequested())),
                  onDelete: () => context.read<VisitBloc>()
                      .add(VisitDeleteRequested(state.items[i].id)),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
