// order_list_page.dart — Admin App
// Adds:
//   • "Placed by" chip on each order card showing officer/admin name
//   • Filter-by-admin dropdown (builds list from loaded orders)
//   • Passes createdById filter through to OrderLoadAllRequested

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/value_objects/order_status.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../widgets/order_card_tile.dart';
import '../widgets/order_list_row.dart';
import '../widgets/order_table_row.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/order_confirm_delete_dialog.dart';

enum _ViewMode { cards, list, table }

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  _ViewMode _viewMode = _ViewMode.cards;
  OrderStatus? _filterStatus;
  String _search = '';

  // ── Admin/officer filter ──────────────────────────────────
  /// actorId of the selected officer/admin filter, or null for "All".
  String? _filterAdminId;

  /// Map of actorId → display name built from loaded orders.
  Map<String, String> _adminNames = {};

  void _loadOrders() {
    context.read<OrderBloc>().add(
      OrderLoadAllRequested(createdById: _filterAdminId),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  /// Build the actor-name map from a loaded list (runs client-side on
  /// the already-fetched page; the server-side filter handles larger sets).
  void _buildAdminNames(List<OrderEntity> items) {
    final map = <String, String>{};
    for (final o in items) {
      if (o.createdById != null && o.createdById!.isNotEmpty) {
        final name = o.createdByName ?? o.createdById!;
        map[o.createdById!] = name;
      }
    }
    if (map != _adminNames) {
      // Update only when content changes to avoid rebuild loops
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _adminNames = map);
      });
    }
  }

  List<OrderEntity> _apply(List<OrderEntity> all) {
    var result = all;
    if (_filterStatus != null) {
      result = result
          .where((o) => OrderStatusX.fromString(o.status) == _filterStatus)
          .toList();
    }
    // Client-side admin filter (supplements server-side filter for UX
    // when switching between admins without a round-trip).
    if (_filterAdminId != null) {
      result = result.where((o) => o.createdById == _filterAdminId).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result
          .where(
            (o) =>
                o.id.toLowerCase().contains(q) ||
                o.customerId.toLowerCase().contains(q) ||
                (o.paymentRef?.toLowerCase().contains(q) ?? false) ||
                (o.createdByName?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          // ── View-mode toggles ──────────────────────────────
          IconButton(
            icon: Icon(
              Icons.grid_view_outlined,
              color: _viewMode == _ViewMode.cards ? scheme.primary : null,
            ),
            tooltip: 'Cards',
            onPressed: () => setState(() => _viewMode = _ViewMode.cards),
          ),
          IconButton(
            icon: Icon(
              Icons.view_list_outlined,
              color: _viewMode == _ViewMode.list ? scheme.primary : null,
            ),
            tooltip: 'List',
            onPressed: () => setState(() => _viewMode = _ViewMode.list),
          ),
          IconButton(
            icon: Icon(
              Icons.table_rows_outlined,
              color: _viewMode == _ViewMode.table ? scheme.primary : null,
            ),
            tooltip: 'Table',
            onPressed: () => setState(() => _viewMode = _ViewMode.table),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: _loadOrders,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.orderCreate),
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
      body: Column(
        children: [
          // ── Search + status filter ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search orders…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 8),
                // Status filter
                PopupMenuButton<OrderStatus?>(
                  icon: Icon(
                    Icons.filter_list_outlined,
                    color: _filterStatus != null ? scheme.primary : null,
                  ),
                  tooltip: 'Filter by status',
                  onSelected: (v) => setState(() => _filterStatus = v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    ...OrderStatus.values.map(
                      (s) => PopupMenuItem(
                        value: s,
                        child: OrderStatusBadge(status: s, compact: true),
                      ),
                    ),
                  ],
                ),
                // ── Admin/officer filter ───────────────────────
                if (_adminNames.isNotEmpty)
                  PopupMenuButton<String?>(
                    icon: Icon(
                      Icons.person_search_outlined,
                      color: _filterAdminId != null ? scheme.primary : null,
                    ),
                    tooltip: 'Filter by admin / officer',
                    onSelected: (v) {
                      setState(() => _filterAdminId = v);
                      // Re-fetch from server with the new filter
                      context.read<OrderBloc>().add(
                        OrderLoadAllRequested(createdById: v),
                      );
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All admins / officers'),
                      ),
                      ..._adminNames.entries.map(
                        (e) => PopupMenuItem(
                          value: e.key,
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16),
                              const SizedBox(width: 8),
                              Text(e.value),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Status filter chips ─────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Row(
              children: [
                _Chip(
                  label: 'All',
                  selected: _filterStatus == null,
                  onTap: () => setState(() => _filterStatus = null),
                ),
                ...OrderStatus.values.map(
                  (s) => _Chip(
                    label: s.displayName,
                    selected: _filterStatus == s,
                    color: s.color,
                    onTap: () => setState(() => _filterStatus = s),
                  ),
                ),
              ],
            ),
          ),

          // ── Active admin filter chip ────────────────────────
          if (_filterAdminId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Row(
                children: [
                  FilterChip(
                    avatar: const Icon(Icons.person_outline, size: 14),
                    label: Text(_adminNames[_filterAdminId] ?? _filterAdminId!),
                    selected: true,
                    onSelected: (_) {
                      setState(() => _filterAdminId = null);
                      _loadOrders();
                    },
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      setState(() => _filterAdminId = null);
                      _loadOrders();
                    },
                  ),
                ],
              ),
            ),

          // ── Order list ──────────────────────────────────────
          Expanded(
            child: BlocConsumer<OrderBloc, OrderState>(
              listener: (context, state) {
                if (state is OrderOperationSuccess) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                  _loadOrders();
                }
                if (state is OrderFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: scheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is OrderLoading || state is OrderInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is OrderFailure) {
                  return Center(child: Text(state.message));
                }
                if (state is OrderEmpty) {
                  return const Center(child: Text('No orders found.'));
                }

                List<OrderEntity> items = [];
                if (state is OrderListLoaded) {
                  items = state.items;
                  _buildAdminNames(items);
                }

                final filtered = _apply(items);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No orders match the filter.'),
                  );
                }

                return _buildView(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildView(List<OrderEntity> items) {
    switch (_viewMode) {
      case _ViewMode.cards:
        return _buildCards(items);
      case _ViewMode.list:
        return _buildList(items);
      case _ViewMode.table:
        return _buildTable(items);
    }
  }

  Widget _buildCards(List<OrderEntity> items) {
    final width = MediaQuery.of(context).size.width;
    final cols = width < 600
        ? 1
        : width < 900
        ? 2
        : 3;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => OrderCardTile(
        item: items[i],
        onTap: () => context.push(AppRouter.orderDetailPath(items[i].id)),
        onDelete: () => _confirmDelete(items[i]),
      ),
    );
  }

  Widget _buildList(List<OrderEntity> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) => OrderListRow(
        item: items[i],
        onTap: () => context.push(AppRouter.orderDetailPath(items[i].id)),
        onDelete: () => _confirmDelete(items[i]),
      ),
    );
  }

  Widget _buildTable(List<OrderEntity> items) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const idW = 120.0;
        const customerW = 140.0;
        const placedByW = 110.0;
        const itemsW = 52.0;
        const totalW = 90.0;
        const statusW = 100.0;
        const actionsW = 44.0;
        const totalFixed =
            idW + customerW + placedByW + itemsW + totalW + statusW + actionsW;
        final customerFlex = availableWidth > totalFixed
            ? availableWidth - (totalFixed - customerW)
            : customerW;

        Widget headerCell(String text, double width) => SizedBox(
          width: width,
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        );

        return Column(
          children: [
            // Header
            Container(
              color: scheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  headerCell('Order', idW),
                  headerCell('Customer', customerFlex),
                  headerCell('Placed by', placedByW),
                  headerCell('Items', itemsW),
                  headerCell('Total', totalW),
                  headerCell('Status', statusW),
                  SizedBox(width: actionsW),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) => OrderTableRow(
                  item: items[i],
                  isLast: i == items.length - 1,
                  onTap: () =>
                      context.push(AppRouter.orderDetailPath(items[i].id)),
                  // FIX: supply the required onDelete callback
                  onDelete: () => _confirmDelete(items[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(OrderEntity item) async {
    final confirmed = await OrderConfirmDeleteDialog.show(
      context,
      orderId: item.id,
    );
    if (confirmed && mounted) {
      context.read<OrderBloc>().add(OrderDeleteRequested(item.id));
    }
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = color ?? scheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.12)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? activeColor : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
