import 'package:flutter/material.dart';

/// A modal bottom sheet with a search field + single-select list.
/// Returns the selected [value] or null if dismissed.
Future<T?> showSearchablePicker<T>({
  required BuildContext context,
  required String title,
  required List<({T value, String label, String? subtitle})> items,
  T? selected,
  String hint = 'Search...',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SearchablePickerSheet<T>(
      title: title,
      items: items,
      selected: selected,
      hint: hint,
    ),
  );
}

/// A modal bottom sheet with search + multi-select checkboxes.
/// Returns the updated [Set<T>] or null if dismissed.
Future<Set<T>?> showSearchableMultiPicker<T>({
  required BuildContext context,
  required String title,
  required List<({T value, String label, String? subtitle})> items,
  required Set<T> selected,
  String hint = 'Search...',
}) {
  return showModalBottomSheet<Set<T>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SearchableMultiPickerSheet<T>(
      title: title,
      items: items,
      selected: selected,
      hint: hint,
    ),
  );
}

// ── Single picker ─────────────────────────────────────────────────────────────

class _SearchablePickerSheet<T> extends StatefulWidget {
  final String title;
  final List<({T value, String label, String? subtitle})> items;
  final T? selected;
  final String hint;
  const _SearchablePickerSheet({
    required this.title,
    required this.items,
    required this.selected,
    required this.hint,
  });
  @override
  State<_SearchablePickerSheet<T>> createState() =>
      _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T>
    extends State<_SearchablePickerSheet<T>> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _q.isEmpty
        ? widget.items
        : widget.items
            .where((e) => e.label.toLowerCase().contains(_q.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(widget.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _q.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _ctrl.clear(); setState(() => _q = ''); })
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('No results', style: TextStyle(color: cs.onSurfaceVariant)))
              : ListView.builder(
                  controller: scrollCtrl,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final isSel = item.value == widget.selected;
                    return ListTile(
                      title: Text(item.label),
                      subtitle: item.subtitle != null ? Text(item.subtitle!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)) : null,
                      trailing: isSel ? Icon(Icons.check_circle, color: cs.primary) : null,
                      selected: isSel,
                      selectedColor: cs.primary,
                      onTap: () => Navigator.of(context).pop(item.value),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ── Multi picker ──────────────────────────────────────────────────────────────

class _SearchableMultiPickerSheet<T> extends StatefulWidget {
  final String title;
  final List<({T value, String label, String? subtitle})> items;
  final Set<T> selected;
  final String hint;
  const _SearchableMultiPickerSheet({
    required this.title,
    required this.items,
    required this.selected,
    required this.hint,
  });
  @override
  State<_SearchableMultiPickerSheet<T>> createState() =>
      _SearchableMultiPickerSheetState<T>();
}

class _SearchableMultiPickerSheetState<T>
    extends State<_SearchableMultiPickerSheet<T>> {
  final _ctrl = TextEditingController();
  String _q = '';
  late final Set<T> _sel;

  @override
  void initState() { super.initState(); _sel = Set.from(widget.selected); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _q.isEmpty
        ? widget.items
        : widget.items
            .where((e) => e.label.toLowerCase().contains(_q.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            Text('${_sel.length} selected', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _q.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _ctrl.clear(); setState(() => _q = ''); })
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('No results', style: TextStyle(color: cs.onSurfaceVariant)))
              : ListView.builder(
                  controller: scrollCtrl,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final isSel = _sel.contains(item.value);
                    return CheckboxListTile(
                      value: isSel,
                      title: Text(item.label),
                      subtitle: item.subtitle != null ? Text(item.subtitle!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)) : null,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      onChanged: (v) => setState(() => v == true ? _sel.add(item.value) : _sel.remove(item.value)),
                    );
                  },
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(Set<T>.from(_sel)),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            child: Text('Confirm (${_sel.length})'),
          ),
        ),
      ]),
    );
  }
}