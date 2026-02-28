// category_list_page.dart
// List with loading / empty / error / data states.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/category_bloc.dart';
import '../widgets/category_card.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  static const routePath = '/categorys';

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(CategoryLoadAllRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorys'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText:   'Search categorys...',
              leading:    const Icon(Icons.search),
              onChanged:  (q) => context.read<CategoryBloc>()
                                       .add(CategorySearchChanged(q)),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "categorys",
        onPressed: () => Navigator.of(context)
            .pushNamed('/categorys/create')
            .then((_) => context.read<CategoryBloc>()
                               .add(CategoryLoadAllRequested())),
        icon:  const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: BlocConsumer<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state is CategoryOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:         Text(state.message),
                backgroundColor: scheme.primary,
              ),
            );
            context.read<CategoryBloc>().add(CategoryLoadAllRequested());
          }
          if (state is CategoryFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:         Text(state.message),
                backgroundColor: scheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CategoryLoading || state is CategoryInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CategoryEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: scheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No categories yet.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is CategoryFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: scheme.error),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.read<CategoryBloc>()
                          .add(CategoryLoadAllRequested()),
                      icon:  const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is CategoryListLoaded) {
            return RefreshIndicator(
              onRefresh: () async => context.read<CategoryBloc>()
                  .add(CategoryLoadAllRequested()),
              child: ListView.builder(
                padding:     const EdgeInsets.fromLTRB(16, 8, 16, 88),
                itemCount:   state.items.length,
                itemBuilder: (_, i) => CategoryCard(
                  item:    state.items[i],
                  onTap:   () => Navigator.of(context)
                      .pushNamed('/categorys/${state.items[i].id}')
                      .then((_) => context.read<CategoryBloc>()
                                         .add(CategoryLoadAllRequested())),
                  onDelete: () => context.read<CategoryBloc>()
                      .add(CategoryDeleteRequested(state.items[i].id)),
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
