import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/mobile_money_cubit.dart';
import '../cubit/mobile_money_state.dart';
import '../widgets/mobile_money_operation_card.dart';
import '../widgets/mobile_money_sync_status.dart';

class MobileMoneyPage extends StatelessWidget {
  const MobileMoneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Money'),
      ),
      body: BlocBuilder<MobileMoneyCubit, MobileMoneyState>(
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
              const SizedBox(height: 16),
              Text('Operations', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              MobileMoneyOperationCard(
                title: 'Initiate Payment',
                subtitle: 'Initiate a mobile money payment request to a customer',
                icon: Icons.payment,
                isLoading: state.isInitiatePaymentLoading,
                error: state.initiatePaymentError,
              // Requires parameters -- wire up from your UI
              ),
              const SizedBox(height: 8),
              MobileMoneyOperationCard(
                title: 'Query Payment Status',
                subtitle: 'Check the current status of a payment transaction',
                icon: Icons.search,
                isLoading: state.isQueryPaymentStatusLoading,
                error: state.queryPaymentStatusError,
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
                      title: Text('Payment Completed'),
                      subtitle: Text('Event: payment.completed'),
                      dense: true,
                    ),
                    ListTile(
                      leading: const Icon(Icons.webhook, size: 20),
                      title: Text('Payment Failed'),
                      subtitle: Text('Event: payment.failed'),
                      dense: true,
                    ),
                    ListTile(
                      leading: const Icon(Icons.webhook, size: 20),
                      title: Text('Payment Cancelled'),
                      subtitle: Text('Event: payment.cancelled'),
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
