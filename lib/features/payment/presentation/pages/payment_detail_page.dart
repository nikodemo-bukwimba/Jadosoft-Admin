import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';

class PaymentDetailPage extends StatelessWidget {
  const PaymentDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<PaymentBloc>().state;
              if (state is PaymentDetailLoaded) {
                Navigator.of(context).pushNamed(
                  '/payments/edit',
                  arguments: {'id': state.item.id},
                );
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<PaymentBloc, PaymentState>(
        builder: (context, state) {
          if (state is PaymentLoading || state is PaymentInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PaymentFailure) {
            return Center(child: Text(state.message));
          }
          if (state is PaymentDetailLoaded) {
            final item = state.item;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _buildField(context, 'Transaction Ref', item.transactionRef?.toString() ?? ''),
                    _buildField(context, 'Amount', item.amount.toStringAsFixed(2)),
                    _buildField(context, 'Order Id', item.orderId),
                    _buildField(context, 'Customer Id', item.customerId),
                    _buildField(context, 'Currency', item.currency),
                    _buildField(context, 'Provider', item.provider),
                    _buildField(context, 'Status', item.status),
                    _buildField(context, 'Initiated At', item.initiatedAt.toIso8601String().split('T').first),
                    _buildField(context, 'Confirmed At', item.confirmedAt?.toIso8601String().split('T').first ?? ''),
                    _buildField(context, 'Failure Reason', item.failureReason?.toString() ?? ''),
                    ],
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildField(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
