import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/conversation_entity.dart';
import '../bloc/conversation_bloc.dart';
import '../bloc/conversation_event.dart';
import '../bloc/conversation_state.dart';
import '../widgets/conversation_tile.dart';

class ConversationListPage extends StatefulWidget {
  const ConversationListPage({super.key});
  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ConversationEntity> _my(
    List<ConversationEntity> all,
    String currentUserId,
  ) =>
      all.where((c) => c.hasParticipant(currentUserId)).toList();

  List<ConversationEntity> _monitored(
    List<ConversationEntity> all,
    String currentUserId,
  ) =>
      all.where((c) => !c.hasParticipant(currentUserId)).toList();

  List<ConversationEntity> _filtered(
    List<ConversationEntity> list,
    String currentUserId,
  ) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((c) {
      final name = c.displayName(currentUserId).toLowerCase();
      final id = c.id.toLowerCase();
      final pNames = c.participants.map((p) => p.name.toLowerCase()).join(' ');
      return name.contains(q) || id.contains(q) || pNames.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // currentUserId is owned by the BLoC — read it once here.
    final currentUserId = context.read<ConversationBloc>().currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or ID...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'My Conversations'),
                  Tab(text: 'Monitored'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: BlocConsumer<ConversationBloc, ConversationState>(
        listener: (context, state) {
          if (state is ConversationOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<ConversationBloc>().add(
              ConversationLoadAllRequested(),
            );
          }
        },
        builder: (context, state) {
          if (state is ConversationLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ConversationFailure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: cs.error),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.read<ConversationBloc>().add(
                      ConversationLoadAllRequested(),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is ConversationEmpty) return _empty(context);
          List<ConversationEntity> all = [];
          if (state is ConversationListLoaded) all = state.items;
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(
                context,
                _filtered(_my(all, currentUserId), currentUserId),
                currentUserId: currentUserId,
                isMine: true,
              ),
              _buildList(
                context,
                _filtered(_monitored(all, currentUserId), currentUserId),
                currentUserId: currentUserId,
                isMine: false,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'new_conv',
        onPressed: () => context.go(AppRouter.conversationCreate),
        tooltip: 'New Conversation',
        child: const Icon(Icons.edit_square),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<ConversationEntity> convs, {
    required String currentUserId,
    required bool isMine,
  }) {
    if (convs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMine ? Icons.chat_outlined : Icons.visibility_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              isMine
                  ? 'No conversations yet'
                  : 'No conversations to monitor',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Try a different search',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ConversationBloc>().add(ConversationLoadAllRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: convs.length,
        itemBuilder: (context, i) {
          final conv = convs[i];
          return ConversationTile(
            conversation: conv,
            currentUserId: currentUserId,
            onTap: () => context.go(AppRouter.conversationDetailPath(conv.id)),
            onDelete: () {
              context.read<ConversationBloc>().add(
                ConversationDeleteRequested(conv.id),
              );
            },
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: cs.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new conversation',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.outline,
            ),
          ),
        ],
      ),
    );
  }
}