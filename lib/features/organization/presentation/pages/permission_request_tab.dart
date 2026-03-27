import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/permission_request_entity.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/organization_event.dart';
import '../bloc/organization_state.dart';

class PermissionRequestTab extends StatelessWidget {
  const PermissionRequestTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<OrganizationBloc, OrganizationState>(
      buildWhen: (_, s) =>
          s is PermissionRequestsLoaded || s is OrganizationLoading,
      builder: (c, s) {
        if (s is OrganizationLoading)
          return const Center(child: CircularProgressIndicator());
        if (s is PermissionRequestsLoaded) {
          if (s.requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_open,
                      size: 48,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    const Text('No permission requests'),
                    const SizedBox(height: 8),
                    Text(
                      'When branch admins need additional permissions beyond what was delegated, their requests will appear here for your approval.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => c.read<OrganizationBloc>().add(
                        PermissionRequestsLoadRequested(),
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => c.read<OrganizationBloc>().add(
              PermissionRequestsLoadRequested(),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: s.requests.length,
              itemBuilder: (_, i) {
                final r = s.requests[i];
                final isPending = r.status == PermissionRequestStatus.pending;
                final statusColor = isPending
                    ? Colors.orange
                    : r.status == PermissionRequestStatus.approved
                    ? Colors.green
                    : Colors.red;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.orgName.isNotEmpty
                                    ? r.orgName
                                    : 'Branch Request',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                r.status.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(r.reason, style: Theme.of(c).textTheme.bodyMedium),
                        if (r.permissionSlugs.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: r.permissionSlugs
                                .map(
                                  (p) => Chip(
                                    label: Text(
                                      p,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (r.reviewNotes != null &&
                            r.reviewNotes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  size: 14,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    r.reviewNotes!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (isPending) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              FilledButton.icon(
                                onPressed: () => c.read<OrganizationBloc>().add(
                                  PermissionRequestApproveRequested(r.id),
                                ),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Approve'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () => c.read<OrganizationBloc>().add(
                                  PermissionRequestDenyRequested(r.id),
                                ),
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Deny'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
        return Center(
          child: FilledButton(
            onPressed: () => c.read<OrganizationBloc>().add(
              PermissionRequestsLoadRequested(),
            ),
            child: const Text('Load Requests'),
          ),
        );
      },
    );
  }
}
