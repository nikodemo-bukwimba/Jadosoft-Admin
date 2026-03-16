import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/payment_entity.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';

enum _ViewMode { list, table }

class PaymentListPage extends StatefulWidget {
  const PaymentListPage({super.key});

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends State<PaymentListPage> {
  _ViewMode _viewMode = _ViewMode.list;
  String? _filterStatus;
  String _search = '';

  static const _statuses = ['confirmed', 'pending', 'failed'];

  List<PaymentEntity> _apply(List<PaymentEntity> all) {
    var result = all;
    if (_filterStatus != null) {
      result = result.where((p) => p.status == _filterStatus).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result
          .where((p) =>
              p.id.toLowerCase().contains(q) ||
              p.orderId.toLowerCase().contains(q) ||
              p.provider.toLowerCase().contains(q) ||
              (p.transactionRef?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            icon: Icon(Icons.view_list_outlined,
                color: _viewMode == _ViewMode.list ? scheme.primary : null),
            tooltip: 'List',
            onPressed: () => setState(() => _viewMode = _ViewMode.list),
          ),
          IconButton(
            icon: Icon(Icons.table_rows_outlined,
                color: _viewMode == _ViewMode.table ? scheme.primary : null),
            tooltip: 'Table',
            onPressed: () => setState(() => _viewMode = _ViewMode.table),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<PaymentBloc>().add(PaymentLoadAllRequested()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search payments…',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                _Chip(
                  label: 'All',
                  selected: _filterStatus == null,
                  color: scheme.primary,
                  onTap: () => setState(() => _filterStatus = null),
                ),
                ..._statuses.map((s) => _Chip(
                      label: _label(s),
                      selected: _filterStatus == s,
                      color: _statusColor(s),
                      onTap: () => setState(() => _filterStatus = s),
                    )),
              ],
            ),
          ),

          Expanded(
            child: BlocConsumer<PaymentBloc, PaymentState>(
              listener: (context, state) {
                if (state is PaymentOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                  context
                      .read<PaymentBloc>()
                      .add(PaymentLoadAllRequested());
                }
                if (state is PaymentFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(state.message),
                        backgroundColor: scheme.error),
                  );
                }
              },
              builder: (context, state) {
                if (state is PaymentLoading || state is PaymentInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is PaymentFailure) {
                  return Center(child: Text(state.message));
                }
                if (state is PaymentEmpty) {
                  return const Center(child: Text('No payments found.'));
                }

                List<PaymentEntity> items = [];
                if (state is PaymentListLoaded) items = state.items;

                final filtered = _apply(items);
                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No payments match the filter.'));
                }

                return _viewMode == _ViewMode.list
                    ? _buildList(filtered)
                    : _buildTable(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<PaymentEntity> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) => _PaymentListRow(
        item: items[i],
        onTap: () =>
            context.push(AppRouter.paymentDetailPath(items[i].id)),
      ),
    );
  }

  Widget _buildTable(List<PaymentEntity> items) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 24),
            child: IntrinsicWidth(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      border: Border(
                          bottom: BorderSide(
                              color: scheme.outlineVariant
                                  .withValues(alpha: 0.4))),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                            flex: 2,
                            child: Text('Ref',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12))),
                        Expanded(
                            flex: 2,
                            child: Text('Order',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12))),
                        SizedBox(
                            width: 70,
                            child: Text('Provider',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12))),
                        SizedBox(
                            width: 80,
                            child: Text('Amount',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12))),
                        SizedBox(
                            width: 80,
                            child: Text('Status',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12))),
                      ],
                    ),
                  ),
                  ...items.asMap().entries.map((e) => _PaymentTableRow(
                        item: e.value,
                        isLast: e.key == items.length - 1,
                        onTap: () => context
                            .push(AppRouter.paymentDetailPath(e.value.id)),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
        'confirmed' => Colors.green,
        'pending' => Colors.orange,
        'failed' => Colors.red,
        _ => Colors.grey,
      };

  String _label(String s) => switch (s) {
        'confirmed' => 'Confirmed',
        'pending' => 'Pending',
        'failed' => 'Failed',
        _ => s,
      };
}

// ─────────────────────────────────────────────
// List row
// ─────────────────────────────────────────────

class _PaymentListRow extends StatelessWidget {
  final PaymentEntity item;
  final VoidCallback onTap;

  const _PaymentListRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = _statusColor(item.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(_providerIcon(item.provider),
                      color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.transactionRef ??
                            'No ref · ${item.provider}',
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Order #${item.orderId.split('-').last.toUpperCase()} · ${item.initiatedAt.toIso8601String().split('T').first}',
                        style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TZS ${_fmt(item.amount)}',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _StatusBadge(status: item.status, compact: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
        'confirmed' => Colors.green,
        'pending' => Colors.orange,
        'failed' => Colors.red,
        _ => Colors.grey,
      };

  IconData _providerIcon(String p) {
    final lower = p.toLowerCase();
    if (lower.contains('mpesa') || lower.contains('m-pesa')) {
      return Icons.phone_android_outlined;
    }
    if (lower.contains('airtel')) return Icons.sim_card_outlined;
    return Icons.payments_outlined;
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─────────────────────────────────────────────
// Table row
// ─────────────────────────────────────────────

class _PaymentTableRow extends StatelessWidget {
  final PaymentEntity item;
  final bool isLast;
  final VoidCallback onTap;

  const _PaymentTableRow(
      {required this.item, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(
                    color: scheme.outlineVariant
                        .withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                item.transactionRef ?? '—',
                style: textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '#${item.orderId.split('-').last.toUpperCase()}',
                style: textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(item.provider,
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            SizedBox(
              width: 80,
              child: Text(
                'TZS ${_fmt(item.amount)}',
                style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 80,
              child: _StatusBadge(status: item.status, compact: true),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;
  const _StatusBadge({required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'confirmed' => Colors.green,
      'pending' => Colors.orange,
      'failed' => Colors.red,
      _ => Colors.grey,
    };
    final label = switch (status) {
      'confirmed' => 'Confirmed',
      'pending' => 'Pending',
      'failed' => 'Failed',
      _ => status,
    };
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? color
                  : scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}