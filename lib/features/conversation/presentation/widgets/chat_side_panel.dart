import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../data/datasources/conversation_mock_datasource.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';

class ChatSidePanel extends StatefulWidget {
  final ConversationEntity conversation;
  final List<MessageEntity> messages;
  final List<MessageEntity> pinnedMessages;
  final void Function(String query)? onSearch;
  final VoidCallback? onClearSearch;
  final void Function(String participantId, String name, String role)?
  onAddParticipant;
  final void Function(String participantId, String name)? onRemoveParticipant;
  final void Function(String participantId, String name, String role)?
  onPrivateMessage;
  final List<MessageEntity>? searchResults;
  final String? searchQuery;
  final void Function(String messageId)? onScrollToMessage;

  const ChatSidePanel({
    super.key,
    required this.conversation,
    required this.messages,
    this.pinnedMessages = const [],
    this.onSearch,
    this.onClearSearch,
    this.onAddParticipant,
    this.onRemoveParticipant,
    this.onPrivateMessage,
    this.searchResults,
    this.searchQuery,
    this.onScrollToMessage,
  });

  @override
  State<ChatSidePanel> createState() => _ChatSidePanelState();
}

class _ChatSidePanelState extends State<ChatSidePanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.conversation.type == ConversationType.group ? 4 : 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isAdmin => widget.conversation.hasParticipant(kAdminId);
  bool get _isGroup => widget.conversation.type == ConversationType.group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final conv = widget.conversation;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          left: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: cs.primaryContainer,
                  child: _isGroup
                      ? Icon(Icons.group, size: 28, color: cs.primary)
                      : Text(
                          conv.displayName(kAdminId)[0],
                          style: TextStyle(
                            fontSize: 24,
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                Text(
                  conv.displayName(kAdminId),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                if (_isGroup)
                  Text(
                    '${conv.participants.length} members • ${conv.onlineCount} online',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: cs.outline),
                  )
                else if (conv.otherParticipant(kAdminId) != null)
                  _OnlineIndicator(
                    participant: conv.otherParticipant(kAdminId)!,
                  ),
                const SizedBox(height: 4),
                Text(
                  conv.id.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.outline,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              const Tab(text: 'Info'),
              if (_isGroup) const Tab(text: 'Members'),
              const Tab(text: 'Pinned'),
              const Tab(text: 'Search'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _InfoTab(
                  conversation: conv,
                  messages: widget.messages,
                  isAdmin: _isAdmin,
                ),
                if (_isGroup)
                  _MembersTab(
                    conversation: conv,
                    isAdmin: _isAdmin,
                    onAdd: widget.onAddParticipant,
                    onRemove: widget.onRemoveParticipant,
                    onPrivateMessage: widget.onPrivateMessage,
                  ),
                _PinnedTab(
                  pinnedMessages: widget.pinnedMessages,
                  onTap: widget.onScrollToMessage,
                ),
                _SearchTab(
                  searchController: _searchController,
                  onSearch: widget.onSearch,
                  onClear: widget.onClearSearch,
                  results: widget.searchResults,
                  query: widget.searchQuery,
                  onTapResult: widget.onScrollToMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineIndicator extends StatelessWidget {
  final ConversationParticipant participant;
  const _OnlineIndicator({required this.participant});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOnline = participant.onlineStatus == OnlineStatus.online;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline
                ? Colors.green
                : (participant.onlineStatus == OnlineStatus.away
                      ? Colors.amber
                      : cs.outline),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          participant.lastSeenLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isOnline ? Colors.green : cs.outline,
            fontWeight: isOnline ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _InfoTab extends StatelessWidget {
  final ConversationEntity conversation;
  final List<MessageEntity> messages;
  final bool isAdmin;
  const _InfoTab({
    required this.conversation,
    required this.messages,
    required this.isAdmin,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isGroup = conversation.type == ConversationType.group;
    final other = conversation.otherParticipant(kAdminId);
    final imageCount = messages.where((m) => m.isImage).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!isGroup && other != null) ...[
          _infoRow(context, Icons.person, 'Role', other.role.toUpperCase()),
          _infoRow(
            context,
            Icons.calendar_today,
            'Joined',
            _fmtDate(other.joinedAt),
          ),
          const SizedBox(height: 16),
        ],
        if (isGroup) ...[
          _infoRow(
            context,
            Icons.calendar_today,
            'Created',
            _fmtDate(conversation.createdAt),
          ),
          if (conversation.status == ConversationStatus.closed &&
              conversation.closedBy != null)
            _infoRow(context, Icons.lock, 'Closed by', conversation.closedBy!),
          const SizedBox(height: 16),
        ],
        Text(
          'Statistics',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _statCard(
          context,
          Icons.message,
          'Messages',
          messages.where((m) => !m.isSystem).length.toString(),
        ),
        _statCard(context, Icons.image, 'Images', imageCount.toString()),
        _statCard(
          context,
          Icons.push_pin,
          'Pinned',
          messages.where((m) => m.isPinned).length.toString(),
        ),
        _statCard(
          context,
          Icons.star,
          'Starred',
          messages.where((m) => m.isStarred).length.toString(),
        ),

        // Fix #5: View Full Profile navigates to officer/customer detail
        if (!isGroup && isAdmin && other != null) ...[
          const SizedBox(height: 24),
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              final id = other.id;
              if (other.role == 'officer') {
                context.go(AppRouter.officerDetailPath(id));
              } else if (other.role == 'customer') {
                context.go(AppRouter.customerDetailPath(id));
              }
            },
            icon: const Icon(Icons.person, size: 16),
            label: Text(
              'View ${other.role == 'officer' ? 'Officer' : 'Customer'} Profile',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(
    BuildContext ctx,
    IconData icon,
    String label,
    String value,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(ctx).colorScheme.outline),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            color: Theme.of(ctx).colorScheme.outline,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  Widget _statCard(
    BuildContext ctx,
    IconData icon,
    String label,
    String value,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(ctx).colorScheme.primary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(ctx).colorScheme.primary,
          ),
        ),
      ],
    ),
  );

  String _fmtDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _MembersTab extends StatelessWidget {
  final ConversationEntity conversation;
  final bool isAdmin;
  final void Function(String, String, String)? onAdd;
  final void Function(String, String)? onRemove;
  final void Function(String, String, String)? onPrivateMessage;
  const _MembersTab({
    required this.conversation,
    required this.isAdmin,
    this.onAdd,
    this.onRemove,
    this.onPrivateMessage,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isClosed = conversation.status == ConversationStatus.closed;
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      children: [
        if (isAdmin && !isClosed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: OutlinedButton.icon(
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Add Member'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),
        ...conversation.participants.map((p) {
          final isMe = p.id == kAdminId;
          final isOnline = p.onlineStatus == OnlineStatus.online;
          return ListTile(
            dense: true,
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _roleColor(p.role).withValues(alpha: 0.15),
                  child: Text(
                    p.name[0],
                    style: TextStyle(
                      color: _roleColor(p.role),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline
                          ? Colors.green
                          : (p.onlineStatus == OnlineStatus.away
                                ? Colors.amber
                                : cs.outline),
                      border: Border.all(color: cs.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(p.name, style: const TextStyle(fontSize: 13)),
                ),
                if (isMe)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'You',
                      style: TextStyle(fontSize: 10, color: cs.primary),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '${p.role.toUpperCase()} • ${p.lastSeenLabel}',
              style: TextStyle(fontSize: 10, color: cs.outline),
            ),
            trailing: !isMe && isAdmin
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (v) {
                      if (v == 'remove') onRemove?.call(p.id, p.name);
                      if (v == 'private')
                        onPrivateMessage?.call(p.id, p.name, p.role);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'private',
                        child: Text('Message Privately'),
                      ),
                      if (!isClosed)
                        PopupMenuItem(
                          value: 'remove',
                          child: Text(
                            'Remove',
                            style: TextStyle(color: cs.error),
                          ),
                        ),
                    ],
                  )
                : null,
          );
        }),
      ],
    );
  }

  void _showAddSheet(BuildContext context) {
    final contacts = ConversationMockDataSource().getAvailableContacts();
    final existingIds = conversation.participants.map((p) => p.id).toSet();
    final available = contacts
        .where((c) => !existingIds.contains(c['id']))
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No contacts to add')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add Member',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: available
                    .map(
                      (c) => ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: _roleColor(
                            c['role']!,
                          ).withValues(alpha: 0.15),
                          child: Text(
                            c['name']![0],
                            style: TextStyle(color: _roleColor(c['role']!)),
                          ),
                        ),
                        title: Text(c['name']!),
                        subtitle: Text(
                          c['role']!.toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onAdd?.call(c['id']!, c['name']!, c['role']!);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String r) => switch (r) {
    'officer' => Colors.teal,
    'customer' => Colors.orange,
    _ => Colors.green,
  };
}

// Fix #2: Pinned tab taps scroll to message
class _PinnedTab extends StatelessWidget {
  final List<MessageEntity> pinnedMessages;
  final void Function(String messageId)? onTap;
  const _PinnedTab({required this.pinnedMessages, this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (pinnedMessages.isEmpty)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.push_pin_outlined, size: 40, color: cs.outline),
            const SizedBox(height: 8),
            Text('No pinned messages', style: TextStyle(color: cs.outline)),
          ],
        ),
      );
    return ListView(
      padding: const EdgeInsets.all(8),
      children: pinnedMessages
          .map(
            (m) => Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: InkWell(
                onTap: () => onTap?.call(m.id),
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.push_pin,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
                  title: Text(
                    m.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    '${m.senderName} • ${_fmtTime(m.sentAt)}',
                    style: TextStyle(fontSize: 10, color: cs.outline),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: cs.outline,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// Fix #2: Search results tap scroll to message
class _SearchTab extends StatelessWidget {
  final TextEditingController searchController;
  final void Function(String)? onSearch;
  final VoidCallback? onClear;
  final List<MessageEntity>? results;
  final String? query;
  final void Function(String messageId)? onTapResult;
  const _SearchTab({
    required this.searchController,
    this.onSearch,
    this.onClear,
    this.results,
    this.query,
    this.onTapResult,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search messages...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              suffixIcon: query != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        searchController.clear();
                        onClear?.call();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => onSearch?.call(v),
          ),
        ),
        if (results != null && query != null && query!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${results!.length} result${results!.length == 1 ? '' : 's'}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: cs.outline),
            ),
          ),
        Expanded(
          child: results == null || results!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 40, color: cs.outline),
                      const SizedBox(height: 8),
                      Text(
                        query != null && query!.isNotEmpty
                            ? 'No results'
                            : 'Search in messages',
                        style: TextStyle(color: cs.outline),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(8),
                  children: results!
                      .map(
                        (m) => Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: InkWell(
                            onTap: () => onTapResult?.call(m.id),
                            borderRadius: BorderRadius.circular(10),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                m.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                '${m.senderName} • ${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.outline,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: cs.outline,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}
