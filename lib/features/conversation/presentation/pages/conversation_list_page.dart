  import '../../../../core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/conversation_bloc.dart';
import '../bloc/conversation_event.dart';
import '../bloc/conversation_state.dart';
import '../widgets/conversation_card.dart';

class ConversationListPage extends StatefulWidget {
  const ConversationListPage({super.key});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ConversationBloc>().add(ConversationLoadAllRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Conversationss')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .pushNamed('/conversations/create')
            .then((_) => context.read<ConversationBloc>().add(ConversationLoadAllRequested())),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<ConversationBloc, ConversationState>(
        listener: (context, state) {
          if (state is ConversationOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<ConversationBloc>().add(ConversationLoadAllRequested());
          }
          if (state is ConversationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ConversationLoading || state is ConversationInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ConversationEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: scheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations found.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is ConversationFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<ConversationBloc>().add(ConversationLoadAllRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is ConversationListLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<ConversationBloc>().add(ConversationLoadAllRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (_, i) => ConversationCard(
                  item: state.items[i],
                  onTap: () => Navigator.of(context)
                      .pushNamed('/conversations/detail', arguments: {'id': state.items[i].id})
                      .then((_) => context.read<ConversationBloc>().add(ConversationLoadAllRequested())),
                  onDelete: () => context.read<ConversationBloc>()
                      .add(ConversationDeleteRequested(state.items[i].id)),
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
