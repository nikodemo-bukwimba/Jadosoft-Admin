import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../data/datasources/conversation_mock_datasource.dart';
import '../../domain/entities/conversation_entity.dart';
import '../bloc/conversation_bloc.dart';
import '../bloc/conversation_event.dart';
import '../bloc/conversation_state.dart';

enum ConversationFormMode { create, edit }

class ConversationFormPage extends StatefulWidget {
  final ConversationFormMode mode;
  final String? id;
  const ConversationFormPage({super.key, required this.mode, this.id});
  @override
  State<ConversationFormPage> createState() => _ConversationFormPageState();
}

class _ConversationFormPageState extends State<ConversationFormPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _broadcastMsgController = TextEditingController();
  String _type = 'direct';
  final Set<String> _selectedIds = {};
  final Set<String> _broadcastConvIds = {};
  final Set<String> _broadcastNewContactIds = {};
  late final List<Map<String, String>> _contacts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _contacts = ConversationMockDataSource().getAvailableContacts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _broadcastMsgController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_selectedIds.isEmpty) return false;
    if (_type == 'direct' && _selectedIds.length != 1) return false;
    if (_type == 'group' && _selectedIds.length < 2) return false;
    if (_type == 'group' && _titleController.text.trim().isEmpty) return false;
    return true;
  }

  void _submit() {
    if (!_canSubmit) return;
    context.read<ConversationBloc>().add(
      ConversationStartNewRequested(
        type: _type,
        title: _type == 'group' ? _titleController.text.trim() : null,
        participants: _contacts
            .where((c) => _selectedIds.contains(c['id']))
            .toList(),
        firstMessage: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
      ),
    );
  }

  void _submitBroadcast() {
    final msg = _broadcastMsgController.text.trim();
    if (msg.isEmpty) return;
    if (_broadcastConvIds.isEmpty && _broadcastNewContactIds.isEmpty) return;
    final bloc = context.read<ConversationBloc>();
    if (_broadcastConvIds.isNotEmpty) {
      bloc.add(
        ConversationBroadcastRequested(
          conversationIds: _broadcastConvIds.toList(),
          content: msg,
        ),
      );
    }
    for (final contactId in _broadcastNewContactIds) {
      final contact = _contacts.firstWhere((c) => c['id'] == contactId);
      bloc.add(
        ConversationStartNewRequested(
          type: 'direct',
          participants: [contact],
          firstMessage: msg,
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Broadcasting to ${_broadcastConvIds.length + _broadcastNewContactIds.length} recipients...',
        ),
      ),
    );
    context.go('/conversations');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;
    return BlocListener<ConversationBloc, ConversationState>(
      listener: (ctx, state) {
        if (state is ConversationNewCreated)
          ctx.go(AppRouter.conversationDetailPath(state.conversationId));
        if (state is ConversationFailure)
          ScaffoldMessenger.of(
            ctx,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        if (state is ConversationBroadcastSuccess) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('Sent to ${state.sentCount} conversations')),
          );
          ctx.go('/conversations');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/conversations'),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Conversation'),
              Tab(text: 'Broadcast'),
            ],
          ),
        ),
        body: BlocBuilder<ConversationBloc, ConversationState>(
          builder: (ctx, state) {
            if (state is ConversationLoading)
              return const Center(child: CircularProgressIndicator());
            return TabBarView(
              controller: _tabController,
              children: [
                _buildNewConversationTab(context, isWide),
                _buildBroadcastTab(context, isWide),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNewConversationTab(BuildContext context, bool isWide) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TypeCard(
                      icon: Icons.person,
                      label: 'Direct',
                      subtitle: '1-on-1',
                      selected: _type == 'direct',
                      onTap: () => setState(() {
                        _type = 'direct';
                        if (_selectedIds.length > 1) _selectedIds.clear();
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeCard(
                      icon: Icons.group,
                      label: 'Group',
                      subtitle: 'Up to 10',
                      selected: _type == 'group',
                      onTap: () => setState(() => _type = 'group'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_type == 'group') ...[
                Text(
                  'Group Name',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter group name...',
                    prefixIcon: const Icon(Icons.group),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  Text(
                    _type == 'direct'
                        ? 'Select Contact'
                        : 'Select Participants',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_type == 'group')
                    Text(
                      '${_selectedIds.length}/10',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: cs.outline),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _SectionHeader(
                label: 'Officers',
                icon: Icons.badge,
                color: Colors.teal,
              ),
              const SizedBox(height: 4),
              ..._contacts
                  .where((c) => c['role'] == 'officer')
                  .map(
                    (c) => _ContactTile(
                      contact: c,
                      selected: _selectedIds.contains(c['id']),
                      onTap: () => _toggle(c['id']!),
                    ),
                  ),
              const SizedBox(height: 16),
              _SectionHeader(
                label: 'Customers',
                icon: Icons.storefront,
                color: Colors.orange,
              ),
              const SizedBox(height: 4),
              ..._contacts
                  .where((c) => c['role'] == 'customer')
                  .map(
                    (c) => _ContactTile(
                      contact: c,
                      selected: _selectedIds.contains(c['id']),
                      onTap: () => _toggle(c['id']!),
                    ),
                  ),
              const SizedBox(height: 24),
              Text(
                'First Message (Optional)',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Type your first message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _canSubmit ? _submit : null,
                  icon: const Icon(Icons.send),
                  label: Text(
                    _type == 'direct' ? 'Start Conversation' : 'Create Group',
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Fix #4: Broadcast tab with existing conversations at top, all contacts below
  Widget _buildBroadcastTab(BuildContext context, bool isWide) {
    final cs = Theme.of(context).colorScheme;
    final mockDs = ConversationMockDataSource();
    final existingConvs = mockDs.getAdminConversations();
    final existingDirectParticipantIds = existingConvs
        .where((c) => c.type == ConversationType.direct)
        .expand(
          (c) => c.participants.where((p) => p.id != kAdminId).map((p) => p.id),
        )
        .toSet();
    final newContacts = _contacts
        .where((c) => !existingDirectParticipantIds.contains(c['id']))
        .toList();
    final totalSelected =
        _broadcastConvIds.length + _broadcastNewContactIds.length;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Broadcast message
              Text(
                'Broadcast Message',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _broadcastMsgController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type the message to broadcast...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.campaign),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              // Existing conversations
              Text(
                'Existing Conversations',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Send to conversations you already have',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.outline),
              ),
              const SizedBox(height: 8),
              ...existingConvs.map(
                (c) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: _broadcastConvIds.contains(c.id)
                          ? cs.primary
                          : cs.outlineVariant.withValues(alpha: 0.3),
                      width: _broadcastConvIds.contains(c.id) ? 1.5 : 0.5,
                    ),
                  ),
                  color: _broadcastConvIds.contains(c.id)
                      ? cs.primaryContainer.withValues(alpha: 0.15)
                      : null,
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: cs.primaryContainer,
                      child: c.type == ConversationType.group
                          ? Icon(Icons.group, size: 16, color: cs.primary)
                          : Text(
                              c.displayName(kAdminId)[0],
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    title: Text(
                      c.displayName(kAdminId),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _broadcastConvIds.contains(c.id)
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    subtitle: Text(
                      c.type == ConversationType.group
                          ? 'Group • ${c.participants.length} members'
                          : 'Direct',
                      style: TextStyle(fontSize: 10, color: cs.outline),
                    ),
                    trailing: _broadcastConvIds.contains(c.id)
                        ? Icon(Icons.check_circle, color: cs.primary)
                        : Icon(
                            Icons.circle_outlined,
                            color: cs.outlineVariant,
                            size: 20,
                          ),
                    onTap: () => setState(() {
                      if (_broadcastConvIds.contains(c.id))
                        _broadcastConvIds.remove(c.id);
                      else
                        _broadcastConvIds.add(c.id);
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // New contacts (no existing conversation)
              if (newContacts.isNotEmpty) ...[
                Text(
                  'New Recipients',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'A new conversation will be created for each',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.outline),
                ),
                const SizedBox(height: 8),
                _SectionHeader(
                  label: 'Officers',
                  icon: Icons.badge,
                  color: Colors.teal,
                ),
                const SizedBox(height: 4),
                ...newContacts
                    .where((c) => c['role'] == 'officer')
                    .map(
                      (c) => _ContactTile(
                        contact: c,
                        selected: _broadcastNewContactIds.contains(c['id']),
                        onTap: () => setState(() {
                          if (_broadcastNewContactIds.contains(c['id']))
                            _broadcastNewContactIds.remove(c['id']);
                          else
                            _broadcastNewContactIds.add(c['id']!);
                        }),
                      ),
                    ),
                const SizedBox(height: 8),
                _SectionHeader(
                  label: 'Customers',
                  icon: Icons.storefront,
                  color: Colors.orange,
                ),
                const SizedBox(height: 4),
                ...newContacts
                    .where((c) => c['role'] == 'customer')
                    .map(
                      (c) => _ContactTile(
                        contact: c,
                        selected: _broadcastNewContactIds.contains(c['id']),
                        onTap: () => setState(() {
                          if (_broadcastNewContactIds.contains(c['id']))
                            _broadcastNewContactIds.remove(c['id']);
                          else
                            _broadcastNewContactIds.add(c['id']!);
                        }),
                      ),
                    ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed:
                      totalSelected > 0 &&
                          _broadcastMsgController.text.trim().isNotEmpty
                      ? _submitBroadcast
                      : null,
                  icon: const Icon(Icons.campaign),
                  label: Text(
                    'Broadcast to $totalSelected recipient${totalSelected == 1 ? '' : 's'}',
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(String id) {
    setState(() {
      if (_type == 'direct') {
        if (_selectedIds.contains(id))
          _selectedIds.remove(id);
        else {
          _selectedIds.clear();
          _selectedIds.add(id);
        }
      } else {
        if (_selectedIds.contains(id))
          _selectedIds.remove(id);
        else if (_selectedIds.length < 10)
          _selectedIds.add(id);
        else
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Max 10 participants')));
      }
    });
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _TypeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? cs.primary : cs.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      color: selected ? cs.primaryContainer.withValues(alpha: 0.3) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.primary : cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: cs.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 2),
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _ContactTile extends StatelessWidget {
  final Map<String, String> contact;
  final bool selected;
  final VoidCallback onTap;
  const _ContactTile({
    required this.contact,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = contact['role'] == 'officer' ? Colors.teal : Colors.orange;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.3),
          width: selected ? 1.5 : 0.5,
        ),
      ),
      color: selected ? cs.primaryContainer.withValues(alpha: 0.15) : null,
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            contact['name']![0],
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
        title: Text(
          contact['name']!,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: selected
            ? Icon(Icons.check_circle, color: cs.primary)
            : Icon(Icons.circle_outlined, color: cs.outlineVariant, size: 20),
      ),
    );
  }
}
