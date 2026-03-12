import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/conversation_bloc.dart';
import '../bloc/conversation_state.dart';

class ConversationDetailPage extends StatelessWidget {
  const ConversationDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<ConversationBloc>().state;
              if (state is ConversationDetailLoaded) {
                Navigator.of(context).pushNamed(
                  '/conversations/edit',
                  arguments: {'id': state.item.id},
                );
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<ConversationBloc, ConversationState>(
        builder: (context, state) {
          if (state is ConversationLoading || state is ConversationInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ConversationFailure) {
            return Center(child: Text(state.message));
          }
          if (state is ConversationDetailLoaded) {
            final item = state.item;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildField(
                        context,
                        'Participant Ids',
                        item.participantIds.join(', '),
                      ),
                      _buildField(
                        context,
                        'Participant Roles',
                        item.participantRoles.join(', '),
                      ),
                      _buildField(
                        context,
                        'Last Message',
                        item.lastMessage?.toString() ?? '',
                      ),
                      _buildField(
                        context,
                        'Last Message At',
                        item.lastMessageAt
                                ?.toIso8601String()
                                .split('T')
                                .first ??
                            '',
                      ),
                      _buildField(
                        context,
                        'Unread Count',
                        item.unreadCount.toString(),
                      ),
                      _buildField(
                        context,
                        'Created At',
                        item.createdAt.toIso8601String().split('T').first,
                      ),
                    ],
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

  Widget _buildField(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
