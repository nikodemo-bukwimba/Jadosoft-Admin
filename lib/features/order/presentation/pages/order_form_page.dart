//Origin

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../enums/order_form_node.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../../../config/di/injection_container.dart';
import '../../../../core/context/org_context.dart';
import '../../../customer/domain/repositories/customer_repository.dart';
import '../../../customer/data/models/customer_model.dart';
import '../../../product/domain/repositories/product_repository.dart';
import '../../../product/data/models/product_model.dart';
import '../../../promotion/domain/repositories/promotion_repository.dart';
import '../../../product/domain/services/client_promotion_pricing_service.dart';
import '../../../inventory/domain/usecases/get_variant_stock_usecase.dart';

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
  final Map<String, int> _liveStock = {};
  CustomerModel? _selectedCustomer;
  final List<_OrderLineItem> _lineItems = [];

  bool _sendMobilePayment = false;
  final _paymentPhoneCtrl = TextEditingController();
  String _paymentProvider = 'mpesa';

  @override
  void initState() {
    super.initState();
    _loadLookupData();
  }

  Future<void> _loadLookupData() async {
    try {
      final customerRepo = sl<CustomerRepository>();
      final productRepo = sl<ProductRepository>();

      final customerResult = await customerRepo.getAll();
      final productResult = await productRepo.getAll();

      if (!mounted) return;

      // ── Customers ──────────────────────────────────────────
      final customers = customerResult.fold(
        (_) => <CustomerModel>[],
        (page) => page.items.whereType<CustomerModel>().toList(),
      );

      // ── Products (base list — never fails the form) ────────
      List<ProductModel> products = productResult.fold(
        (_) => <ProductModel>[],
        (list) => list
            .whereType<ProductModel>()
            .where((p) => p.isAvailable && p.status != 'archived')
            .toList(),
      );

      // ── Promotion decoration (best-effort, non-fatal) ──────
      try {
        final promoRepo = sl<PromotionRepository>();
        final pricingService = const ClientPromotionPricingService();
        final promoResult = await promoRepo.getAll();

        promoResult.fold(
          (_) => null, // promotions unavailable — keep plain products
          (promos) {
            products = pricingService
                .decorateProducts(products, promos)
                .whereType<ProductModel>()
                .toList();
          },
        );
      } catch (_) {
        // PromotionRepository not registered or network error —
        // products already loaded above, just skip decoration.
      }

      setState(() {
        _customers = customers;
        _products = products;
        _loadingLookups = false;
      });

      if (widget.mode == OrderFormNode.edit) {
        _populateFromOrder();
      }
    } catch (e) {
      if (mounted) setState(() => _loadingLookups = false);
    }
  }

  // double get _calculatedTotal =>
  //     _lineItems.fold(0.0, (sum, e) => sum + e.product.price * e.quantity);

  double get _calculatedTotal => _lineItems.fold(
    0.0,
    (sum, e) => sum + e.product.effectivePrice * e.quantity,
  );

  @override
  void dispose() {
    _paymentRefController.dispose();
    _paymentPhoneCtrl.dispose();
    super.dispose();
  }

  void _populateFromOrder() {
    final state = context.read<OrderBloc>().state;
    if (state is! OrderDetailLoaded) return;

    final order = state.item;

    // Pre-select customer
    final customer = _customers
        .where((c) => c.id == order.customerId)
        .firstOrNull;
    if (customer != null) {
      setState(() => _selectedCustomer = customer);
    }

    // Pre-fill payment ref
    if (order.paymentRef != null && order.paymentRef!.isNotEmpty) {
      _paymentRefController.text = order.paymentRef!;
    }

    // Pre-fill line items from order items
    final lineItems = <_OrderLineItem>[];
    for (final item in order.items) {
      final productId = item['productId']?.toString() ?? '';
      final qty = int.tryParse(item['qty']?.toString() ?? '1') ?? 1;
      final product = _products.where((p) => p.id == productId).firstOrNull;
      if (product != null) {
        lineItems.add(_OrderLineItem(product: product, quantity: qty));
      }
    }

    if (lineItems.isNotEmpty) {
      setState(
        () => _lineItems
          ..clear()
          ..addAll(lineItems),
      );
    }
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
                          const SizedBox(height: 20),

                          // ── Optional mobile payment prompt ─
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone_in_talk_outlined,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Send Mobile Payment Prompt',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const Spacer(),
                                      Switch(
                                        value: _sendMobilePayment,
                                        onChanged: (v) => setState(
                                          () => _sendMobilePayment = v,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Optionally send an M-Pesa / Airtel Money push notification '
                                    'to a customer phone number.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (_sendMobilePayment) ...[
                                    const SizedBox(height: 16),
                                    // Provider selector
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _ProviderChip(
                                            label: 'M-Pesa',
                                            color: Colors.green,
                                            selected:
                                                _paymentProvider == 'mpesa',
                                            onTap: () => setState(
                                              () => _paymentProvider = 'mpesa',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _ProviderChip(
                                            label: 'Airtel Money',
                                            color: Colors.red,
                                            selected:
                                                _paymentProvider == 'airtel',
                                            onTap: () => setState(
                                              () => _paymentProvider = 'airtel',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _paymentPhoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        labelText: 'Customer Phone Number',
                                        hintText: _paymentProvider == 'mpesa'
                                            ? '07XXXXXXXX'
                                            : '06XXXXXXXX',
                                        prefixIcon: const Icon(
                                          Icons.phone_outlined,
                                        ),
                                        border: const OutlineInputBorder(),
                                        helperText:
                                            'A payment push will be sent to this number.',
                                      ),
                                      validator: (v) {
                                        if (!_sendMobilePayment) return null;
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Enter a phone number or disable mobile payment';
                                        }
                                        final digits = v.trim().replaceAll(
                                          RegExp(r'[\s\-+]'),
                                          '',
                                        );
                                        if (!RegExp(
                                          r'^\d{9,12}$',
                                        ).hasMatch(digits)) {
                                          return 'Enter a valid phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
                          _selectedCustomer!.name, // was: businessName
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _selectedCustomer!.address ??
                              '', // was: officeAddress
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
          // Resolve live stock cap for this line item
          final variantId = item.product.variantId;
          final liveMax =
              (variantId != null && _liveStock.containsKey(variantId))
              ? _liveStock[variantId]!
              : (item.product.quantityAvailable ?? 999);
          final maxStock = liveMax > 0
              ? liveMax
              : 999; // 0 means out-of-stock, uncap stepper — submit will catch it

          return _LineItemRow(
            item: item,
            theme: theme,
            maxStock: maxStock,
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

  Future<int?> _showQtyDialog(ProductModel product) async {
    // Capture context-dependent objects BEFORE any await
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    int? available;
    final variantId = product.variantId;

    if (variantId != null) {
      // Use cached value if already fetched this session
      if (_liveStock.containsKey(variantId)) {
        available = _liveStock[variantId];
      } else {
        try {
          final orgId = sl<OrgContext>().requireRootOrgId();
          final result = await sl<GetVariantStockUseCase>()(
            GetVariantStockParams(orgId: orgId, variantId: variantId),
          );
          result.fold(
            (_) => null, // inventory unavailable — fall back to metadata
            (stock) {
              available = stock.totalStock;
              _liveStock[variantId] = stock.totalStock; // cache it
            },
          );
        } catch (_) {
          // Inventory service unreachable — fall back to metadata
        }
      }
    }

    // Fall back to product metadata if live stock unavailable
    available ??= product.quantityAvailable;

    // Pin to a final local — Dart can't promote variables assigned inside closures
    final a = available;
    final int maxQty = (a != null && a > 0) ? a : 999;

    if (a != null && a == 0) {
      if (!mounted) return null;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${product.name} is out of stock. Available: 0.'),
          backgroundColor: errorColor,
        ),
      );
      return null;
    }

    final localAvailable = a; // used inside the dialog closure
    final controller = TextEditingController(text: '1');
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
              if (product.isOnPromotion) ...[
                Text(
                  'TZS ${product.effectivePrice.toStringAsFixed(0)} per unit',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Was TZS ${product.price.toStringAsFixed(0)} · '
                  '${product.discountPercentage!.toStringAsFixed(0)}% off',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ] else
                Text(
                  'TZS ${product.price.toStringAsFixed(0)} per unit',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 4),
              if (localAvailable != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: localAvailable <= 10
                        ? Colors.orange.withValues(alpha: 0.12)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Available: $localAvailable units',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: localAvailable <= 10
                          ? Colors.orange.shade800
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.outlined(
                    icon: const Icon(Icons.remove),
                    onPressed: qty > 1
                        ? () {
                            setS(() {
                              qty--;
                              controller.text = '$qty';
                            });
                          }
                        : null,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        if (parsed != null && parsed >= 1 && parsed <= maxQty) {
                          setS(() => qty = parsed);
                        } else if (parsed != null && parsed > maxQty) {
                          setS(() {
                            qty = maxQty;
                            controller.text = '$maxQty';
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.text.length),
                            );
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    icon: const Icon(Icons.add),
                    onPressed: qty < maxQty
                        ? () {
                            setS(() {
                              qty++;
                              controller.text = '$qty';
                            });
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total: TZS ${(product.effectivePrice * qty).toStringAsFixed(0)}',
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

    // Inventory check
    for (final line in _lineItems) {
      final available =
          (line.product.variantId != null &&
              _liveStock.containsKey(line.product.variantId))
          ? _liveStock[line.product.variantId]
          : line.product.quantityAvailable;
      if (available != null && available == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${line.product.name} is out of stock.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      if (available != null && line.quantity > available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${line.product.name}: requested ${line.quantity} but only $available available.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    // final items = _lineItems
    //     .map(
    //       (e) => {
    //         'productId': e.product.id,
    //         'variantId': e.product.variantId ?? e.product.id,
    //         'name': e.product.name,
    //         'unitPrice': e.product.price,
    //         'qty': e.quantity,
    //         'subtotal': e.product.price * e.quantity,
    //       },
    //     )
    //     .toList();

    final items = _lineItems
        .map(
          (e) => {
            'productId': e.product.id,
            'variantId': e.product.variantId ?? e.product.id,
            'name': e.product.name,
            'basePrice': e.product.price,
            'unitPrice': e.product.effectivePrice,
            'qty': e.quantity,
            'subtotal': e.product.effectivePrice * e.quantity,
            if (e.product.hasPromotion) ...{
              'promotionId': e.product.promotionId,
              'discountPercentage': e.product.discountPercentage,
            },
          },
        )
        .toList();

    final isEdit = widget.mode == OrderFormNode.edit;

    if (isEdit) {
      // ── Edit: Nexora orders cannot be re-created via basket.
      // Only update the payment reference on the existing order entity.
      final currentState = context.read<OrderBloc>().state;
      if (currentState is OrderDetailLoaded) {
        context.read<OrderBloc>().add(
          OrderUpdateRequested(
            currentState.item.copyWith(
              paymentRef: _paymentRefController.text.trim().isEmpty
                  ? null
                  : _paymentRefController.text.trim(),
            ),
          ),
        );
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load order to update.')),
        );
      }
    } else {
      for (final e in _lineItems) {
        debugPrint(
          'ITEM: name=${e.product.name} id=${e.product.id} variantId=${e.product.variantId}',
        );
      }

      // Build effective paymentRef — append mobile payment info if provided
      final orgContext = sl<OrgContext>();
      final adminName =
          orgContext.actorName ?? orgContext.rootOrgName ?? 'Admin';
      final adminId = orgContext.actorId ?? orgContext.effectiveOrgId;

      final baseRef = _paymentRefController.text.trim();
      final mobileNote =
          _sendMobilePayment && _paymentPhoneCtrl.text.trim().isNotEmpty
          ? 'MOBILE:${_paymentPhoneCtrl.text.trim()}:${_paymentProvider.toUpperCase()}'
          : null;
      final effectiveRef = [
        if (baseRef.isNotEmpty) baseRef,
        ?mobileNote,
      ].join('|');

      context.read<OrderBloc>().add(
        OrderCreateRequested(
          CreateOrderParams(
            customerId: _selectedCustomer!.id,
            items: items,
            total: _calculatedTotal,
            paymentRef: effectiveRef.isEmpty ? null : effectiveRef,
            // ── Officer / Admin identity ──────────────────────
            createdByName: adminName,
            createdById: adminId,
          ),
        ),
      );
    }
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
  final int maxStock;

  const _LineItemRow({
    required this.item,
    required this.theme,
    required this.onRemove,
    required this.onQtyChanged,
    this.maxStock = 999, // default = uncapped if stock unknown
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = item.product.effectivePrice * item.quantity;
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
                if (item.product.isOnPromotion)
                  Row(
                    children: [
                      Text(
                        'TZS ${item.product.price.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'TZS ${item.product.effectivePrice.toStringAsFixed(0)} × '
                        '${item.quantity} = TZS ${subtotal.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
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
          _QtyStepper(
            value: item.quantity,
            maxValue: maxStock,
            onChanged: onQtyChanged,
          ),
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
  final int maxValue; // ← ADD
  final ValueChanged<int> onChanged;

  const _QtyStepper({
    required this.value,
    required this.onChanged,
    this.maxValue = 999, // ← ADD
  });

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
            onTap: value < maxValue
                ? () => onChanged(value + 1)
                : null, // ← FIXED
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
      return c.name.toLowerCase().contains(q) || // was: businessName
          (c.phone?.toLowerCase().contains(q) ??
              false) || // was: ownerName (no ownerName exists)
          (c.address?.toLowerCase().contains(q) ?? false); // was: officeAddress
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
                      c.name[0].toUpperCase(), // was: businessName
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(c.name), // was: businessName
                  subtitle: Text(
                    '${c.phone ?? ''} · ${c.address ?? ''}', // was: ownerName · officeAddress
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

// ─────────────────────────────────────────────────────────────────────────────
// Product list sheet — pops selected product
// ─────────────────────────────────────────────────────────────────────────────

class _ProductListSheet extends StatefulWidget {
  final List<ProductModel> products;
  const _ProductListSheet({required this.products});
  @override
  State<_ProductListSheet> createState() => _ProductListSheetState();
}

class _ProductListSheetState extends State<_ProductListSheet> {
  final _searchCtrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filtered = _q.isEmpty
        ? widget.products
        : widget.products
              .where(
                (p) =>
                    p.name.toLowerCase().contains(_q.toLowerCase()) ||
                    p.id.toLowerCase().contains(_q.toLowerCase()),
              )
              .toList();

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
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _q.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _q = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.medication_outlined,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(p.name),
                        subtitle: p.isOnPromotion
                            ? Row(
                                children: [
                                  Text(
                                    'TZS ${p.effectivePrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'TZS ${p.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : Text('TZS ${p.price.toStringAsFixed(0)}'),
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

class _ProviderChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ProviderChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.10)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? color : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
