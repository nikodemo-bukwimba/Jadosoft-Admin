// visit_list_page.dart
// List with loading / empty / error / data states.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/visit_bloc.dart';
import '../../domain/repositories/visit_repository.dart';
import '../../domain/usecases/get_all_visit_usecase.dart';
import '../widgets/visit_card.dart';

class VisitListPage extends StatefulWidget {
  const VisitListPage({super.key});

  static const routePath = '/visits';

  @override
  State<VisitListPage> createState() => _VisitListPageState();
}

class _VisitListPageState extends State<VisitListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<VisitBloc>().add(VisitLoadAllRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visits'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search visits...',
              leading: const Icon(Icons.search),
              onChanged: (q) =>
                  context.read<VisitBloc>().add(VisitSearchChanged(q)),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "visits",
        onPressed: () => Navigator.of(context)
            .pushNamed('/visits/create')
            .then(
              (_) => context.read<VisitBloc>().add(VisitLoadAllRequested()),
            ),
        icon: const Icon(Icons.add),
        label: const Text('Add Visit'),
      ),
      body: BlocConsumer<VisitBloc, VisitState>(
        listener: (context, state) {
          if (state is VisitOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.primary,
              ),
            );
            context.read<VisitBloc>().add(VisitLoadAllRequested());
          }
          if (state is VisitFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
              ),
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
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: scheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No visits yet.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is VisitFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: scheme.error),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.read<VisitBloc>().add(
                        VisitLoadAllRequested(),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is VisitListLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<VisitBloc>().add(VisitLoadAllRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                itemCount: state.items.length,
                itemBuilder: (_, i) => VisitCard(
                  item: state.items[i],
                  onTap: () => Navigator.of(context)
                      .pushNamed('/visits/${state.items[i].id}')
                      .then(
                        (_) => context.read<VisitBloc>().add(
                          VisitLoadAllRequested(),
                        ),
                      ),
                  onDelete: () => context.read<VisitBloc>().add(
                    VisitDeleteRequested(state.items[i].id),
                  ),
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
