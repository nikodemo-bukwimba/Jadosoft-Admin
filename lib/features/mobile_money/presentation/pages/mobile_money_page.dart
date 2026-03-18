import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/mobile_money_cubit.dart';
import '../cubit/mobile_money_state.dart';
import '../widgets/mobile_money_sync_status.dart';
import '../../domain/models/initiate_payment_request.dart';

class MobileMoneyPage extends StatefulWidget {
  const MobileMoneyPage({super.key});

  @override
  State<MobileMoneyPage> createState() => _MobileMoneyPageState();
}

class _MobileMoneyPageState extends State<MobileMoneyPage> {
  // Initiate payment form
  final _paymentFormKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referenceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedProvider = 'M-Pesa';
  String _selectedCurrency = 'TZS';

  // Query status form
  final _statusFormKey = GlobalKey<FormState>();
  final _transactionIdController = TextEditingController();
  String? _lastTransactionId;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _referenceController.dispose();
    _descriptionController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Money'),
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
      body: BlocConsumer<MobileMoneyCubit, MobileMoneyState>(
        listener: (context, state) {
          if (!state.isInitiatePaymentLoading &&
              state.initiatePaymentError == null &&
              state.lastTransactionId != null) {
            setState(() {
              _lastTransactionId = state.lastTransactionId;
              _transactionIdController.text = state.lastTransactionId!;
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Payment initiated — TXN: ${state.lastTransactionId}'),
              ]),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MobileMoneySyncStatus(
                  lastSyncAt: state.lastSyncAt,
                  isLoading: state.isLoading,
                ),
                const SizedBox(height: 20),

                // ── Warning banner ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber,
                          color: Colors.amber.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Payment initiation triggers real money movement in production. '
                          'Currently running in mock mode — no actual transactions.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Initiate Payment ──────────────────────────────
                _SectionHeader(
                    icon: Icons.payment, label: 'Initiate Payment'),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _paymentFormKey,
                      child: Column(
                        children: [
                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                decoration: const InputDecoration(
                                  labelText: 'Amount *',
                                  hintText: '25000',
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Amount is required';
                                  }
                                  final n = double.tryParse(v.trim());
                                  if (n == null || n <= 0) {
                                    return 'Enter a valid amount';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              child: DropdownButtonFormField<String>(
                                value: _selectedCurrency,
                                decoration: const InputDecoration(
                                    labelText: 'Currency'),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'TZS', child: Text('TZS')),
                                  DropdownMenuItem(
                                      value: 'USD', child: Text('USD')),
                                  DropdownMenuItem(
                                      value: 'KES', child: Text('KES')),
                                ],
                                onChanged: (v) => setState(
                                    () => _selectedCurrency = v ?? 'TZS'),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Customer Phone *',
                              hintText: '+255712345678',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Phone number is required'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedProvider,
                            decoration: const InputDecoration(
                              labelText: 'Provider *',
                              prefixIcon: Icon(Icons.account_balance_wallet),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'M-Pesa', child: Text('M-Pesa')),
                              DropdownMenuItem(
                                  value: 'Airtel Money',
                                  child: Text('Airtel Money')),
                            ],
                            onChanged: (v) => setState(
                                () => _selectedProvider = v ?? 'M-Pesa'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _referenceController,
                            decoration: const InputDecoration(
                              labelText: 'Reference *',
                              hintText: 'e.g. ORD-001',
                              prefixIcon: Icon(Icons.tag),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Reference is required'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description (optional)',
                              hintText: 'Payment for order...',
                              prefixIcon: Icon(Icons.notes),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (state.initiatePaymentError != null)
                            _ErrorBanner(
                                message: state.initiatePaymentError!),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: state.isInitiatePaymentLoading
                                  ? null
                                  : () => _handleInitiatePayment(context),
                              icon: state.isInitiatePaymentLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Icon(Icons.send_to_mobile),
                              label: Text(state.isInitiatePaymentLoading
                                  ? 'Initiating...'
                                  : 'Initiate Payment'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Query Status ──────────────────────────────────
                _SectionHeader(
                    icon: Icons.search, label: 'Query Payment Status'),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _statusFormKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _transactionIdController,
                            decoration: InputDecoration(
                              labelText: 'Transaction ID *',
                              hintText: 'Paste transaction ID here',
                              prefixIcon: const Icon(Icons.fingerprint),
                              suffixIcon: _lastTransactionId != null
                                  ? Tooltip(
                                      message: 'Use last transaction ID',
                                      child: IconButton(
                                        icon: const Icon(Icons.history),
                                        onPressed: () => setState(() =>
                                            _transactionIdController.text =
                                                _lastTransactionId!),
                                      ),
                                    )
                                  : null,
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Transaction ID is required'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          if (state.queryPaymentStatusError != null)
                            _ErrorBanner(
                                message: state.queryPaymentStatusError!),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: state.isQueryPaymentStatusLoading
                                  ? null
                                  : () => _handleQueryStatus(context),
                              icon: state.isQueryPaymentStatusLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Icon(Icons.search),
                              label: Text(state.isQueryPaymentStatusLoading
                                  ? 'Querying...'
                                  : 'Query Status'),
                            ),
                          ),
                          if (state.queryPaymentStatusResult != null) ...[
                            const SizedBox(height: 16),
                            _PaymentStatusResult(
                                result: state.queryPaymentStatusResult!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Webhooks ──────────────────────────────────────
                _WebhookInfoCard(events: const [
                  _WebhookEvent(
                      event: 'payment.completed',
                      label: 'Payment Completed',
                      color: Colors.green),
                  _WebhookEvent(
                      event: 'payment.failed',
                      label: 'Payment Failed',
                      color: Colors.red),
                  _WebhookEvent(
                      event: 'payment.cancelled',
                      label: 'Payment Cancelled',
                      color: Colors.orange),
                ]),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleInitiatePayment(BuildContext context) {
    if (!_paymentFormKey.currentState!.validate()) return;
    context.read<MobileMoneyCubit>().initiatePayment(
          InitiatePaymentRequest(
            amount: double.parse(_amountController.text.trim()),
            currency: _selectedCurrency,
            phoneNumber: _phoneController.text.trim(),
            provider: _selectedProvider,
            reference: _referenceController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          ),
        );
  }

  void _handleQueryStatus(BuildContext context) {
    if (!_statusFormKey.currentState!.validate()) return;
    context
        .read<MobileMoneyCubit>()
        .queryPaymentStatus(_transactionIdController.text.trim());
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
          borderRadius: BorderRadius.circular(8)),
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

class _PaymentStatusResult extends StatelessWidget {
  final dynamic result;
  const _PaymentStatusResult({required this.result});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColors = {
      'completed': Colors.green,
      'pending': Colors.orange,
      'failed': Colors.red,
      'cancelled': Colors.grey,
    };
    final statusColor =
        statusColors[result.status] ?? scheme.onSurfaceVariant;
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
        _ResultRow(label: 'TXN ID', value: result.transactionId),
        _ResultRow(
            label: 'Status',
            value: result.status.toUpperCase(),
            valueColor: statusColor),
        _ResultRow(
            label: 'Amount',
            value:
                '${result.currency} ${result.amount.toStringAsFixed(2)}'),
        _ResultRow(label: 'Provider', value: result.provider),
        if (result.completedAt != null)
          _ResultRow(
              label: 'Completed',
              value: result.completedAt.toString().split('.').first),
        if (result.failureReason != null)
          _ResultRow(
              label: 'Failure',
              value: result.failureReason,
              valueColor: scheme.error),
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
          width: 90,
          child: Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value ?? '-',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            const Icon(Icons.webhook, size: 16),
            const SizedBox(width: 8),
            Text('Webhook Events',
                style: Theme.of(context).textTheme.titleSmall),
          ]),
        ),
        ...events.map((e) => ListTile(
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
            )),
      ]),
    );
  }
}