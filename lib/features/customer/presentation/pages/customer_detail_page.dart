import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';

class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<CustomerBloc>().state;
              if (state is CustomerDetailLoaded) {
                Navigator.of(context).pushNamed(
                  '/customers/edit',
                  arguments: {'id': state.item.id},
                );
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          if (state is CustomerLoading || state is CustomerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CustomerFailure) {
            return Center(child: Text(state.message));
          }
          if (state is CustomerDetailLoaded) {
            final item = state.item;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _buildField(context, 'Business Name', item.businessName),
                    _buildField(context, 'Owner Name', item.ownerName),
                    _buildField(context, 'Full Office Name', item.fullOfficeName?.toString() ?? ''),
                    _buildField(context, 'Official Phone', item.officialPhone),
                    _buildField(context, 'Contact Person', item.contactPerson?.toString() ?? ''),
                    _buildField(context, 'Contact Person Phone', item.contactPersonPhone?.toString() ?? ''),
                    _buildField(context, 'Office Address', item.officeAddress?.toString() ?? ''),
                    _buildField(context, 'Gps Lat', item.gpsLat?.toString() ?? ''),
                    _buildField(context, 'Gps Lng', item.gpsLng?.toString() ?? ''),
                    _buildField(context, 'Assigned Officer Id', item.assignedOfficerId),
                    _buildField(context, 'Registration Date', item.registrationDate.toIso8601String().split('T').first),
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
