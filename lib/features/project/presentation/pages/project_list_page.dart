import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';
import '../widgets/project_card.dart';

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(ProjectLoadAllRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .pushNamed('/projects/create')
            .then((_) => context.read<ProjectBloc>().add(ProjectLoadAllRequested())),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state is ProjectOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<ProjectBloc>().add(ProjectLoadAllRequested());
          }
          if (state is ProjectFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: scheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is ProjectLoading || state is ProjectInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProjectEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: scheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No projects yet. Create your first project.', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            );
          }
          if (state is ProjectFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<ProjectBloc>().add(ProjectLoadAllRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is ProjectListLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<ProjectBloc>().add(ProjectLoadAllRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (_, i) => ProjectCard(
                  item: state.items[i],
                  onTap: () => Navigator.of(context)
                      .pushNamed('/projects/detail', arguments: {'id': state.items[i].id})
                      .then((_) => context.read<ProjectBloc>().add(ProjectLoadAllRequested())),
                  onDelete: () => context.read<ProjectBloc>()
                      .add(ProjectDeleteRequested(state.items[i].id)),
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
