import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';

class CategoryDetailPage extends StatelessWidget {
  const CategoryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Categories Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<CategoryBloc>().state;
              if (state is CategoryDetailLoaded) {
                Navigator.of(context).pushNamed(
                  '/categorys/edit',
                  arguments: {'id': state.item.id},
                );
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoading || state is CategoryInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CategoryFailure) {
            return Center(child: Text(state.message));
          }
          if (state is CategoryDetailLoaded) {
            final item = state.item;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _buildField(context, 'Name', item.name),
                    _buildField(context, 'Description', item.description?.toString() ?? ''),
                    _buildField(context, 'Is Active', item.isActive.toString()),
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
