import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/officer_bloc.dart';
import '../bloc/officer_event.dart';
import '../bloc/officer_state.dart';
import '../widgets/officer_card.dart';

class OfficerListPage extends StatefulWidget {
  const OfficerListPage({super.key});

  @override
  State<OfficerListPage> createState() => _OfficerListPageState();
}

class _OfficerListPageState extends State<OfficerListPage> {
  @override
  void initState() {
    super.initState();
    context.read<OfficerBloc>().add(OfficerLoadAllRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Officerss')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .pushNamed('/officers/create')
            .then((_) => context.read<OfficerBloc>().add(OfficerLoadAllRequested())),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<OfficerBloc, OfficerState>(
        listener: (context, state) {
          if (state is OfficerOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<OfficerBloc>().add(OfficerLoadAllRequested());
          }
          if (state is OfficerFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: scheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is OfficerLoading || state is OfficerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OfficerEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: scheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No officers found.', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            );
          }
          if (state is OfficerFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<OfficerBloc>().add(OfficerLoadAllRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is OfficerListLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<OfficerBloc>().add(OfficerLoadAllRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (_, i) => OfficerCard(
                  item: state.items[i],
                  onTap: () => Navigator.of(context)
                      .pushNamed('/officers/detail', arguments: {'id': state.items[i].id})
                      .then((_) => context.read<OfficerBloc>().add(OfficerLoadAllRequested())),
                  onDelete: () => context.read<OfficerBloc>()
                      .add(OfficerDeleteRequested(state.items[i].id)),
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
