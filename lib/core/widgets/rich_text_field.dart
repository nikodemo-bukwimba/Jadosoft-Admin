import 'package:flutter/material.dart';

/// A rich-text-capable input field supporting:
/// - Numbered lists: type "1. " → auto-continues "2. " on next line
/// - Bullet lists: type "- " → auto-continues "- " on next line
/// - Bold: wrap selection with **text**
/// - The toolbar shows formatting actions above the keyboard
class RichTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int minLines;
  final int maxLines;
  final bool highlight;

  const RichTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.minLines = 3,
    this.maxLines = 8,
    this.highlight = false,
  });

  @override
  State<RichTextField> createState() => _RichTextFieldState();
}

class _RichTextFieldState extends State<RichTextField> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() => setState(() => _focused = _focusNode.hasFocus));
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(() {});
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      return;
    }
    final cursor = selection.baseOffset;
    if (cursor <= 0 || cursor > text.length) return;

    if (text[cursor - 1] != '\n') return;

    final beforeCursor = text.substring(0, cursor - 1);
    final lastNewline = beforeCursor.lastIndexOf('\n');
    final prevLine = beforeCursor.substring(lastNewline + 1);

    String? prefix;

    final numberedMatch = RegExp(r'^(\d+)\.\s').firstMatch(prevLine);
    if (numberedMatch != null) {
      final num = int.parse(numberedMatch.group(1)!) + 1;
      prefix = '$num. ';
    }

    if (prefix == null && prevLine.startsWith('- ')) {
      if (prevLine.trim() == '-') {
        final newText = text.substring(0, cursor - 1 - prevLine.length) +
            text.substring(cursor - 1);
        widget.controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: cursor - 1 - prevLine.length,
          ),
        );
        return;
      }
      prefix = '- ';
    }

    if (prefix == null) return;

    final newText = text.substring(0, cursor) + prefix + text.substring(cursor);
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + prefix.length),
    );
  }

  void _insertBullet() {
    final c = widget.controller;
    final sel = c.selection;
    final text = c.text;
    final cursor = sel.isValid ? sel.baseOffset : text.length;

    final before = text.substring(0, cursor);
    final lineStart = before.lastIndexOf('\n') + 1;
    final linePrefix = before.substring(lineStart);

    String insert;
    int newCursor;

    if (linePrefix.isEmpty || linePrefix == '\n') {
      insert = '- ';
      newCursor = cursor + 2;
    } else {
      insert = '\n- ';
      newCursor = cursor + 3;
    }

    final newText = text.substring(0, cursor) + insert + text.substring(cursor);
    c.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  void _insertNumbered() {
    final c = widget.controller;
    final sel = c.selection;
    final text = c.text;
    final cursor = sel.isValid ? sel.baseOffset : text.length;

    final before = text.substring(0, cursor);
    final lineStart = before.lastIndexOf('\n') + 1;
    final linePrefix = before.substring(lineStart);

    int nextNum = 1;
    final lines = before.split('\n');
    for (final line in lines.reversed) {
      final m = RegExp(r'^(\d+)\.\s').firstMatch(line);
      if (m != null) {
        nextNum = int.parse(m.group(1)!) + 1;
        break;
      }
    }

    String insert;
    int newCursor;

    if (linePrefix.isEmpty) {
      insert = '$nextNum. ';
      newCursor = cursor + insert.length;
    } else {
      insert = '\n$nextNum. ';
      newCursor = cursor + insert.length;
    }

    final newText = text.substring(0, cursor) + insert + text.substring(cursor);
    c.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  void _wrapBold() {
    final c = widget.controller;
    final sel = c.selection;
    if (!sel.isValid || sel.isCollapsed) return;
    final text = c.text;
    final selected = sel.textInside(text);
    final newText = text.replaceRange(sel.start, sel.end, '**$selected**');
    c.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: sel.start + selected.length + 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.highlight
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;

    final enabledBorder = widget.highlight
        ? OutlineInputBorder(
            borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
          )
        : const OutlineInputBorder();

    final focusedBorder = widget.highlight
        ? OutlineInputBorder(borderSide: BorderSide(color: color, width: 2))
        : null;

    final labelStyle = widget.highlight ? TextStyle(color: color) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState:
              _focused ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(height: 0),
          secondChild: Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _ToolbarButton(
                  icon: Icons.format_list_bulleted,
                  tooltip: 'Bullet list',
                  onTap: _insertBullet,
                ),
                _ToolbarButton(
                  icon: Icons.format_list_numbered,
                  tooltip: 'Numbered list',
                  onTap: _insertNumbered,
                ),
                _ToolbarButton(
                  icon: Icons.format_bold,
                  tooltip: 'Bold (select text first)',
                  onTap: _wrapBold,
                ),
                const VerticalDivider(width: 1, indent: 6, endIndent: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '**bold**  •  - bullet  •  1. numbered',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            border: const OutlineInputBorder(),
            enabledBorder: enabledBorder,
            focusedBorder: focusedBorder,
            alignLabelWithHint: true,
            labelStyle: labelStyle,
          ),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
