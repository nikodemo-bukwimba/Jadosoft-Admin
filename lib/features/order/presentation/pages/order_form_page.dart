import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../enums/order_form_node.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../../customer/data/datasources/customer_mock_datasource.dart';
import '../../../customer/data/models/customer_model.dart';
import '../../../product/data/datasources/product_mock_datasource.dart';
import '../../../product/data/models/product_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OrderFormPage — Manual order creation / edit
// ─────────────────────────────────────────────────────────────────────────────

class OrderFormPage extends StatefulWidget {
  final OrderFormNode mode;
  final String? id;

  const OrderFormPage({super.key, this.mode = OrderFormNode.create, this.id});

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _paymentRefController = TextEditingController();

  bool _isSubmitting = false;
  bool _loadingLookups = true;

  List<CustomerModel> _customers = [];
  List<ProductModel> _products = [];
  CustomerModel? _selectedCustomer;
  final List<_OrderLineItem> _lineItems = [];

  @override
  void initState() {
    super.initState();
    _loadLookupData();
  }

  Future<void> _loadLookupData() async {
    final customers = await CustomerMockDataSource().getAll();
    final products = await ProductMockDataSource().getAll();
    if (mounted) {
      setState(() {
        _customers = customers.cast<CustomerModel>();
        _products = products
            .cast<ProductModel>()
            .where((p) => p.isAvailable && p.status != 'archived')
            .toList();
        _loadingLookups = false;
      });
    }
  }

  double get _calculatedTotal =>
      _lineItems.fold(0.0, (sum, e) => sum + e.product.price * e.quantity);

  @override
  void dispose() {
    _paymentRefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == OrderFormNode.create;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Order' : 'Edit Order'),
        centerTitle: false,
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderOperationSuccess) {
            setState(() => _isSubmitting = false);
            context.pop();
          }
          if (state is OrderFailure) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        child: _loadingLookups
            ? const Center(child: CircularProgressIndicator())
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionHeader(
                            label: 'Customer',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 12),
                          _buildCustomerSelector(theme),
                          const SizedBox(height: 24),
                          _SectionHeader(
                            label: 'Order Items',
                            icon: Icons.inventory_2_outlined,
                            trailing: TextButton.icon(
                              onPressed: _addProduct,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Product'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_lineItems.isEmpty)
                            _EmptyItemsPlaceholder(onAdd: _addProduct)
                          else
                            _buildItemsList(theme),
                          const SizedBox(height: 24),
                          _SectionHeader(
                            label: 'Payment Reference',
                            icon: Icons.receipt_outlined,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Optional — leave blank for cash orders. '
                            'M-Pesa/Airtel ref auto-confirms the order.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _paymentRefController,
                            decoration: const InputDecoration(
                              labelText: 'M-Pesa / Airtel Reference (optional)',
                              hintText: 'e.g. MPESA-2024-001',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.tag),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 24),
                          if (_lineItems.isNotEmpty) ...[
                            _TotalCard(total: _calculatedTotal, theme: theme),
                            const SizedBox(height: 24),
                          ],
                          FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isCreate ? 'Create Order' : 'Save Changes',
                                  ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ── Customer selector ──────────────────────────────────────────────────────

  Widget _buildCustomerSelector(ThemeData theme) {
    return FormField<CustomerModel>(
      validator: (_) =>
          _selectedCustomer == null ? 'Please select a customer' : null,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _pickCustomer,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Customer *',
                border: const OutlineInputBorder(),
                errorText: state.errorText,
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: _selectedCustomer == null
                  ? Text(
                      'Select customer...',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCustomer!.businessName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _selectedCustomer!.officeAddress ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomer() async {
    final picked = await showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CustomerListSheet(
        customers: _customers,
        selected: _selectedCustomer,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedCustomer = picked);
    }
  }

  // ── Items list ─────────────────────────────────────────────────────────────

  Widget _buildItemsList(ThemeData theme) {
    return Column(
      children: [
        ..._lineItems.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return _LineItemRow(
            item: item,
            theme: theme,
            onRemove: () => setState(() => _lineItems.removeAt(i)),
            onQtyChanged: (qty) => setState(() => _lineItems[i].quantity = qty),
          );
        }),
        const Divider(height: 24),
      ],
    );
  }

  // ── Add product: two-step — list sheet → qty dialog ────────────────────────

  Future<void> _addProduct() async {
    final alreadyAdded = _lineItems.map((e) => e.product.id).toSet();
    final available = _products
        .where((p) => !alreadyAdded.contains(p.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All available products have been added')),
      );
      return;
    }

    // Step 1: pick product from list — sheet has NO setState, just pops value
    final picked = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductListSheet(products: available),
    );

    if (picked == null || !mounted) return;

    // Step 2: pick qty in a plain AlertDialog — completely isolated state
    final qty = await _showQtyDialog(picked);
    if (qty == null || !mounted) return;

    setState(
      () => _lineItems.add(_OrderLineItem(product: picked, quantity: qty)),
    );
  }

  Future<int?> _showQtyDialog(ProductModel product) {
    int qty = 1;
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TZS ${product.price.toStringAsFixed(0)} per unit',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.outlined(
                    icon: const Icon(Icons.remove),
                    onPressed: qty > 1 ? () => setS(() => qty--) : null,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '$qty',
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    icon: const Icon(Icons.add),
                    onPressed: qty < 999 ? () => setS(() => qty++) : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total: TZS ${(product.price * qty).toStringAsFixed(0)}',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(ctx).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(qty),
              child: const Text('Add to Order'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product to the order')),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    final items = _lineItems
        .map(
          (e) => {
            'productId': e.product.id,
            'name': e.product.name,
            'unitPrice': e.product.price,
            'qty': e.quantity,
            'subtotal': e.product.price * e.quantity,
          },
        )
        .toList();

    context.read<OrderBloc>().add(
      OrderCreateRequested(
        CreateOrderParams(
          customerId: _selectedCustomer!.id,
          items: items,
          total: _calculatedTotal,
          paymentRef: _paymentRefController.text.trim().isEmpty
              ? null
              : _paymentRefController.text.trim(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal line item model
// ─────────────────────────────────────────────────────────────────────────────

class _OrderLineItem {
  final ProductModel product;
  int quantity;
  _OrderLineItem({required this.product, required this.quantity});
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget? trailing;

  const _SectionHeader({
    required this.label,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty items placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyItemsPlaceholder extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyItemsPlaceholder({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_shopping_cart_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No products added yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Product'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Line item row
// ─────────────────────────────────────────────────────────────────────────────

class _LineItemRow extends StatelessWidget {
  final _OrderLineItem item;
  final ThemeData theme;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChanged;

  const _LineItemRow({
    required this.item,
    required this.theme,
    required this.onRemove,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = item.product.price * item.quantity;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'TZS ${item.product.price.toStringAsFixed(0)} × '
                  '${item.quantity} = TZS ${subtotal.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _QtyStepper(value: item.quantity, onChanged: onQtyChanged),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onRemove,
            color: theme.colorScheme.error,
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Qty stepper — used only on the main form page (inside Scaffold/Material)
// ─────────────────────────────────────────────────────────────────────────────

class _QtyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _QtyStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: Icons.remove,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add,
            onTap: value < 999 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null
              ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Total card
// ─────────────────────────────────────────────────────────────────────────────

class _TotalCard extends StatelessWidget {
  final double total;
  final ThemeData theme;

  const _TotalCard({required this.total, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Order Total',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'TZS ${total.toStringAsFixed(0)}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer list sheet — StatelessWidget, pops selected customer
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerListSheet extends StatefulWidget {
  final List<CustomerModel> customers;
  final CustomerModel? selected;

  const _CustomerListSheet({required this.customers, this.selected});

  @override
  State<_CustomerListSheet> createState() => _CustomerListSheetState();
}

class _CustomerListSheetState extends State<_CustomerListSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = widget.customers.where((c) {
      final q = _search.toLowerCase();
      return c.businessName.toLowerCase().contains(q) ||
          (c.ownerName?.toLowerCase().contains(q) ?? false) ||
          (c.officeAddress?.toLowerCase().contains(q) ?? false);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Select Customer',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search by name or address...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final c = filtered[i];
                final isSelected = widget.selected?.id == c.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      c.businessName[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(c.businessName),
                  subtitle: Text(
                    '${c.ownerName ?? ''} · ${c.officeAddress ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                  selected: isSelected,
                  onTap: () => Navigator.of(ctx).pop(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product list sheet — StatelessWidget, pops selected product
// No setState anywhere — qty is handled by AlertDialog in parent
// ─────────────────────────────────────────────────────────────────────────────

class _ProductListSheet extends StatelessWidget {
  final List<ProductModel> products;

  const _ProductListSheet({required this.products});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              'Select Product',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                return ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.medication_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(p.name),
                  subtitle: Text('TZS ${p.price.toStringAsFixed(0)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(ctx).pop(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
