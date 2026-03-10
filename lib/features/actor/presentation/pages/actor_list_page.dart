// actor_list_page.dart
// ─────────────────────────────────────────────────────────────
// Phase 2: Status filter chips, search bar, offline indicator.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/actor_bloc.dart';
import '../bloc/actor_event.dart';
import '../bloc/actor_state.dart';
import '../widgets/actor_card.dart';

class ActorListPage extends StatefulWidget {
  const ActorListPage({super.key});

  @override
  State<ActorListPage> createState() => _ActorListPageState();
}

class _ActorListPageState extends State<ActorListPage> {
  final _searchController = TextEditingController();
  String? _activeStatusFilter;

  static const _statusFilters = [
    null, // "All"
    'active',
    'pending',
    'suspended',
    'inactive',
  ];

  @override
  void initState() {
    super.initState();
    context.read<ActorBloc>().add(ActorLoadAllRequested());
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
      appBar: AppBar(title: const Text('Actors')),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context).pushNamed('/actors/create').then((result) {
              if (result == true) {
                context.read<ActorBloc>().add(ActorLoadAllRequested());
              }
            }),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search actors...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // ── Status filter chips ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _statusFilters.map((status) {
                  final isSelected = _activeStatusFilter == status;
                  final label = status ?? 'All';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(label[0].toUpperCase() + label.substring(1)),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _activeStatusFilter = status);
                      },
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── List body ─────────────────────────────────────
          Expanded(
            child: BlocConsumer<ActorBloc, ActorState>(
              listener: (context, state) {
                if (state is ActorOperationSuccess) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                  context.read<ActorBloc>().add(ActorLoadAllRequested());
                }
                if (state is ActorFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: scheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ActorLoading || state is ActorInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ActorEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: scheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No actors found. Create your first actor.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                if (state is ActorFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: scheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(state.message),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.read<ActorBloc>().add(
                            ActorLoadAllRequested(),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is ActorListLoaded) {
                  final filtered = _applyFilters(state.items);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No actors match your filters.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<ActorBloc>().add(ActorLoadAllRequested()),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => ActorCard(
                        item: filtered[i],
                        onTap: () => Navigator.of(context)
                            .pushNamed(
                              '/actors/detail',
                              arguments: {'id': filtered[i].id},
                            )
                            .then(
                              (_) => context.read<ActorBloc>().add(
                                ActorLoadAllRequested(),
                              ),
                            ),
                        onDelete: () => context.read<ActorBloc>().add(
                          ActorDeleteRequested(filtered[i].id),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Client-side filtering on the already-loaded list.
  List<dynamic> _applyFilters(List<dynamic> items) {
    var result = items.toList();

    // Status filter
    if (_activeStatusFilter != null) {
      result = result.where((a) => a.status == _activeStatusFilter).toList();
    }

    // Search filter (display name)
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result
          .where((a) => a.displayName.toLowerCase().contains(query))
          .toList();
    }

    return result;
  }
}
