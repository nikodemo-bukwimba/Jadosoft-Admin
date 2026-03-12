import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/sms_gateway_cubit.dart';
import '../cubit/sms_gateway_state.dart';
import '../widgets/sms_gateway_operation_card.dart';
import '../widgets/sms_gateway_sync_status.dart';

class SmsGatewayPage extends StatelessWidget {
  const SmsGatewayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Gateway'),
      ),
      body: BlocBuilder<SmsGatewayCubit, SmsGatewayState>(
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
              const SizedBox(height: 16),
              Text('Operations', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SmsGatewayOperationCard(
                title: 'Send SMS',
                subtitle: 'Send an SMS message to a recipient',
                icon: Icons.send,
                isLoading: state.isSendSmsLoading,
                error: state.sendSmsError,
              // Requires parameters -- wire up from your UI
              ),
              const SizedBox(height: 8),
              SmsGatewayOperationCard(
                title: 'Get Delivery Status',
                subtitle: 'Retrieve delivery status for a sent SMS',
                icon: Icons.check_circle_outline,
                isLoading: state.isGetDeliveryStatusLoading,
                error: state.getDeliveryStatusError,
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
                      title: Text('Message Delivered'),
                      subtitle: Text('Event: message.delivered'),
                      dense: true,
                    ),
                    ListTile(
                      leading: const Icon(Icons.webhook, size: 20),
                      title: Text('Message Failed'),
                      subtitle: Text('Event: message.failed'),
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
