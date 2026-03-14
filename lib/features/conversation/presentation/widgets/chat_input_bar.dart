import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';

class ChatInputBar extends StatefulWidget {
  final void Function(String content, String? imageUrl, {List<String>? mentionedUserIds}) onSend;
  final bool enabled;
  final MessageEntity? replyingTo;
  final VoidCallback? onCancelReply;
  final List<ConversationParticipant> participants;

  const ChatInputBar({super.key, required this.onSend, this.enabled = true,
    this.replyingTo, this.onCancelReply, this.participants = const []});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _pendingImagePath;
  bool _showMentions = false;
  String _mentionQuery = '';

  @override
  void didUpdateWidget(ChatInputBar old) {
    super.didUpdateWidget(old);
    if (widget.replyingTo != null && old.replyingTo == null) _focusNode.requestFocus();
  }

  @override
  void dispose() { _controller.dispose(); _focusNode.dispose(); super.dispose(); }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImagePath == null) return;
    final mentions = _extractMentions(text);
    widget.onSend(text, _pendingImagePath, mentionedUserIds: mentions.isNotEmpty ? mentions : null);
    _controller.clear(); setState(() { _pendingImagePath = null; _showMentions = false; });
    _focusNode.requestFocus();
  }

  List<String> _extractMentions(String text) {
    final mentions = <String>[];
    if (text.contains('@all')) mentions.add('all');
    for (final p in widget.participants) {
      final tag = '@${p.name.split(' ').first}';
      if (text.contains(tag)) mentions.add(p.id);
    }
    return mentions;
  }

  void _onTextChanged(String text) {
    setState(() {
      final lastAt = text.lastIndexOf('@');
      if (lastAt != -1 && (lastAt == 0 || text[lastAt - 1] == ' ')) {
        _showMentions = true;
        _mentionQuery = text.substring(lastAt + 1).toLowerCase();
      } else { _showMentions = false; }
    });
  }

  void _insertMention(String name) {
    final text = _controller.text;
    final lastAt = text.lastIndexOf('@');
    if (lastAt == -1) return;
    final firstName = name.split(' ').first;
    _controller.text = '${text.substring(0, lastAt)}@$firstName ';
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    setState(() => _showMentions = false);
    _focusNode.requestFocus();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 80);
      if (file != null) setState(() => _pendingImagePath = file.path);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasContent = _controller.text.trim().isNotEmpty || _pendingImagePath != null;
    final filteredParticipants = widget.participants.where((p) =>
        p.id != 'admin-001' && p.name.toLowerCase().contains(_mentionQuery)).toList();

    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Mention suggestions
      if (_showMentions && filteredParticipants.isNotEmpty)
        Container(constraints: const BoxConstraints(maxHeight: 180),
          decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)))),
          child: ListView(shrinkWrap: true, padding: EdgeInsets.zero, children: [
            ListTile(dense: true, leading: const Icon(Icons.group, size: 18), title: const Text('@all — Mention everyone'),
              onTap: () { _controller.text = '${_controller.text.substring(0, _controller.text.lastIndexOf('@'))}@all ';
                _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
                setState(() => _showMentions = false); _focusNode.requestFocus(); }),
            ...filteredParticipants.map((p) => ListTile(dense: true,
              leading: CircleAvatar(radius: 14, backgroundColor: _roleColor(p.role).withValues(alpha: 0.15),
                child: Text(p.name[0], style: TextStyle(color: _roleColor(p.role), fontSize: 12, fontWeight: FontWeight.w600))),
              title: Text(p.name, style: const TextStyle(fontSize: 13)), subtitle: Text(p.role.toUpperCase(), style: const TextStyle(fontSize: 10)),
              onTap: () => _insertMention(p.name)))])),

      // Reply preview
      if (widget.replyingTo != null) Container(padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.06),
          border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)), left: BorderSide(color: cs.primary, width: 3))),
        child: Row(children: [Icon(Icons.reply, size: 16, color: cs.primary), const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Replying to ${widget.replyingTo!.senderName}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 1),
            Text(widget.replyingTo!.isImage ? '📷 Photo' : widget.replyingTo!.content, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 12))])),
          IconButton(icon: Icon(Icons.close, size: 18, color: cs.outline), onPressed: widget.onCancelReply, padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32))])),

      // Pending image
      if (_pendingImagePath != null) Container(height: 80, margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [const SizedBox(width: 80, height: 80, child: Center(child: Icon(Icons.image, size: 32))),
          const Spacer(), IconButton(icon: Icon(Icons.close, color: cs.error), onPressed: () => setState(() => _pendingImagePath = null))])),

      // Input bar
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(color: cs.surface,
          border: widget.replyingTo == null ? Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))) : null),
        child: SafeArea(top: false, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          IconButton(icon: Icon(Icons.attach_file, color: cs.onSurfaceVariant), onPressed: widget.enabled ? () =>
            showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
              builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }),
                ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); })])))) : null),
          Expanded(child: Container(constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24)),
            child: TextField(controller: _controller, focusNode: _focusNode, enabled: widget.enabled, maxLines: 5, minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: widget.enabled ? 'Type a message... (@ to mention)' : 'Closed', hintStyle: TextStyle(color: cs.outline),
                border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
              onChanged: _onTextChanged, onSubmitted: (_) => _handleSend()))),
          const SizedBox(width: 4),
          IconButton.filled(icon: const Icon(Icons.send, size: 20),
            style: IconButton.styleFrom(backgroundColor: hasContent && widget.enabled ? cs.primary : cs.outline, foregroundColor: hasContent && widget.enabled ? cs.onPrimary : cs.surface),
            onPressed: hasContent && widget.enabled ? _handleSend : null),
        ]))),
    ]);
  }

  Color _roleColor(String role) => switch (role) { 'officer' => Colors.teal, 'customer' => Colors.orange, _ => Colors.green };
}