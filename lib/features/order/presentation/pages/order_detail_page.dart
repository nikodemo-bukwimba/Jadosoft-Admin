import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../../domain/value_objects/order_status.dart';
import '../widgets/order_status_badge.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<OrderBloc>().state;
              if (state is OrderDetailLoaded) {
                Navigator.of(
                  context,
                ).pushNamed('/orders/edit', arguments: {'id': state.item.id});
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            if (state.updatedItem != null) {
              context.read<OrderBloc>().add(
                OrderLoadOneRequested(state.updatedItem!.id),
              );
            }
          }
          if (state is OrderFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderLoading || state is OrderInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OrderFailure) {
            return Center(child: Text(state.message));
          }
          if (state is OrderDetailLoaded) {
            final item = state.item;
            final statusEnum = OrderStatusX.fromString(item.status);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.id,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                OrderStatusBadge(status: statusEnum),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actions',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if ([OrderStatus.draft].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () => context
                                      .read<OrderBloc>()
                                      .add(OrderConfirmRequested(item.id)),
                                  child: const Text('Confirm Order'),
                                ),
                              if ([OrderStatus.confirmed].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () => context
                                      .read<OrderBloc>()
                                      .add(OrderShipRequested(item.id)),
                                  child: const Text('Ship Order'),
                                ),
                              if ([OrderStatus.shipped].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () => context
                                      .read<OrderBloc>()
                                      .add(OrderDeliverRequested(item.id)),
                                  child: const Text('Mark Delivered'),
                                ),
                              if ([
                                OrderStatus.draft,
                                OrderStatus.confirmed,
                              ].contains(statusEnum))
                                FilledButton.tonal(
                                  onPressed: () => context
                                      .read<OrderBloc>()
                                      .add(OrderCancelRequested(item.id)),
                                  child: const Text('Cancel Order'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField(context, 'Customer Id', item.customerId),
                          _buildField(
                            context,
                            'Total',
                            item.total.toStringAsFixed(2),
                          ),
                          _buildField(
                            context,
                            'Items',
                            item.items.map((e) => e.toString()).join(', '),
                          ),
                          _buildField(
                            context,
                            'Payment Ref',
                            item.paymentRef ?? '',
                          ),
                          _buildField(context, 'Status', item.status),
                          _buildField(
                            context,
                            'Created At',
                            item.createdAt.toIso8601String().split('T').first,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
