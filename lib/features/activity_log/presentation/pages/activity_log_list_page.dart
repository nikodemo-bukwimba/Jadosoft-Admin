  import '../../../../core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/activity_log_bloc.dart';
import '../bloc/activity_log_event.dart';
import '../bloc/activity_log_state.dart';
import '../widgets/activity_log_card.dart';

class ActivityLogListPage extends StatefulWidget {
  const ActivityLogListPage({super.key});

  @override
  State<ActivityLogListPage> createState() => _ActivityLogListPageState();
}

class _ActivityLogListPageState extends State<ActivityLogListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ActivityLogBloc>().add(ActivityLogLoadAllRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Logss')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .pushNamed('/activity_logs/create')
            .then((_) => context.read<ActivityLogBloc>().add(ActivityLogLoadAllRequested())),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<ActivityLogBloc, ActivityLogState>(
        listener: (context, state) {
          if (state is ActivityLogOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<ActivityLogBloc>().add(ActivityLogLoadAllRequested());
          }
          if (state is ActivityLogFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ActivityLogLoading || state is ActivityLogInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ActivityLogEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: scheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No activity logs recorded yet.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is ActivityLogFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<ActivityLogBloc>().add(ActivityLogLoadAllRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is ActivityLogListLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<ActivityLogBloc>().add(ActivityLogLoadAllRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (_, i) => ActivityLogCard(
                  item: state.items[i],
                  onTap: () => Navigator.of(context)
                      .pushNamed('/activity_logs/detail', arguments: {'id': state.items[i].id})
                      .then((_) => context.read<ActivityLogBloc>().add(ActivityLogLoadAllRequested())),
                  onDelete: () => context.read<ActivityLogBloc>()
                      .add(ActivityLogDeleteRequested(state.items[i].id)),
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
