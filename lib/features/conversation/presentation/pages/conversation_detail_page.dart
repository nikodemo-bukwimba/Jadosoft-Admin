import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bloc = context.read<ConversationBloc>();
    final currentUserId = bloc.currentUserId;

    return BlocConsumer<ConversationBloc, ConversationState>(
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
        final isAdmin = conv.hasParticipant(currentUserId);
        final isClosed = conv.status == ConversationStatus.closed;
        final isGroup = conv.type == ConversationType.group;
        final showNames = isGroup || !isAdmin;

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
                                color: cs.errorContainer.withValues(alpha: 0.3),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock, size: 16, color: cs.error),
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
                                          ConversationReopenRequested(conv.id),
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
                            if (!showPanel &&
                                (state.pinnedMessages?.isNotEmpty ?? false))
                              GestureDetector(
                                onTap: () => _scrollToMessage(
                                  msgs,
                                  state.pinnedMessages!.first.id,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.08),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.amber.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.push_pin,
                                        size: 14,
                                        color: Colors.amber.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          state.pinnedMessages!.first.content,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.amber.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: Colors.amber.shade700,
                                      ),
                                    ],
                                  ),
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
                                            style: TextStyle(color: cs.outline),
                                          ),
                                          if (isAdmin && !isClosed)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                'Start the conversation below',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: cs.outline,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.only(
                                        top: 12,
                                        bottom: 8,
                                        left: 4,
                                        right: 4,
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
                                          onForward: isAdmin
                                              ? (m) => _showForwardDialog(
                                                  context,
                                                  bloc,
                                                  m,
                                                  currentUserId,
                                                )
                                              : null,
                                          onEdit: isAdmin
                                              ? (m) => _showEditDialog(
                                                  context,
                                                  bloc,
                                                  m,
                                                  conv.id,
                                                )
                                              : null,
                                          onViewReadReceipts: isAdmin && isGroup
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
                                      if (content.isEmpty && imageUrl == null) {
                                        return;
                                      }
                                      bloc.add(
                                        ConversationSendMessageRequested(
                                          conversationId: conv.id,
                                          content: content,
                                          imageUrl: imageUrl,
                                          replyToId: _replyingTo?.id,
                                          replyToSenderName:
                                              _replyingTo?.senderName,
                                          replyToContent:
                                              _replyingTo?.isImage == true
                                              ? '📷 Photo'
                                              : _replyingTo?.content,
                                          mentionedUserIds: mentionedUserIds,
                                        ),
                                      );
                                      setState(() => _replyingTo = null);
                                    },
                              ),
                            if (!isAdmin)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cs.surface,
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
                      // availableContacts: injected from ActorBloc if needed
                      onSearch: (q) => bloc.add(
                        ConversationSearchMessages(
                          conversationId: conv.id,
                          query: q,
                        ),
                      ),
                      onClearSearch: () => bloc.add(ConversationClearSearch()),
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
    );
  }

  AppBar _buildAppBar(
    BuildContext ctx,
    ConversationBloc bloc,
    ConversationEntity conv,
    String currentUserId,
    bool isGroup,
    bool isClosed,
    bool isAdmin,
    bool isWide,
  ) {
    final cs = Theme.of(ctx).colorScheme;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => ctx.go('/conversations'),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          ParticipantAvatarStack(
            participants: conv.participants,
            isGroup: isGroup,
            size: 36,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conv.displayName(currentUserId),
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isGroup
                      ? '${conv.participants.length} members • ${conv.onlineCount} online'
                      : conv.subtitle(currentUserId),
                  style: Theme.of(
                    ctx,
                  ).textTheme.labelSmall?.copyWith(color: cs.outline),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (isWide)
          IconButton(
            icon: Icon(
              _showSidePanel ? Icons.chevron_right : Icons.info_outline,
            ),
            tooltip: _showSidePanel ? 'Hide panel' : 'Show panel',
            onPressed: () => setState(() => _showSidePanel = !_showSidePanel),
          ),
        if (!isWide)
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () =>
                _showMobileSidePanel(ctx, bloc, conv, currentUserId),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (v) => _handleMenu(ctx, bloc, v, conv, currentUserId),
          itemBuilder: (_) => [
            if (isAdmin && isGroup && !isClosed)
              const PopupMenuItem(
                value: 'add',
                child: ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('Add Member'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            if (isAdmin && isGroup && !isClosed)
              const PopupMenuItem(
                value: 'remove',
                child: ListTile(
                  leading: Icon(Icons.person_remove),
                  title: Text('Remove Member'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            if (isGroup)
              const PopupMenuItem(
                value: 'members',
                child: ListTile(
                  leading: Icon(Icons.people),
                  title: Text('View Members'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            if (isAdmin && !isClosed)
              PopupMenuItem(
                value: 'broadcast',
                child: ListTile(
                  leading: Icon(Icons.campaign, color: cs.primary),
                  title: Text('Broadcast', style: TextStyle(color: cs.primary)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            if (isAdmin && !isClosed)
              PopupMenuItem(
                value: 'close',
                child: ListTile(
                  leading: Icon(Icons.lock, color: cs.error),
                  title: Text('Close', style: TextStyle(color: cs.error)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            if (isAdmin && isClosed)
              const PopupMenuItem(
                value: 'reopen',
                child: ListTile(
                  leading: Icon(Icons.lock_open, color: Colors.green),
                  title: Text('Reopen', style: TextStyle(color: Colors.green)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            if (isAdmin)
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: cs.error),
                  title: Text('Delete', style: TextStyle(color: cs.error)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _handleMenu(
    BuildContext ctx,
    ConversationBloc bloc,
    String action,
    ConversationEntity conv,
    String currentUserId,
  ) {
    switch (action) {
      case 'close':
        _confirm(
          ctx,
          'Close?',
          'Participants cannot send messages.',
          'Close',
          true,
          () => bloc.add(ConversationCloseRequested(conv.id)),
        );
      case 'reopen':
        bloc.add(ConversationReopenRequested(conv.id));
      case 'delete':
        _confirm(
          ctx,
          'Delete?',
          'Permanently delete conversation and messages.',
          'Delete',
          true,
          () => bloc.add(ConversationDeleteRequested(conv.id)),
        );
      case 'add':
      case 'remove':
      case 'members':
        _showMobileSidePanel(ctx, bloc, conv, currentUserId);
      case 'broadcast':
        _showBroadcastDialog(ctx, bloc, currentUserId);
    }
  }

  void _showMobileSidePanel(
    BuildContext ctx,
    ConversationBloc bloc,
    ConversationEntity conv,
    String currentUserId,
  ) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.85,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: BlocBuilder<ConversationBloc, ConversationState>(
          builder: (ctx2, state) {
            if (state is! ConversationChatLoaded) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return SafeArea(
              child: ChatSidePanel(
                conversation: state.conversation,
                currentUserId: currentUserId,
                messages: state.messages,
                pinnedMessages: state.pinnedMessages ?? [],
                searchResults: state.searchResults,
                searchQuery: state.searchQuery,
                onSearch: (q) => bloc.add(
                  ConversationSearchMessages(conversationId: conv.id, query: q),
                ),
                onClearSearch: () => bloc.add(ConversationClearSearch()),
                onAddParticipant: (id, name, role) {
                  Navigator.pop(ctx);
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
                  Navigator.pop(ctx);
                  bloc.add(
                    ConversationRemoveParticipantRequested(
                      conversationId: conv.id,
                      participantId: id,
                      name: name,
                    ),
                  );
                },
                onPrivateMessage: (id, name, role) {
                  Navigator.pop(ctx);
                  bloc.add(
                    ConversationPrivateReplyRequested(
                      participantId: id,
                      participantName: name,
                      participantRole: role,
                    ),
                  );
                },
                onScrollToMessage: (msgId) {
                  Navigator.pop(ctx);
                  _scrollToMessage(state.messages, msgId);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _confirm(
    BuildContext ctx,
    String title,
    String content,
    String label,
    bool destructive,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                  )
                : null,
            onPressed: () {
              Navigator.pop(d);
              onConfirm();
            },
            child: Text(label),
          ),
        ],
      ),
    );
  }

  /// Forward dialog — drives conversation list from BLoC state.
  /// No mock datasource reference.
  void _showForwardDialog(
    BuildContext ctx,
    ConversationBloc bloc,
    MessageEntity msg,
    String currentUserId,
  ) {
    final convState = bloc.state;
    final List<ConversationEntity> convs;
    if (convState is ConversationListLoaded) {
      convs = convState.items
          .where((c) => c.hasParticipant(currentUserId))
          .toList();
    } else if (convState is ConversationChatLoaded) {
      convs = [convState.conversation];
    } else {
      convs = [];
    }

    if (convs.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('No conversations to forward to')),
      );
      return;
    }

    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Forward to...'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ListView(
            children: convs
                .map(
                  (c) => ListTile(
                    title: Text(
                      c.displayName(currentUserId),
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(c.id, style: const TextStyle(fontSize: 10)),
                    onTap: () {
                      Navigator.pop(d);
                      bloc.add(
                        ConversationForwardMessageRequested(
                          targetConversationId: c.id,
                          content: msg.content,
                          originalConvId: msg.conversationId,
                          originalSenderName: msg.senderName,
                        ),
                      );
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Forwarded to ${c.displayName(currentUserId)}',
                          ),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext ctx,
    ConversationBloc bloc,
    MessageEntity msg,
    String convId,
  ) {
    final controller = TextEditingController(text: msg.content);
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(d);
              if (controller.text.trim().isNotEmpty) {
                bloc.add(
                  ConversationEditMessageRequested(
                    conversationId: convId,
                    messageId: msg.id,
                    newContent: controller.text.trim(),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Broadcast dialog — drives conversation list from BLoC state.
  /// No mock datasource reference.
  void _showBroadcastDialog(
    BuildContext ctx,
    ConversationBloc bloc,
    String currentUserId,
  ) {
    final convState = bloc.state;
    final List<ConversationEntity> existingConvs =
        convState is ConversationListLoaded
        ? convState.items.where((c) => c.hasParticipant(currentUserId)).toList()
        : convState is ConversationChatLoaded
        ? [convState.conversation]
        : [];

    final selected = <String>{};
    final msgController = TextEditingController();

    showDialog(
      context: ctx,
      builder: (d) => StatefulBuilder(
        builder: (ctx2, setState2) => AlertDialog(
          title: const Text('Broadcast Message'),
          content: SizedBox(
            width: 380,
            height: 400,
            child: Column(
              children: [
                TextField(
                  controller: msgController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Type broadcast message...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Conversations (${selected.length} selected)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                if (existingConvs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No conversations loaded.\nGo back to the list first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      children: existingConvs
                          .map(
                            (c) => CheckboxListTile(
                              dense: true,
                              value: selected.contains(c.id),
                              title: Text(
                                c.displayName(currentUserId),
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                c.type == ConversationType.group
                                    ? 'Group'
                                    : 'Direct',
                                style: const TextStyle(fontSize: 10),
                              ),
                              onChanged: (v) => setState2(() {
                                if (v == true) {
                                  selected.add(c.id);
                                } else {
                                  selected.remove(c.id);
                                }
                              }),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed:
                  selected.isNotEmpty && msgController.text.trim().isNotEmpty
                  ? () {
                      Navigator.pop(d);
                      bloc.add(
                        ConversationBroadcastRequested(
                          conversationIds: selected.toList(),
                          content: msgController.text.trim(),
                        ),
                      );
                    }
                  : null,
              child: Text('Send (${selected.length})'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReadReceiptsDialog(BuildContext ctx, List<ReadReceipt> receipts) {
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Read by'),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: receipts
                .map(
                  (r) => ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.done_all,
                      size: 16,
                      color: Colors.blue,
                    ),
                    title: Text(
                      r.userName,
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Text(
                      '${r.readAt.hour.toString().padLeft(2, '0')}:${r.readAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  bool _showDateSep(List<MessageEntity> msgs, int i) {
    if (i == 0) return true;
    final c = msgs[i].sentAt;
    final p = msgs[i - 1].sentAt;
    return c.day != p.day || c.month != p.month || c.year != p.year;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}/${dt.year}';
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
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    color: color,
    child: Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
