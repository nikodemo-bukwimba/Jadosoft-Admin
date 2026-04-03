import 'package:flutter/material.dart';

/// GitHub-style confirmation dialog — user must type the exact resource name.
/// Returns true only when the typed name matches and the user confirms.
class ProductConfirmNameDialog extends StatefulWidget {
  final String title;
  final String productName;
  final String actionLabel;
  final Color actionColor;
  final String warningMessage;

  const ProductConfirmNameDialog({
    super.key,
    required this.title,
    required this.productName,
    required this.actionLabel,
    required this.actionColor,
    required this.warningMessage,
  });

  /// Convenience launcher — returns true if confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String productName,
    required String actionLabel,
    required Color actionColor,
    required String warningMessage,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductConfirmNameDialog(
        title: title,
        productName: productName,
        actionLabel: actionLabel,
        actionColor: actionColor,
        warningMessage: warningMessage,
      ),
    );
    return result ?? false;
  }

  @override
  State<ProductConfirmNameDialog> createState() =>
      _ProductConfirmNameDialogState();
}

class _ProductConfirmNameDialogState extends State<ProductConfirmNameDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final matches = _controller.text.trim() == widget.productName;
      if (matches != _matches) setState(() => _matches = matches);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.warningMessage,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'To confirm, type the product name below:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.productName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Type product name to confirm',
              border: const OutlineInputBorder(),
              errorText: _controller.text.isNotEmpty && !_matches
                  ? 'Name does not match'
                  : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: widget.actionColor),
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}