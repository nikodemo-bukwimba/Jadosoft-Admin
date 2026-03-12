import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/weekly_plan_bloc.dart';
import '../bloc/weekly_plan_event.dart';
import '../bloc/weekly_plan_state.dart';
import '../widgets/weekly_plan_card.dart';

class WeeklyPlanListPage extends StatefulWidget {
  const WeeklyPlanListPage({super.key});

  @override
  State<WeeklyPlanListPage> createState() => _WeeklyPlanListPageState();
}

class _WeeklyPlanListPageState extends State<WeeklyPlanListPage> {
  @override
  void initState() {
    super.initState();
    context.read<WeeklyPlanBloc>().add(WeeklyPlanLoadAllRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Planss')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .pushNamed('/weekly_plans/create')
            .then((_) => context.read<WeeklyPlanBloc>().add(WeeklyPlanLoadAllRequested())),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<WeeklyPlanBloc, WeeklyPlanState>(
        listener: (context, state) {
          if (state is WeeklyPlanOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<WeeklyPlanBloc>().add(WeeklyPlanLoadAllRequested());
          }
          if (state is WeeklyPlanFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: scheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is WeeklyPlanLoading || state is WeeklyPlanInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is WeeklyPlanEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: scheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No weekly plans found.', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            );
          }
          if (state is WeeklyPlanFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<WeeklyPlanBloc>().add(WeeklyPlanLoadAllRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is WeeklyPlanListLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<WeeklyPlanBloc>().add(WeeklyPlanLoadAllRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (_, i) => WeeklyPlanCard(
                  item: state.items[i],
                  onTap: () => Navigator.of(context)
                      .pushNamed('/weekly_plans/detail', arguments: {'id': state.items[i].id})
                      .then((_) => context.read<WeeklyPlanBloc>().add(WeeklyPlanLoadAllRequested())),
                  onDelete: () => context.read<WeeklyPlanBloc>()
                      .add(WeeklyPlanDeleteRequested(state.items[i].id)),
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
