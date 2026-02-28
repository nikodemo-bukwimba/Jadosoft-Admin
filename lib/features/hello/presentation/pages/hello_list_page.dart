import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/hello_bloc.dart';
import '../bloc/hello_event.dart';
import '../bloc/hello_state.dart';
import '../widgets/hello_card.dart';

class HelloListPage extends StatefulWidget {
  const HelloListPage({super.key});

  @override
  State<HelloListPage> createState() => _HelloListPageState();
}

class _HelloListPageState extends State<HelloListPage> {
  @override
  void initState() {
    super.initState();
    context.read<HelloBloc>().add(HelloLoadAllRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Hellos')),
      floatingActionButton: FloatingActionButton(
        heroTag: "hellos",
        onPressed: () => Navigator.of(context)
            .pushNamed('/hellos/create')
            .then(
              (_) => context.read<HelloBloc>().add(HelloLoadAllRequested()),
            ),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<HelloBloc, HelloState>(
        listener: (context, state) {
          if (state is HelloOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            context.read<HelloBloc>().add(HelloLoadAllRequested());
          }
          if (state is HelloFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HelloLoading || state is HelloInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HelloEmpty) {
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
                    'No items found.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is HelloFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        context.read<HelloBloc>().add(HelloLoadAllRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is HelloListLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<HelloBloc>().add(HelloLoadAllRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (_, i) => HelloCard(
                  item: state.items[i],
                  onTap: () => Navigator.of(context)
                      .pushNamed(
                        '/hellos/detail',
                        arguments: {'id': state.items[i].id},
                      )
                      .then(
                        (_) => context.read<HelloBloc>().add(
                          HelloLoadAllRequested(),
                        ),
                      ),
                  onDelete: () => context.read<HelloBloc>().add(
                    HelloDeleteRequested(state.items[i].id),
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
