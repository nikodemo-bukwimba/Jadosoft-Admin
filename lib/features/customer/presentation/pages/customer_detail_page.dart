import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../domain/entities/customer_entity.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../../../officer/data/datasources/officer_mock_datasource.dart';

class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({super.key});

  Future<String> _getOfficerName(String officerId) async {
    try {
      final ds = OfficerMockDataSource();
      final officer = await ds.getById(officerId);
      return officer.name;
    } catch (_) {
      return officerId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Detail'),
        actions: [
          BlocBuilder<CustomerBloc, CustomerState>(
            builder: (context, state) {
              if (state is CustomerDetailLoaded) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () => context.push(
                        AppRouter.customerEditPath(state.item.id),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: scheme.error),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(
                        context,
                        state.item.id,
                        state.item.businessName,
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            context.pop();
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
          if (state is CustomerFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: scheme.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
          if (state is CustomerDetailLoaded) {
            return _buildContent(context, state.item);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, CustomerEntity item) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 600;
    final hasGps = item.gpsLat != null && item.gpsLng != null;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? MediaQuery.of(context).size.width * 0.1 : 16,
        vertical: 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ──────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: scheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      child: Icon(Icons.store, color: scheme.primary, size: 30),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.businessName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (item.fullOfficeName != null &&
                              item.fullOfficeName!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.fullOfficeName!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            'Registered ${item.registrationDate.toIso8601String().split('T').first}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Owner & Contact Card ─────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Owner & Contact',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(height: 24),
                    _row(context, Icons.person, 'Owner', item.ownerName),
                    _row(
                      context,
                      Icons.phone,
                      'Official Phone',
                      item.officialPhone,
                    ),
                    if (item.contactPerson != null &&
                        item.contactPerson!.isNotEmpty)
                      _row(
                        context,
                        Icons.people_outline,
                        'Contact Person',
                        item.contactPerson!,
                      ),
                    if (item.contactPersonPhone != null &&
                        item.contactPersonPhone!.isNotEmpty)
                      _row(
                        context,
                        Icons.phone_forwarded_outlined,
                        'Contact Phone',
                        item.contactPersonPhone!,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Location & Assignment Card ───────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location & Assignment',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(height: 24),
                    if (item.officeAddress != null &&
                        item.officeAddress!.isNotEmpty)
                      _row(
                        context,
                        Icons.location_on_outlined,
                        'Address',
                        item.officeAddress!,
                      ),
                    // GPS row — tappable
                    if (hasGps)
                      _gpsRow(context, item)
                    else
                      _row(
                        context,
                        Icons.gps_not_fixed_outlined,
                        'GPS',
                        'Not recorded',
                        muted: true,
                      ),
                    FutureBuilder<String>(
                      future: _getOfficerName(item.assignedOfficerId),
                      builder: (_, snap) => _row(
                        context,
                        Icons.badge_outlined,
                        'Assigned Officer',
                        snap.data ?? '...',
                      ),
                    ),
                    _row(context, Icons.fingerprint, 'ID', item.id),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// GPS row that opens the map on tap.
  Widget _gpsRow(BuildContext context, CustomerEntity item) {
    final scheme = Theme.of(context).colorScheme;
    final coords =
        '${item.gpsLat!.toStringAsFixed(4)}, ${item.gpsLng!.toStringAsFixed(4)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Tooltip(
        message: 'Open in Map',
        child: InkWell(
          onTap: () => MapLauncher.open(
            lat: item.gpsLat!,
            lng: item.gpsLng!,
            label: item.businessName,
          ),
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Icon(Icons.gps_fixed, size: 20, color: scheme.primary),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: Text(
                  'GPS',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  coords,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: scheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: scheme.primary,
                  ),
                ),
              ),
              Icon(Icons.open_in_new, size: 14, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool muted = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final color = muted
        ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: muted
                ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
                : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text('Remove "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<CustomerBloc>().add(CustomerDeleteRequested(id));
    }
  }
}
