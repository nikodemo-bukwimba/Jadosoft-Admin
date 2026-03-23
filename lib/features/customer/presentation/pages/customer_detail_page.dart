import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../config/di/injection_container.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../domain/entities/customer_entity.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../../../officer/data/datasources/officer_remote_datasource.dart';

class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({super.key});

  /// Resolve officer display name from assigned_officer_id (actorId).
  Future<String> _getOfficerName(String? officerId) async {
    if (officerId == null || officerId.isEmpty) return 'Not assigned';
    try {
      final ds = sl<OfficerRemoteDataSource>();
      final result = await ds.getAll();
      final match = result.items.where((o) => o.actorId == officerId).firstOrNull
          ?? result.items.where((o) => o.userId == officerId).firstOrNull;
      if (match != null) {
        final role = match.orgRoleName ?? '';
        return role.isNotEmpty ? '${match.displayName} ($role)' : match.displayName;
      }
      return officerId;
    } catch (_) {
      return officerId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Detail'), actions: [
        BlocBuilder<CustomerBloc, CustomerState>(builder: (context, state) {
          if (state is CustomerDetailLoaded) {
            return Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit',
                onPressed: () => context.push(AppRouter.customerEditPath(state.item.id))),
              IconButton(icon: Icon(Icons.delete_outline, color: scheme.error), tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, state.item.id, state.item.name)),
            ]);
          }
          return const SizedBox.shrink();
        }),
      ]),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            context.pop();
          }
          if (state is CustomerFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: scheme.error));
          }
        },
        builder: (context, state) {
          if (state is CustomerLoading || state is CustomerInitial) return const Center(child: CircularProgressIndicator());
          if (state is CustomerFailure) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error), const SizedBox(height: 16), Text(state.message),
            const SizedBox(height: 16), FilledButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back), label: const Text('Go Back')),
          ]));
          if (state is CustomerDetailLoaded) return _buildContent(context, state.item);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, CustomerEntity item) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 600;
    final contact = item.primaryContact;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWide ? MediaQuery.of(context).size.width * 0.1 : 16, vertical: 16),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header Card ──
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Row(children: [
          CircleAvatar(radius: 32, backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
            child: Icon(item.isB2B ? Icons.store : Icons.person, color: scheme.primary, size: 30)),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(item.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
              if (item.code != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
                child: Text(item.code!, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              _chip(context, item.customerType.toUpperCase(), scheme.primary),
              if (item.category != null) _chip(context, item.category!, scheme.tertiary),
              _chip(context, item.tier, _tierColor(item.tier)),
              _chip(context, item.status, item.status == 'active' ? Colors.green : item.status == 'blacklisted' ? Colors.red : Colors.grey),
            ]),
            if (item.createdAt != null) ...[const SizedBox(height: 6),
              Text('Registered ${item.createdAt!.toIso8601String().split('T').first}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))],
          ])),
        ]))),
        const SizedBox(height: 12),

        // ── Contact & Communication Card ──
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Contact & Communication', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
          const Divider(height: 24),
          if (item.phone != null) _row(context, Icons.phone, 'Phone', item.phone!),
          if (item.email != null) _row(context, Icons.email_outlined, 'Email', item.email!),
          if (item.whatsappNumber != null) _row(context, Icons.chat, 'WhatsApp', item.whatsappNumber!),
          if (contact != null) ...[
            const SizedBox(height: 8),
            Text('Primary Contact', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            _row(context, Icons.person_outline, 'Name', '${contact.name}${contact.role != null ? ' (${contact.role})' : ''}'),
            if (contact.phone != null) _row(context, Icons.phone_forwarded_outlined, 'Phone', contact.phone!),
          ],
          if (item.contacts.length > 1) ...[
            const SizedBox(height: 8),
            Text('All Contacts (${item.contacts.length})', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            ...item.contacts.map((c) => _row(context, Icons.person_pin, c.role ?? 'contact', '${c.name}${c.phone != null ? ' · ${c.phone}' : ''}')),
          ],
        ]))),
        const SizedBox(height: 12),

        // ── Location & Assignment Card ──
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Location & Assignment', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
          const Divider(height: 24),
          if (item.address != null) _row(context, Icons.location_on_outlined, 'Address', item.address!),
          if (item.city != null) _row(context, Icons.location_city, 'City', '${item.city}${item.county != null ? ', ${item.county}' : ''}'),
          if (item.hasGps) _gpsRow(context, item) else _row(context, Icons.gps_not_fixed_outlined, 'GPS', 'Not recorded', muted: true),
          // ── Officer name via FutureBuilder ──
          FutureBuilder<String>(
            future: _getOfficerName(item.assignedOfficerId),
            builder: (_, snap) => _row(
              context, Icons.badge_outlined, 'Assigned Officer', snap.data ?? '...',
            ),
          ),
          _row(context, Icons.fingerprint, 'Customer ID', item.id),
        ]))),
        const SizedBox(height: 80),
      ])),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.4))),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)));

  Color _tierColor(String tier) => switch (tier) {
    'platinum' => Colors.deepPurple, 'gold' => Colors.amber.shade700, 'silver' => Colors.blueGrey, _ => Colors.grey,
  };

  Widget _gpsRow(BuildContext context, CustomerEntity item) {
    final scheme = Theme.of(context).colorScheme;
    final coords = '${item.latitude!.toStringAsFixed(4)}, ${item.longitude!.toStringAsFixed(4)}';
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Tooltip(message: 'Open in Map',
      child: InkWell(onTap: () => MapLauncher.open(lat: item.latitude!, lng: item.longitude!, label: item.name),
        borderRadius: BorderRadius.circular(6), child: Row(children: [
          Icon(Icons.gps_fixed, size: 20, color: scheme.primary), const SizedBox(width: 12),
          SizedBox(width: 110, child: Text('GPS', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
          Expanded(child: Text(coords, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500, color: scheme.primary, decoration: TextDecoration.underline, decorationColor: scheme.primary))),
          Icon(Icons.open_in_new, size: 14, color: scheme.primary),
        ]))));
  }

  Widget _row(BuildContext context, IconData icon, String label, String value, {bool muted = false}) {
    final scheme = Theme.of(context).colorScheme;
    final color = muted ? scheme.onSurfaceVariant.withValues(alpha: 0.45) : null;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      Icon(icon, size: 20, color: muted ? scheme.onSurfaceVariant.withValues(alpha: 0.4) : scheme.onSurfaceVariant),
      const SizedBox(width: 12),
      SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
      Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: color))),
    ]));
  }

  Future<void> _confirmDelete(BuildContext context, String id, String name) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dc) => AlertDialog(
      title: const Text('Delete Customer?'), content: Text('Remove "$name"? This cannot be undone.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dc, false), child: const Text('Cancel')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(dc, true), child: const Text('Delete'))]));
    if (confirmed == true && context.mounted) context.read<CustomerBloc>().add(CustomerDeleteRequested(id));
  }
}
