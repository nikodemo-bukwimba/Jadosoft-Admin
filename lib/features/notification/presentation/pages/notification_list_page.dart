import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notification_card.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(NotificationLoadAllRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notificationss')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .pushNamed('/notifications/create')
            .then((_) => context.read<NotificationBloc>().add(NotificationLoadAllRequested())),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<NotificationBloc>().add(NotificationLoadAllRequested());
          }
          if (state is NotificationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: scheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading || state is NotificationInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: scheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No notifications found.', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            );
          }
          if (state is NotificationFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<NotificationBloc>().add(NotificationLoadAllRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is NotificationListLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<NotificationBloc>().add(NotificationLoadAllRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (_, i) => NotificationCard(
                  item: state.items[i],
                  onTap: () => Navigator.of(context)
                      .pushNamed('/notifications/detail', arguments: {'id': state.items[i].id})
                      .then((_) => context.read<NotificationBloc>().add(NotificationLoadAllRequested())),
                  onDelete: () => context.read<NotificationBloc>()
                      .add(NotificationDeleteRequested(state.items[i].id)),
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
