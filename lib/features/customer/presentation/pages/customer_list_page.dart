  import '../../../../core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../widgets/customer_card.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(CustomerLoadAllRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Customerss')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .pushNamed('/customers/create')
            .then((_) => context.read<CustomerBloc>().add(CustomerLoadAllRequested())),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<CustomerBloc>().add(CustomerLoadAllRequested());
          }
          if (state is CustomerFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CustomerLoading || state is CustomerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CustomerEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: scheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No customers found. Create your first customer.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is CustomerFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<CustomerBloc>().add(CustomerLoadAllRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is CustomerListLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<CustomerBloc>().add(CustomerLoadAllRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (_, i) => CustomerCard(
                  item: state.items[i],
                  onTap: () => Navigator.of(context)
                      .pushNamed('/customers/detail', arguments: {'id': state.items[i].id})
                      .then((_) => context.read<CustomerBloc>().add(CustomerLoadAllRequested())),
                  onDelete: () => context.read<CustomerBloc>()
                      .add(CustomerDeleteRequested(state.items[i].id)),
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
