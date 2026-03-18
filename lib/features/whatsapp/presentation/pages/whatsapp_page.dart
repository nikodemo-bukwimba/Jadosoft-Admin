import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/whatsapp_cubit.dart';
import '../cubit/whatsapp_state.dart';
import '../widgets/whatsapp_sync_status.dart';
import '../../domain/models/send_template_request.dart';
import '../../domain/models/send_media_request.dart';

class WhatsappPage extends StatefulWidget {
  const WhatsappPage({super.key});

  @override
  State<WhatsappPage> createState() => _WhatsappPageState();
}

class _WhatsappPageState extends State<WhatsappPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Template form
  final _templateFormKey = GlobalKey<FormState>();
  final _tplPhoneNumberIdController = TextEditingController();
  final _tplToController = TextEditingController();
  final _tplNameController = TextEditingController();
  final _tplLangController = TextEditingController(text: 'en');

  // Media form
  final _mediaFormKey = GlobalKey<FormState>();
  final _mediaPhoneNumberIdController = TextEditingController();
  final _mediaToController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  final _mediaCaptionController = TextEditingController();
  String _selectedMediaType = 'image';

  // Status form
  final _statusFormKey = GlobalKey<FormState>();
  final _msgIdController = TextEditingController();
  String? _lastSentMessageId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tplPhoneNumberIdController.dispose();
    _tplToController.dispose();
    _tplNameController.dispose();
    _tplLangController.dispose();
    _mediaPhoneNumberIdController.dispose();
    _mediaToController.dispose();
    _mediaUrlController.dispose();
    _mediaCaptionController.dispose();
    _msgIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Business'),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.message, size: 18), text: 'Template'),
            Tab(icon: Icon(Icons.image, size: 18), text: 'Media'),
            Tab(icon: Icon(Icons.track_changes, size: 18), text: 'Status'),
          ],
        ),
      ),
      body: BlocConsumer<WhatsappCubit, WhatsappState>(
        listener: (context, state) {
          if (!state.isSendTemplateLoading &&
              state.sendTemplateError == null &&
              state.lastSentMessageId != null) {
            setState(() {
              _lastSentMessageId = state.lastSentMessageId;
              _msgIdController.text = state.lastSentMessageId!;
            });
            _showSuccess(context,
                'Template sent — ID: ${state.lastSentMessageId}');
          }
          if (!state.isSendMediaLoading &&
              state.sendMediaError == null &&
              state.lastSentMediaId != null) {
            setState(() {
              _lastSentMessageId = state.lastSentMediaId;
              _msgIdController.text = state.lastSentMediaId!;
            });
            _showSuccess(
                context, 'Media sent — ID: ${state.lastSentMediaId}');
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: WhatsappSyncStatus(
                  lastSyncAt: state.lastSyncAt,
                  isLoading: state.isLoading,
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTemplateTab(context, state),
                    _buildMediaTab(context, state),
                    _buildStatusTab(context, state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Template Tab ────────────────────────────────────────────────────────
  Widget _buildTemplateTab(BuildContext context, WhatsappState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _templateFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Send a pre-approved WhatsApp template message'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tplPhoneNumberIdController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number ID *',
                    hintText: 'Your WhatsApp Business phone number ID',
                    prefixIcon: Icon(Icons.dialpad),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Phone Number ID is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tplToController,
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
                  controller: _tplNameController,
                  decoration: const InputDecoration(
                    labelText: 'Template Name *',
                    hintText: 'e.g. product_update',
                    prefixIcon: Icon(Icons.layers),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Template name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tplLangController,
                  decoration: const InputDecoration(
                    labelText: 'Language Code *',
                    hintText: 'en',
                    prefixIcon: Icon(Icons.language),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Language code is required'
                      : null,
                ),
                const SizedBox(height: 16),
                if (state.sendTemplateError != null)
                  _ErrorBanner(message: state.sendTemplateError!),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isSendTemplateLoading
                        ? null
                        : () => _handleSendTemplate(context),
                    icon: state.isSendTemplateLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                    label: Text(state.isSendTemplateLoading
                        ? 'Sending...'
                        : 'Send Template'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Media Tab ───────────────────────────────────────────────────────────
  Widget _buildMediaTab(BuildContext context, WhatsappState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _mediaFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Send image, document or video via WhatsApp'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mediaPhoneNumberIdController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number ID *',
                    hintText: 'Your WhatsApp Business phone number ID',
                    prefixIcon: Icon(Icons.dialpad),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Phone Number ID is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mediaToController,
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
                DropdownButtonFormField<String>(
                  value: _selectedMediaType,
                  decoration: const InputDecoration(
                    labelText: 'Media Type *',
                    prefixIcon: Icon(Icons.perm_media),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'image', child: Text('Image')),
                    DropdownMenuItem(
                        value: 'document', child: Text('Document')),
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedMediaType = v ?? 'image'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mediaUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Media URL *',
                    hintText: 'https://example.com/file.jpg',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Media URL is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mediaCaptionController,
                  decoration: const InputDecoration(
                    labelText: 'Caption (optional)',
                    hintText: 'Add a caption...',
                    prefixIcon: Icon(Icons.closed_caption),
                  ),
                ),
                const SizedBox(height: 16),
                if (state.sendMediaError != null)
                  _ErrorBanner(message: state.sendMediaError!),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isSendMediaLoading
                        ? null
                        : () => _handleSendMedia(context),
                    icon: state.isSendMediaLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.upload),
                    label: Text(state.isSendMediaLoading
                        ? 'Sending...'
                        : 'Send Media'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Status Tab ──────────────────────────────────────────────────────────
  Widget _buildStatusTab(BuildContext context, WhatsappState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _statusFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _msgIdController,
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
                                      _msgIdController.text =
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
                    if (state.getMessageStatusError != null)
                      _ErrorBanner(message: state.getMessageStatusError!),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: state.isGetMessageStatusLoading
                            ? null
                            : () => _handleGetStatus(context),
                        icon: state.isGetMessageStatusLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.search),
                        label: Text(state.isGetMessageStatusLoading
                            ? 'Checking...'
                            : 'Check Status'),
                      ),
                    ),
                    if (state.getMessageStatusResult != null) ...[
                      const SizedBox(height: 16),
                      _MessageStatusResult(
                          result: state.getMessageStatusResult!),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _WebhookInfoCard(events: const [
            _WebhookEvent(
                event: 'messages.sent',
                label: 'Message Sent',
                color: Colors.blue),
            _WebhookEvent(
                event: 'messages.delivered',
                label: 'Message Delivered',
                color: Colors.green),
            _WebhookEvent(
                event: 'messages.read',
                label: 'Message Read',
                color: Colors.teal),
            _WebhookEvent(
                event: 'messages.failed',
                label: 'Message Failed',
                color: Colors.red),
          ]),
        ],
      ),
    );
  }

  void _handleSendTemplate(BuildContext context) {
    if (!_templateFormKey.currentState!.validate()) return;
    context.read<WhatsappCubit>().sendTemplate(
          _tplPhoneNumberIdController.text.trim(),
          SendTemplateRequest(
            to: _tplToController.text.trim(),
            templateName: _tplNameController.text.trim(),
            languageCode: _tplLangController.text.trim(),
          ),
        );
  }

  void _handleSendMedia(BuildContext context) {
    if (!_mediaFormKey.currentState!.validate()) return;
    context.read<WhatsappCubit>().sendMedia(
          _mediaPhoneNumberIdController.text.trim(),
          SendMediaRequest(
            to: _mediaToController.text.trim(),
            mediaType: _selectedMediaType,
            mediaUrl: _mediaUrlController.text.trim(),
            caption: _mediaCaptionController.text.trim().isEmpty
                ? null
                : _mediaCaptionController.text.trim(),
          ),
        );
  }

  void _handleGetStatus(BuildContext context) {
    if (!_statusFormKey.currentState!.validate()) return;
    context
        .read<WhatsappCubit>()
        .getMessageStatus(_msgIdController.text.trim());
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(message),
      ]),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant));
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

class _MessageStatusResult extends StatelessWidget {
  final dynamic result;
  const _MessageStatusResult({required this.result});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColors = {
      'sent': Colors.blue,
      'delivered': Colors.green,
      'read': Colors.teal,
      'failed': Colors.red,
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
        _ResultRow(label: 'Message ID', value: result.messageId),
        _ResultRow(
            label: 'Status',
            value: result.status.toUpperCase(),
            valueColor: statusColor),
        _ResultRow(
            label: 'Timestamp',
            value: result.timestamp.toString().split('.').first),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant)),
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
        children: [
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
        ],
      ),
    );
  }
}