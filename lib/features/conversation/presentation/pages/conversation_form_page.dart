import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../data/datasources/conversation_mock_datasource.dart';
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

class _ConversationFormPageState extends State<ConversationFormPage> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _type = 'direct';
  final Set<String> _selectedIds = {};
  late final List<Map<String, String>> _contacts;

  @override
  void initState() { super.initState(); _contacts = ConversationMockDataSource().getAvailableContacts(); }
  @override
  void dispose() { _titleController.dispose(); _messageController.dispose(); super.dispose(); }

  bool get _canSubmit {
    if (_selectedIds.isEmpty) return false;
    if (_type == 'direct' && _selectedIds.length != 1) return false;
    if (_type == 'group' && _selectedIds.length < 2) return false;
    if (_type == 'group' && _titleController.text.trim().isEmpty) return false;
    return true;
  }

  void _submit() {
    if (!_canSubmit) return;
    context.read<ConversationBloc>().add(ConversationStartNewRequested(type: _type,
      title: _type == 'group' ? _titleController.text.trim() : null,
      participants: _contacts.where((c) => _selectedIds.contains(c['id'])).toList(),
      firstMessage: _messageController.text.trim().isNotEmpty ? _messageController.text.trim() : null));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;
    return BlocListener<ConversationBloc, ConversationState>(
      listener: (ctx, state) {
        if (state is ConversationNewCreated) ctx.go(AppRouter.conversationDetailPath(state.conversationId));
        if (state is ConversationFailure) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message)));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('New Conversation'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/conversations'))),
        body: BlocBuilder<ConversationBloc, ConversationState>(builder: (ctx, state) {
          if (state is ConversationLoading) return const Center(child: CircularProgressIndicator());
          return SingleChildScrollView(padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 16),
            child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Conversation Type', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _TypeCard(icon: Icons.person, label: 'Direct', subtitle: '1-on-1', selected: _type == 'direct',
                    onTap: () => setState(() { _type = 'direct'; if (_selectedIds.length > 1) _selectedIds.clear(); }))),
                  const SizedBox(width: 12),
                  Expanded(child: _TypeCard(icon: Icons.group, label: 'Group', subtitle: 'Up to 10', selected: _type == 'group',
                    onTap: () => setState(() => _type = 'group')))]),
                const SizedBox(height: 24),
                if (_type == 'group') ...[
                  Text('Group Name', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: _titleController, decoration: InputDecoration(hintText: 'Enter group name...', prefixIcon: const Icon(Icons.group),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (_) => setState(() {})),
                  const SizedBox(height: 24)],
                Row(children: [
                  Text(_type == 'direct' ? 'Select Contact' : 'Select Participants', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (_type == 'group') Text('${_selectedIds.length}/10', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.outline))]),
                const SizedBox(height: 8),
                _SectionHeader(label: 'Officers', icon: Icons.badge, color: Colors.teal), const SizedBox(height: 4),
                ..._contacts.where((c) => c['role'] == 'officer').map((c) => _ContactTile(contact: c, selected: _selectedIds.contains(c['id']), onTap: () => _toggle(c['id']!))),
                const SizedBox(height: 16),
                _SectionHeader(label: 'Customers', icon: Icons.storefront, color: Colors.orange), const SizedBox(height: 4),
                ..._contacts.where((c) => c['role'] == 'customer').map((c) => _ContactTile(contact: c, selected: _selectedIds.contains(c['id']), onTap: () => _toggle(c['id']!))),
                const SizedBox(height: 24),
                Text('First Message (Optional)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(controller: _messageController, maxLines: 3, decoration: InputDecoration(hintText: 'Type your first message...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(onPressed: _canSubmit ? _submit : null,
                  icon: const Icon(Icons.send), label: Text(_type == 'direct' ? 'Start Conversation' : 'Create Group'))),
                const SizedBox(height: 32),
              ]))));
        })));
  }

  void _toggle(String id) {
    setState(() {
      if (_type == 'direct') { if (_selectedIds.contains(id)) _selectedIds.remove(id); else { _selectedIds.clear(); _selectedIds.add(id); } }
      else { if (_selectedIds.contains(id)) _selectedIds.remove(id); else if (_selectedIds.length < 10) _selectedIds.add(id);
        else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 10 participants'))); }
    });
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon; final String label; final String subtitle; final bool selected; final VoidCallback onTap;
  const _TypeCard({required this.icon, required this.label, required this.subtitle, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) { final cs = Theme.of(context).colorScheme;
    return Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 2 : 1)),
      color: selected ? cs.primaryContainer.withValues(alpha: 0.3) : null,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.all(16),
        child: Column(children: [Icon(icon, size: 32, color: selected ? cs.primary : cs.onSurfaceVariant), const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? cs.primary : cs.onSurface)), const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.outline))])))); }
}

class _SectionHeader extends StatelessWidget {
  final String label; final IconData icon; final Color color;
  const _SectionHeader({required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 4, bottom: 2),
    child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600))]));
}

class _ContactTile extends StatelessWidget {
  final Map<String, String> contact; final bool selected; final VoidCallback onTap;
  const _ContactTile({required this.contact, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) { final cs = Theme.of(context).colorScheme; final isOfficer = contact['role'] == 'officer'; final color = isOfficer ? Colors.teal : Colors.orange;
    return Card(elevation: 0, margin: const EdgeInsets.symmetric(vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.3), width: selected ? 1.5 : 0.5)),
      color: selected ? cs.primaryContainer.withValues(alpha: 0.15) : null,
      child: ListTile(onTap: onTap, dense: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: CircleAvatar(radius: 18, backgroundColor: color.withValues(alpha: 0.15), child: Text(contact['name']![0], style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        title: Text(contact['name']!, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        trailing: selected ? Icon(Icons.check_circle, color: cs.primary) : Icon(Icons.circle_outlined, color: cs.outlineVariant, size: 20))); }
}