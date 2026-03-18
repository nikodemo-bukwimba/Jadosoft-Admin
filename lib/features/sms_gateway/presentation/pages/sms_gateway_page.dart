import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/sms_gateway_cubit.dart';
import '../cubit/sms_gateway_state.dart';
import '../widgets/sms_gateway_sync_status.dart';
import '../../domain/models/send_sms_request.dart';

class SmsGatewayPage extends StatefulWidget {
  const SmsGatewayPage({super.key});

  @override
  State<SmsGatewayPage> createState() => _SmsGatewayPageState();
}

class _SmsGatewayPageState extends State<SmsGatewayPage> {
  // Send SMS form
  final _sendFormKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final _messageController = TextEditingController();
  final _fromController = TextEditingController();

  // Delivery status form
  final _statusFormKey = GlobalKey<FormState>();
  final _messageIdController = TextEditingController();

  // Track last sent messageId for quick status check
  String? _lastSentMessageId;

  @override
  void dispose() {
    _toController.dispose();
    _messageController.dispose();
    _fromController.dispose();
    _messageIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Gateway'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.circle, size: 10, color: Colors.green),
              label: const Text('Mock Mode'),
              labelStyle: Theme.of(context).textTheme.labelSmall,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: BlocConsumer<SmsGatewayCubit, SmsGatewayState>(
        listener: (context, state) {
          // Show success snackbar after send and capture messageId
          if (!state.isSendSmsLoading &&
              state.sendSmsError == null &&
              state.lastSentMessageId != null &&
              state.lastSyncAt != null) {
            setState(() {
              _lastSentMessageId = state.lastSentMessageId;
              _messageIdController.text = state.lastSentMessageId!;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('SMS sent — ID: ${state.lastSentMessageId}'),
                ]),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmsGatewaySyncStatus(
                  lastSyncAt: state.lastSyncAt,
                  isLoading: state.isLoading,
                ),
                const SizedBox(height: 20),

                // ── Send SMS ──────────────────────────────────────
                _SectionHeader(icon: Icons.send, label: 'Send SMS'),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _sendFormKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _toController,
                            decoration: const InputDecoration(
                              labelText: 'Recipient Phone *',
                              hintText: '+255712345678',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Recipient phone is required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              labelText: 'Message *',
                              hintText: 'Type your SMS message...',
                              prefixIcon: Icon(Icons.message),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            maxLength: 160,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Message is required'
                                : null,
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _fromController,
                            decoration: const InputDecoration(
                              labelText: 'Sender ID (optional)',
                              hintText: 'BARICK',
                              prefixIcon: Icon(Icons.business),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (state.sendSmsError != null)
                            _ErrorBanner(message: state.sendSmsError!),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: state.isSendSmsLoading
                                  ? null
                                  : () => _handleSendSms(context),
                              icon: state.isSendSmsLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Icon(Icons.send),
                              label: Text(state.isSendSmsLoading
                                  ? 'Sending...'
                                  : 'Send SMS'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Delivery Status ───────────────────────────────
                _SectionHeader(
                    icon: Icons.track_changes, label: 'Delivery Status'),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _statusFormKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _messageIdController,
                            decoration: InputDecoration(
                              labelText: 'Message ID *',
                              hintText: 'Paste message ID here',
                              prefixIcon: const Icon(Icons.fingerprint),
                              suffixIcon: _lastSentMessageId != null
                                  ? Tooltip(
                                      message: 'Use last sent ID',
                                      child: IconButton(
                                        icon: const Icon(Icons.history),
                                        onPressed: () => setState(() =>
                                            _messageIdController.text =
                                                _lastSentMessageId!),
                                      ),
                                    )
                                  : null,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Message ID is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          if (state.getDeliveryStatusError != null)
                            _ErrorBanner(
                                message: state.getDeliveryStatusError!),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: state.isGetDeliveryStatusLoading
                                  ? null
                                  : () => _handleGetStatus(context),
                              icon: state.isGetDeliveryStatusLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Icon(Icons.search),
                              label: Text(state.isGetDeliveryStatusLoading
                                  ? 'Checking...'
                                  : 'Check Status'),
                            ),
                          ),
                          // Result
                          if (state.getDeliveryStatusResult != null) ...[
                            const SizedBox(height: 16),
                            _DeliveryStatusResult(
                                result: state.getDeliveryStatusResult!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Webhooks (info) ───────────────────────────────
                _SectionHeader(icon: Icons.webhook, label: 'Webhook Events'),
                const SizedBox(height: 12),
                _WebhookInfoCard(events: const [
                  _WebhookEvent(
                      event: 'message.delivered',
                      label: 'Message Delivered',
                      color: Colors.green),
                  _WebhookEvent(
                      event: 'message.failed',
                      label: 'Message Failed',
                      color: Colors.red),
                ]),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleSendSms(BuildContext context) {
    if (!_sendFormKey.currentState!.validate()) return;
    context.read<SmsGatewayCubit>().sendSms(
          SendSmsRequest(
            to: _toController.text.trim(),
            message: _messageController.text.trim(),
            from: _fromController.text.trim().isEmpty
                ? null
                : _fromController.text.trim(),
          ),
        );
  }

  void _handleGetStatus(BuildContext context) {
    if (!_statusFormKey.currentState!.validate()) return;
    context
        .read<SmsGatewayCubit>()
        .getDeliveryStatus(_messageIdController.text.trim());
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(label, style: Theme.of(context).textTheme.titleMedium),
    ]);
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, size: 16, color: scheme.error),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onErrorContainer))),
      ]),
    );
  }
}

class _DeliveryStatusResult extends StatelessWidget {
  final dynamic result;
  const _DeliveryStatusResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDelivered = result.status == 'delivered';
    final statusColor = isDelivered ? Colors.green : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Result',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        _ResultRow(label: 'Message ID', value: result.messageId),
        _ResultRow(
          label: 'Status',
          value: result.status.toUpperCase(),
          valueColor: statusColor,
        ),
        if (result.deliveredAt != null)
          _ResultRow(
              label: 'Delivered At',
              value: result.deliveredAt.toString().split('.').first),
        if (result.errorCode != null)
          _ResultRow(
              label: 'Error Code',
              value: result.errorCode,
              valueColor: scheme.error),
        if (result.errorMessage != null)
          _ResultRow(label: 'Error', value: result.errorMessage),
      ]),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String? value;
  final Color? valueColor;
  const _ResultRow({required this.label, this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value ?? '-',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                      fontWeight: FontWeight.w600, color: valueColor)),
        ),
      ]),
    );
  }
}

class _WebhookEvent {
  final String event;
  final String label;
  final Color color;
  const _WebhookEvent(
      {required this.event, required this.label, required this.color});
}

class _WebhookInfoCard extends StatelessWidget {
  final List<_WebhookEvent> events;
  const _WebhookInfoCard({required this.events});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: events
            .map((e) => ListTile(
                  leading: Icon(Icons.circle, size: 10, color: e.color),
                  title: Text(e.label,
                      style: Theme.of(context).textTheme.bodyMedium),
                  subtitle: Text(e.event,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                  dense: true,
                  trailing: Chip(
                    label: const Text('Laravel handles'),
                    labelStyle: Theme.of(context).textTheme.labelSmall,
                    padding: EdgeInsets.zero,
                  ),
                ))
            .toList(),
      ),
    );
  }
}