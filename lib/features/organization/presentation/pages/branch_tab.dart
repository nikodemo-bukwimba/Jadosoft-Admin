import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/organization_event.dart';
import '../bloc/organization_state.dart';
import '../widgets/branch_card_tile.dart';

class BranchTab extends StatelessWidget {
  final VoidCallback? onSwitchToMembers;
  const BranchTab({super.key, this.onSwitchToMembers});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationBloc, OrganizationState>(
      buildWhen: (_, s) =>
          s is BranchesLoaded ||
          s is OrganizationLoading ||
          s is OrganizationFailure,
      builder: (c, s) {
        if (s is OrganizationLoading)
          return const Center(child: CircularProgressIndicator());
        if (s is BranchesLoaded) {
          if (s.branches.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 48,
                    color: Theme.of(
                      c,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  const Text('No branches yet'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showCreateDialog(c),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Branch'),
                  ),
                ],
              ),
            );
          }
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async =>
                    c.read<OrganizationBloc>().add(BranchesLoadRequested()),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: s.branches.length,
                  itemBuilder: (_, i) => BranchCardTile(
                    branch: s.branches[i],
                    onViewMembers: (branchId) {
                      c.read<OrganizationBloc>().add(
                        MembersLoadRequested(orgId: branchId),
                      );
                      onSwitchToMembers
                          ?.call(); // ← use callback, not DefaultTabController
                    },
                    onDelete: (branchId) =>
                        _confirmDelete(c, branchId, s.branches[i].name),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: () => _showCreateDialog(c),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          );
        }
        return Center(
          child: FilledButton(
            onPressed: () =>
                c.read<OrganizationBloc>().add(BranchesLoadRequested()),
            child: const Text('Load Branches'),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String branchId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text(
          'Are you sure you want to delete "$name"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              // Delete is via the platform admin API — show info for now
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Branch deletion requires platform admin. Contact support.',
                  ),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Branch'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Branch Name *',
                  hintText: 'e.g. Dar es Salaam Branch',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context.read<OrganizationBloc>().add(
                BranchCreateRequested({
                  'name': nameCtrl.text.trim(),
                  if (descCtrl.text.trim().isNotEmpty)
                    'description': descCtrl.text.trim(),
                  if (addrCtrl.text.trim().isNotEmpty)
                    'address': addrCtrl.text.trim(),
                }),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
