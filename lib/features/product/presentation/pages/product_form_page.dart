import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/enums/form_mode.dart';
import '../../../category/domain/entities/category_entity.dart';
import '../../../category/presentation/bloc/category_bloc.dart';
import '../../../category/presentation/bloc/category_event.dart';
import '../../../category/presentation/bloc/category_state.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../enums/product_form_node.dart';

/// Product create/edit form.
///
/// Features:
///   - Image picker with camera and gallery options
///   - Product type dropdown (default: physical)
///   - Category dropdown populated via DI (CategoryBloc)
///   - Single price field (wrapped into default variant by datasource)
///   - seller_actor_id injected from OrgContext (not user-entered)
///   - SKU field
///   - Description field
class ProductFormPage extends StatefulWidget {
  final FormMode mode;
  final ProductEntity? product;

  const ProductFormPage({
    super.key,
    this.mode = FormMode.create,
    this.product,
  });

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _skuController;

  final Map<ProductFormNode, FocusNode> _focusNodes = {
    for (final node in ProductFormNode.values) node: FocusNode(),
  };

  ProductType _selectedType = ProductType.physical;
  String? _selectedCategoryId;
  File? _selectedImageFile;
  String? _existingImageUrl;
  bool _isSubmitting = false;

  bool get _isEdit => widget.mode == FormMode.edit;

  @override
  void initState() {
    super.initState();

    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController =
        TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(2) : '',
    );
    _skuController = TextEditingController(text: p?.sku ?? '');

    _selectedType = p?.type ?? ProductType.physical;
    _selectedCategoryId = p?.categoryId;
    _existingImageUrl = p?.imageUrl;

    // Load categories for the dropdown via DI
    _loadCategories();
  }

  void _loadCategories() {
    try {
      context.read<CategoryBloc>().add(const CategoryLoadAllRequested());
    } catch (_) {
      // CategoryBloc not available in widget tree — categories will
      // be empty. This is acceptable in isolated testing.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _skuController.dispose();
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  // ── Image Picker ─────────────────────────────────────────────────

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Image',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImageFile != null || _existingImageUrl != null)
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text('Remove Image',
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedImageFile = null;
                    _existingImageUrl = null;
                  });
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selectedImageFile = File(picked.path));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  // ── Submit ───────────────────────────────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    // seller_actor_id is obtained from OrgContext via the repository.
    // The form does not expose it — it is injected at the data layer.
    final product = ProductEntity(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      type: _selectedType,
      sellerActorId: widget.product?.sellerActorId ?? '',
      categoryId: _selectedCategoryId,
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      currency: widget.product?.currency ?? 'TZS',
      sku: _skuController.text.trim().isEmpty
          ? null
          : _skuController.text.trim(),
      imageUrl: _existingImageUrl,
      status: widget.product?.status ?? ProductStatus.draft,
    );

    if (_isEdit) {
      context.read<ProductBloc>().add(ProductUpdateRequested(product));
    } else {
      context.read<ProductBloc>().add(ProductCreateRequested(product));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'New Product'),
      ),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.of(context).pop();
          }
          if (state is ProductError) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Image Picker ───────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _showImagePickerSheet,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildImagePreview(colorScheme),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Tap to add product image',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Name ───────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                focusNode: _focusNodes[ProductFormNode.name],
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g. Amoxicillin 500mg',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                onFieldSubmitted: (_) =>
                    _focusNodes[ProductFormNode.description]!.requestFocus(),
              ),
              const SizedBox(height: 16),

              // ── Description ────────────────────────────────────
              TextFormField(
                controller: _descriptionController,
                focusNode: _focusNodes[ProductFormNode.description],
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Product description...',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    _focusNodes[ProductFormNode.price]!.requestFocus(),
              ),
              const SizedBox(height: 16),

              // ── Price ──────────────────────────────────────────
              TextFormField(
                controller: _priceController,
                focusNode: _focusNodes[ProductFormNode.price],
                decoration: InputDecoration(
                  labelText: 'Price (TZS) *',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  prefixText: 'TZS ',
                  prefixStyle: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'),
                  ),
                ],
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Price is required';
                  }
                  final price = double.tryParse(v.trim());
                  if (price == null || price < 0) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
                onFieldSubmitted: (_) =>
                    _focusNodes[ProductFormNode.sku]!.requestFocus(),
              ),
              const SizedBox(height: 16),

              // ── SKU ────────────────────────────────────────────
              TextFormField(
                controller: _skuController,
                focusNode: _focusNodes[ProductFormNode.sku],
                decoration: const InputDecoration(
                  labelText: 'SKU',
                  hintText: 'e.g. AMX-500-30',
                  prefixIcon: Icon(Icons.qr_code),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),

              // ── Product Type Dropdown ──────────────────────────
              DropdownButtonFormField<ProductType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Product Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: ProductType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
              const SizedBox(height: 16),

              // ── Category Dropdown (via DI / CategoryBloc) ─────
              _CategoryDropdown(
                selectedCategoryId: _selectedCategoryId,
                onChanged: (id) =>
                    setState(() => _selectedCategoryId = id),
              ),
              const SizedBox(height: 32),

              // ── Submit Button ──────────────────────────────────
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEdit ? 'Update Product' : 'Create Product'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(ColorScheme colorScheme) {
    if (_selectedImageFile != null) {
      return Image.file(_selectedImageFile!, fit: BoxFit.cover);
    }
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return Image.network(
        _existingImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(colorScheme),
      );
    }
    return _imagePlaceholder(colorScheme);
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo_outlined,
          size: 36,
          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
        const SizedBox(height: 6),
        Text(
          'Add Image',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

// ── Category Dropdown (connected to CategoryBloc via DI) ─────────────

class _CategoryDropdown extends StatelessWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          List<CategoryEntity> categories = [];
          if (state is CategoryListLoaded) {
            categories = state.categories;
          }

          return DropdownButtonFormField<String?>(
            value: selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.folder_outlined),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No Category'),
              ),
              ...categories.map((c) => DropdownMenuItem<String?>(
                    value: c.id,
                    child: Text(c.name),
                  )),
            ],
            onChanged: onChanged,
          );
        },
      );
    } catch (_) {
      // CategoryBloc not in tree — show disabled dropdown
      return DropdownButtonFormField<String?>(
        value: null,
        decoration: const InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(Icons.folder_outlined),
          hintText: 'Categories unavailable',
        ),
        items: const [],
        onChanged: null,
      );
    }
  }
}
