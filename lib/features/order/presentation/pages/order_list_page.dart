import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../widgets/order_card.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(OrderLoadAllRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Orderss')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .pushNamed('/orders/create')
            .then((_) => context.read<OrderBloc>().add(OrderLoadAllRequested())),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<OrderBloc>().add(OrderLoadAllRequested());
          }
          if (state is OrderFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: scheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderLoading || state is OrderInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OrderEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: scheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No orders yet.', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            );
          }
          if (state is OrderFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<OrderBloc>().add(OrderLoadAllRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is OrderListLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<OrderBloc>().add(OrderLoadAllRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (_, i) => OrderCard(
                  item: state.items[i],
                  onTap: () => Navigator.of(context)
                      .pushNamed('/orders/detail', arguments: {'id': state.items[i].id})
                      .then((_) => context.read<OrderBloc>().add(OrderLoadAllRequested())),
                  onDelete: () => context.read<OrderBloc>()
                      .add(OrderDeleteRequested(state.items[i].id)),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
