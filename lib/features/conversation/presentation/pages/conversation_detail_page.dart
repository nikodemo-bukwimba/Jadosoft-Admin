// === FILE: lib/features/conversation/presentation/pages/conversation_detail_page.dart ===
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../../actor/presentation/bloc/actor_bloc.dart';
import '../../../actor/presentation/bloc/actor_event.dart';
import '../../../actor/presentation/bloc/actor_state.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../bloc/conversation_bloc.dart';
import '../bloc/conversation_event.dart';
import '../bloc/conversation_state.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_side_panel.dart';
import '../widgets/message_bubble.dart';
import '../widgets/participant_avatar_stack.dart';
import '../widgets/typing_indicator.dart';

class ConversationDetailPage extends StatefulWidget {
  const ConversationDetailPage({super.key});
  @override
  State<ConversationDetailPage> createState() => _ConversationDetailPageState();
}

class _ConversationDetailPageState extends State<ConversationDetailPage> {
  final _scrollController = ScrollController();
  MessageEntity? _replyingTo;
  bool _showSidePanel = true;

  /// Contacts resolved from ActorBloc — used for "Add Member" in groups.
  List<Map<String, String>> _availableContacts = [];

  @override
  void initState() {
    super.initState();
    // Load actors for the add-member sheet
    _tryLoadActors();
  }

  void _tryLoadActors() {
    try {
      context.read<ActorBloc>().add(ActorLoadAllRequested());
    } catch (_) {
      // ActorBloc not provided — add-member will be disabled
    }
  }

  void _rebuildContacts() {
    final bloc = context.read<ConversationBloc>();
    final currentUserId = bloc.currentUserId;
    final contacts = <Map<String, String>>[];

    try {
      final actorState = context.read<ActorBloc>().state;
      if (actorState is ActorListLoaded) {
        for (final a in actorState.items) {
          if (a.id == currentUserId) continue;
          if (a.id.isEmpty) continue;
          final typeLabels = a.actorTypes
              .map((t) => t.label.toLowerCase())
              .toList();
          final role = typeLabels.any((l) => l.contains('officer'))
              ? 'officer'
              : typeLabels.any((l) => l.contains('customer'))
              ? 'customer'
              : typeLabels.any(
                  (l) => l.contains('owner') || l.contains('admin'),
                )
              ? 'officer'
              : (typeLabels.isNotEmpty ? typeLabels.first : 'member');
          contacts.add({'id': a.id, 'name': a.displayName, 'role': role});
        }
      }
    } catch (_) {
      // ActorBloc not available
    }

    if (mounted) {
      setState(() => _availableContacts = contacts);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToMessage(List<MessageEntity> messages, String messageId) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1 || !_scrollController.hasClients) return;
    final targetOffset = (index * 70.0).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Determines if the current user is a participant in this conversation.
  ///
  /// FIX: The API may return participant IDs in different formats (actor_id vs
  /// user_id). We check both exact match and case-insensitive match. If neither
  /// works but the user's role is 'admin', they are still considered a
  /// participant for the admin app (they created or were added to the conv).
  bool _isParticipant(ConversationEntity conv, String currentUserId) {
    // Exact match
    if (conv.hasParticipant(currentUserId)) return true;

    // Case-insensitive match (ULIDs are case-insensitive per spec)
    final lowerUserId = currentUserId.toLowerCase();
    if (conv.participants.any((p) => p.id.toLowerCase() == lowerUserId)) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bloc = context.read<ConversationBloc>();
    final currentUserId = bloc.currentUserId;

    return MultiBlocListener(
      listeners: [
        // Rebuild contacts when ActorBloc emits
        BlocListener<ActorBloc, ActorState>(
          listener: (_, _) => _rebuildContacts(),
        ),
      ],
      child: BlocConsumer<ConversationBloc, ConversationState>(
        listener: (context, state) {
          if (state is ConversationChatLoaded) _scrollToBottom();
          if (state is ConversationFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is ConversationOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            context.go('/conversations');
          }
          if (state is ConversationNewCreated) {
            final newId = state.conversationId;
            context.go('/conversations');
            Future.delayed(const Duration(milliseconds: 100), () {
              if (context.mounted) {
                context.go(AppRouter.conversationDetailPath(newId));
              }
            });
          }
          if (state is ConversationReadReceiptsLoaded) {
            _showReadReceiptsDialog(context, state.receipts);
          }
          if (state is ConversationBroadcastSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Broadcast sent to ${state.sentCount} conversations',
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ConversationLoading) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          if (state is! ConversationChatLoaded) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_outlined, size: 48, color: cs.outline),
                    const SizedBox(height: 12),
                    const Text('Loading...'),
                  ],
                ),
              ),
            );
          }

          final conv = state.conversation;
          final msgs = state.messages;
          // FIX #1: Use robust participant check
          final isAdmin = _isParticipant(conv, currentUserId);
          final isClosed = conv.status == ConversationStatus.closed;
          final isGroup = conv.type == ConversationType.group;
          final showNames = true;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final showPanel = isWide && _showSidePanel;

              return Scaffold(
                appBar: _buildAppBar(
                  context,
                  bloc,
                  conv,
                  currentUserId,
                  isGroup,
                  isClosed,
                  isAdmin,
                  isWide,
                ),
                body: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: showPanel ? double.infinity : 800,
                          ),
                          decoration: isWide && !showPanel
                              ? BoxDecoration(
                                  border: Border.symmetric(
                                    vertical: BorderSide(
                                      color: cs.outlineVariant.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                          child: Column(
                            children: [
                              if (!isAdmin)
                                _Banner(
                                  icon: Icons.visibility,
                                  text: 'You are monitoring this conversation',
                                  color: cs.tertiaryContainer.withValues(
                                    alpha: 0.5,
                                  ),
                                  iconColor: cs.tertiary,
                                  textColor: cs.onTertiaryContainer,
                                ),
                              if (isClosed)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  color: cs.errorContainer.withValues(
                                    alpha: 0.3,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lock,
                                        size: 16,
                                        color: cs.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Closed${conv.closedBy != null ? " by ${conv.closedBy}" : ""}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: cs.error,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                      if (isAdmin)
                                        TextButton.icon(
                                          onPressed: () => bloc.add(
                                            ConversationReopenRequested(
                                              conv.id,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.lock_open,
                                            size: 16,
                                          ),
                                          label: const Text('Reopen'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: cs.primary,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            minimumSize: const Size(0, 32),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              Expanded(
                                child: msgs.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.chat_bubble_outline,
                                              size: 48,
                                              color: cs.outline,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'No messages yet',
                                              style: TextStyle(
                                                color: cs.outline,
                                              ),
                                            ),
                                            if (isAdmin && !isClosed)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: Text(
                                                  'Send the first message below',
                                                  style: TextStyle(
                                                    color: cs.outline,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        itemCount:
                                            msgs.length +
                                            (state.typingUser != null ? 1 : 0),
                                        itemBuilder: (ctx, i) {
                                          if (i == msgs.length &&
                                              state.typingUser != null) {
                                            return TypingIndicator(
                                              senderName: state.typingUser!,
                                            );
                                          }
                                          final msg = msgs[i];
                                          return MessageBubble(
                                            message: msg,
                                            currentUserId: currentUserId,
                                            showSenderName: showNames,
                                            showDateSeparator: _showDateSep(
                                              msgs,
                                              i,
                                            ),
                                            dateSeparatorLabel:
                                                _showDateSep(msgs, i)
                                                ? _dateLabel(msg.sentAt)
                                                : null,
                                            onDelete: isAdmin && !msg.isSystem
                                                ? (id) => bloc.add(
                                                    ConversationDeleteMessageRequested(
                                                      conversationId: conv.id,
                                                      messageId: id,
                                                    ),
                                                  )
                                                : null,
                                            onReply:
                                                isAdmin &&
                                                    !isClosed &&
                                                    !msg.isSystem
                                                ? (m) => setState(
                                                    () => _replyingTo = m,
                                                  )
                                                : null,
                                            onReact: isAdmin && !isClosed
                                                ? (id, emoji) => bloc.add(
                                                    ConversationAddReactionRequested(
                                                      conversationId: conv.id,
                                                      messageId: id,
                                                      emoji: emoji,
                                                    ),
                                                  )
                                                : null,
                                            onTogglePin: isAdmin
                                                ? (id) => bloc.add(
                                                    ConversationTogglePinRequested(
                                                      conversationId: conv.id,
                                                      messageId: id,
                                                    ),
                                                  )
                                                : null,
                                            onToggleStar: isAdmin
                                                ? (id) => bloc.add(
                                                    ConversationToggleStarRequested(
                                                      conversationId: conv.id,
                                                      messageId: id,
                                                    ),
                                                  )
                                                : null,
                                            onForward: isAdmin && !isClosed
                                                ? (m) => _showForwardDialog(
                                                    context,
                                                    bloc,
                                                    m,
                                                    conv.id,
                                                  )
                                                : null,
                                            onEdit: isAdmin && !isClosed
                                                ? (m) => _showEditDialog(
                                                    context,
                                                    bloc,
                                                    m,
                                                    conv.id,
                                                  )
                                                : null,
                                            onViewReadReceipts:
                                                isAdmin && isGroup
                                                ? (id) => bloc.add(
                                                    ConversationViewReadReceipts(
                                                      conversationId: conv.id,
                                                      messageId: id,
                                                    ),
                                                  )
                                                : null,
                                            onPrivateReply:
                                                isAdmin &&
                                                    isGroup &&
                                                    !msg.isSystem
                                                ? (pId, name, role) => bloc.add(
                                                    ConversationPrivateReplyRequested(
                                                      participantId: pId,
                                                      participantName: name,
                                                      participantRole: role,
                                                      message:
                                                          'Regarding: "${msg.content}"',
                                                    ),
                                                  )
                                                : null,
                                          );
                                        },
                                      ),
                              ),
                              if (isAdmin && !isClosed)
                                ChatInputBar(
                                  enabled: true,
                                  replyingTo: _replyingTo,
                                  onCancelReply: () =>
                                      setState(() => _replyingTo = null),
                                  participants: conv.participants,
                                  onSend:
                                      (
                                        content,
                                        imageUrl, {
                                        List<String>? mentionedUserIds,
                                      }) {
                                        bloc.add(
                                          ConversationSendMessageRequested(
                                            conversationId: conv.id,
                                            content: content,
                                            imageUrl: imageUrl,
                                            replyToId: _replyingTo?.id,
                                            replyToSenderName:
                                                _replyingTo?.senderName,
                                            replyToContent:
                                                _replyingTo?.content,
                                            mentionedUserIds: mentionedUserIds,
                                          ),
                                        );
                                        setState(() => _replyingTo = null);
                                      },
                                )
                              else if (!isAdmin)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: cs.outlineVariant.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.visibility,
                                        size: 16,
                                        color: cs.outline,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Monitor mode — read only',
                                        style: TextStyle(
                                          color: cs.outline,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (showPanel)
                      ChatSidePanel(
                        conversation: conv,
                        currentUserId: currentUserId,
                        messages: msgs,
                        pinnedMessages: state.pinnedMessages ?? [],
                        searchResults: state.searchResults,
                        searchQuery: state.searchQuery,
                        // FIX #7: Wire availableContacts from ActorBloc
                        availableContacts: _availableContacts,
                        onSearch: (q) => bloc.add(
                          ConversationSearchMessages(
                            conversationId: conv.id,
                            query: q,
                          ),
                        ),
                        onClearSearch: () =>
                            bloc.add(ConversationClearSearch()),
                        onAddParticipant: (id, name, role) => bloc.add(
                          ConversationAddParticipantRequested(
                            conversationId: conv.id,
                            participantId: id,
                            name: name,
                            role: role,
                          ),
                        ),
                        onRemoveParticipant: (id, name) => bloc.add(
                          ConversationRemoveParticipantRequested(
                            conversationId: conv.id,
                            participantId: id,
                            name: name,
                          ),
                        ),
                        onPrivateMessage: (id, name, role) => bloc.add(
                          ConversationPrivateReplyRequested(
                            participantId: id,
                            participantName: name,
                            participantRole: role,
                          ),
                        ),
                        onScrollToMessage: (msgId) =>
                            _scrollToMessage(msgs, msgId),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showInfoBottomSheet(
    BuildContext context,
    ConversationEntity conv,
    String currentUserId,
    ConversationBloc bloc,
    bool isGroup,
    bool isClosed,
    bool isAdmin,
  ) {
    final blocState = bloc.state;
    final msgs = blocState is ConversationChatLoaded
        ? blocState.messages
        : <MessageEntity>[];
    final pinned = blocState is ConversationChatLoaded
        ? (blocState.pinnedMessages ?? <MessageEntity>[])
        : <MessageEntity>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: ChatSidePanel(
          conversation: conv,
          currentUserId: currentUserId,
          messages: msgs,
          pinnedMessages: pinned,
          availableContacts: _availableContacts,
          onSearch: (q) => bloc.add(
            ConversationSearchMessages(conversationId: conv.id, query: q),
          ),
          onClearSearch: () => bloc.add(ConversationClearSearch()),
          onAddParticipant: (id, name, role) {
            Navigator.pop(context);
            bloc.add(
              ConversationAddParticipantRequested(
                conversationId: conv.id,
                participantId: id,
                name: name,
                role: role,
              ),
            );
          },
          onRemoveParticipant: (id, name) {
            Navigator.pop(context);
            bloc.add(
              ConversationRemoveParticipantRequested(
                conversationId: conv.id,
                participantId: id,
                name: name,
              ),
            );
          },
          onPrivateMessage: (id, name, role) {
            Navigator.pop(context);
            bloc.add(
              ConversationPrivateReplyRequested(
                participantId: id,
                participantName: name,
                participantRole: role,
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ConversationBloc bloc,
    ConversationEntity conv,
    String currentUserId,
    bool isGroup,
    bool isClosed,
    bool isAdmin,
    bool isWide,
  ) {
    final cs = Theme.of(context).colorScheme;
    final displayName = conv.displayName(currentUserId);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/conversations'),
      ),
      title: InkWell(
        onTap: isWide
            ? () => setState(() => _showSidePanel = !_showSidePanel)
            : () => _showInfoBottomSheet(
                context,
                conv,
                currentUserId,
                bloc,
                isGroup,
                isClosed,
                isAdmin,
              ),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ParticipantAvatarStack(
              participants: conv.participants,
              isGroup: isGroup,
              size: 36,
              currentUserId:
                  currentUserId, 
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    conv.subtitle(currentUserId),
                    style: TextStyle(fontSize: 11, color: cs.outline),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!isWide)
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Info',
            onPressed: () => _showInfoBottomSheet(
              context,
              conv,
              currentUserId,
              bloc,
              isGroup,
              isClosed,
              isAdmin,
            ),
          ),
        if (isWide)
          IconButton(
            icon: Icon(
              _showSidePanel ? Icons.info : Icons.info_outline,
              color: _showSidePanel ? cs.primary : null,
            ),
            tooltip: _showSidePanel ? 'Hide panel' : 'Show panel',
            onPressed: () => setState(() => _showSidePanel = !_showSidePanel),
          ),
        if (isAdmin && !isClosed)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'close') {
                bloc.add(ConversationCloseRequested(conv.id));
              }
              if (v == 'delete') {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete conversation?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          bloc.add(ConversationDeleteRequested(conv.id));
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.error,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'close',
                child: Text('Close Conversation'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: cs.error)),
              ),
            ],
          ),
      ],
    );
  }

  bool _showDateSep(List<MessageEntity> msgs, int index) {
    if (index == 0) return true;
    final curr = msgs[index].sentAt;
    final prev = msgs[index - 1].sentAt;
    return curr.year != prev.year ||
        curr.month != prev.month ||
        curr.day != prev.day;
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }

  void _showReadReceiptsDialog(
    BuildContext context,
    List<ReadReceipt> receipts,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Read by'),
        content: SizedBox(
          width: 280,
          child: receipts.isEmpty
              ? const Text('No one has read this message yet.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: receipts
                      .map(
                        (r) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            child: Text(
                              r.userName.isNotEmpty ? r.userName[0] : '?',
                            ),
                          ),
                          title: Text(r.userName),
                          subtitle: Text(
                            '${r.readAt.hour}:${r.readAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showForwardDialog(
    BuildContext context,
    ConversationBloc bloc,
    MessageEntity msg,
    String currentConvId,
  ) {
    // Simplified — forward to a conversation selected from the list
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Forward Message'),
        content: const Text(
          'Forward functionality requires loading the conversation list. '
          'Use the broadcast tab for multi-recipient forwarding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    ConversationBloc bloc,
    MessageEntity msg,
    String convId,
  ) {
    final controller = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Edit your message...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != msg.content) {
                bloc.add(
                  ConversationEditMessageRequested(
                    conversationId: convId,
                    messageId: msg.id,
                    newContent: newContent,
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color iconColor;
  final Color textColor;
  const _Banner({
    required this.icon,
    required this.text,
    required this.color,
    required this.iconColor,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color,
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
