import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../domain/value_objects/product_status.dart';
import '../widgets/product_status_badge.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<ProductBloc>().state;
              if (state is ProductDetailLoaded) {
                Navigator.of(context).pushNamed(
                  '/products/edit',
                  arguments: {'id': state.item.id},
                );
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            if (state.updatedItem != null) {
              context.read<ProductBloc>()
                  .add(ProductLoadOneRequested(state.updatedItem!.id));
            }
          }
          if (state is ProductFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProductLoading || state is ProductInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProductFailure) {
            return Center(child: Text(state.message));
          }
          if (state is ProductDetailLoaded) {
            final item = state.item;
            final statusEnum = ProductStatusX.fromString(item.status);
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
                                  style: Theme.of(context).textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ProductStatusBadge(status: statusEnum),
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
                          Text('Actions', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                    if ([ProductStatus.draft].contains(statusEnum))
                      FilledButton.tonal(
                        onPressed: () => context.read<ProductBloc>()
                            .add(ProductPublishRequested(item.id)),
                        child: const Text('Publish'),
                      ),
                    if ([ProductStatus.active].contains(statusEnum))
                      FilledButton.tonal(
                        onPressed: () => context.read<ProductBloc>()
                            .add(ProductFeatureRequested(item.id)),
                        child: const Text('Mark Featured'),
                      ),
                    if ([ProductStatus.featured].contains(statusEnum))
                      FilledButton.tonal(
                        onPressed: () => context.read<ProductBloc>()
                            .add(ProductUnfeatureRequested(item.id)),
                        child: const Text('Remove Featured'),
                      ),
                    if ([ProductStatus.active, ProductStatus.featured].contains(statusEnum))
                      FilledButton.tonal(
                        onPressed: () => context.read<ProductBloc>()
                            .add(ProductArchiveRequested(item.id)),
                        child: const Text('Archive'),
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
                    _buildField(context, 'Name', item.name),
                    _buildField(context, 'Price', item.price.toStringAsFixed(2)),
                    _buildField(context, 'Description', item.description ?? ''),
                    _buildField(context, 'Category Id', item.categoryId),
                    _buildField(context, 'Is Available', item.isAvailable.toString()),
                    _buildField(context, 'Is Featured', item.isFeatured.toString()),
                    _buildField(context, 'Is New', item.isNew.toString()),
                    _buildField(context, 'Status', item.status),
                    _buildField(context, 'Created At', item.createdAt.toIso8601String().split('T').first),
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
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
