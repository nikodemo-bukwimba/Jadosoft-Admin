  import '../../../../core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../widgets/payment_card.dart';

class PaymentListPage extends StatefulWidget {
  const PaymentListPage({super.key});

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends State<PaymentListPage> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(PaymentLoadAllRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Paymentss')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .pushNamed('/payments/create')
            .then((_) => context.read<PaymentBloc>().add(PaymentLoadAllRequested())),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<PaymentBloc>().add(PaymentLoadAllRequested());
          }
          if (state is PaymentFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentLoading || state is PaymentInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PaymentEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: scheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No payments recorded yet.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is PaymentFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<PaymentBloc>().add(PaymentLoadAllRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is PaymentListLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<PaymentBloc>().add(PaymentLoadAllRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (_, i) => PaymentCard(
                  item: state.items[i],
                  onTap: () => Navigator.of(context)
                      .pushNamed('/payments/detail', arguments: {'id': state.items[i].id})
                      .then((_) => context.read<PaymentBloc>().add(PaymentLoadAllRequested())),
                  onDelete: () => context.read<PaymentBloc>()
                      .add(PaymentDeleteRequested(state.items[i].id)),
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
