import 'package:flutter/material.dart';

class OrderConfirmDeleteDialog extends StatefulWidget {
  final String orderId;

  const OrderConfirmDeleteDialog({super.key, required this.orderId});

  static Future<bool> show(BuildContext context, {required String orderId}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrderConfirmDeleteDialog(orderId: orderId),
    );
    return result ?? false;
  }

  @override
  State<OrderConfirmDeleteDialog> createState() => _State();
}

class _State extends State<OrderConfirmDeleteDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  String get _displayId => widget.orderId.split('-').last.toUpperCase();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final matches = _controller.text.trim().toUpperCase() == _displayId;
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
      title: const Text('Delete Order?'),
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
              'This action is irreversible. The order will be permanently removed.',
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'To confirm, type the order ID below:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _displayId,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Type order ID to confirm',
              border: const OutlineInputBorder(),
              errorText: _controller.text.isNotEmpty && !_matches
                  ? 'ID does not match'
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
          style: FilledButton.styleFrom(
              backgroundColor: scheme.error),
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}