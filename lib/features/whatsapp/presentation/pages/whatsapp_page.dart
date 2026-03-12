import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/whatsapp_cubit.dart';
import '../cubit/whatsapp_state.dart';
import '../widgets/whatsapp_operation_card.dart';
import '../widgets/whatsapp_sync_status.dart';

class WhatsappPage extends StatelessWidget {
  const WhatsappPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Business'),
      ),
      body: BlocBuilder<WhatsappCubit, WhatsappState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              WhatsappSyncStatus(
                lastSyncAt: state.lastSyncAt,
                isLoading: state.isLoading,
              ),
              const SizedBox(height: 16),
              Text('Operations', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              WhatsappOperationCard(
                title: 'Send Template Message',
                subtitle: 'Send a pre-approved WhatsApp template message to a recipient',
                icon: Icons.message,
                isLoading: state.isSendTemplateLoading,
                error: state.sendTemplateError,
              // Requires parameters -- wire up from your UI
              ),
              const SizedBox(height: 8),
              WhatsappOperationCard(
                title: 'Send Media Message',
                subtitle: 'Send media (image, document, video) via WhatsApp',
                icon: Icons.image,
                isLoading: state.isSendMediaLoading,
                error: state.sendMediaError,
              // Requires parameters -- wire up from your UI
              ),
              const SizedBox(height: 8),
              WhatsappOperationCard(
                title: 'Get Message Status',
                subtitle: 'Retrieve status of a sent WhatsApp message',
                icon: Icons.info_outline,
                isLoading: state.isGetMessageStatusLoading,
                error: state.getMessageStatusError,
              // Requires parameters -- wire up from your UI
              ),
              const SizedBox(height: 8),

              const SizedBox(height: 24),
              Text('Webhooks', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.webhook, size: 20),
                      title: Text('Message Sent'),
                      subtitle: Text('Event: messages.sent'),
                      dense: true,
                    ),
                    ListTile(
                      leading: const Icon(Icons.webhook, size: 20),
                      title: Text('Message Delivered'),
                      subtitle: Text('Event: messages.delivered'),
                      dense: true,
                    ),
                    ListTile(
                      leading: const Icon(Icons.webhook, size: 20),
                      title: Text('Message Read'),
                      subtitle: Text('Event: messages.read'),
                      dense: true,
                    ),
                    ListTile(
                      leading: const Icon(Icons.webhook, size: 20),
                      title: Text('Message Failed'),
                      subtitle: Text('Event: messages.failed'),
                      dense: true,
                    ),
                  ],
                ),
              ),
              ],
            ),
          );
        },
      ),
    );
  }
}
