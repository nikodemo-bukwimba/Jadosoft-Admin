import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../enums/product_form_node.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../domain/usecases/create_product_usecase.dart';
import '../../../category/data/datasources/category_mock_datasource.dart';
import '../../../category/domain/entities/category_entity.dart';
import '../widgets/product_image.dart';

class ProductFormPage extends StatefulWidget {
  final ProductFormNode mode;
  final String? id;

  const ProductFormPage({
    super.key,
    this.mode = ProductFormNode.create,
    this.id,
  });

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  /// Holds either a network URL (from existing product) or local file path (from picker).
  String? _imageSource;
  String? _selectedCategoryId;
  bool _isAvailableValue = true;
  bool _isFeaturedValue = false;
  bool _isNewValue = true;

  bool _isSubmitting = false;
  bool _fieldsPopulated = false;

  List<CategoryEntity> _categories = [];
  bool _categoriesLoading = true;

  bool get _isEdit => widget.mode == ProductFormNode.edit;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final ds = CategoryMockDataSource();
      final result = await ds.getAll();
      final cats = result.items.cast<CategoryEntity>();
      if (mounted) {
        setState(() {
          _categories = cats;
          _categoriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _populateFields(ProductState state) {
    if (_isEdit && !_fieldsPopulated && state is ProductDetailLoaded) {
      _nameController.text = state.item.name;
      _descriptionController.text = state.item.description ?? '';
      _priceController.text = state.item.price.toStringAsFixed(0);
      _imageSource = state.item.imageUrl;
      _selectedCategoryId = state.item.categoryId;
      _isAvailableValue = state.item.isAvailable;
      _isFeaturedValue = state.item.isFeatured;
      _isNewValue = state.item.isNew;
      _fieldsPopulated = true;
    }
  }

  // ─── Image Picker ──────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _imageSource = picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Product Image',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    sheetContext,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.camera_alt,
                    color: Theme.of(sheetContext).colorScheme.primary,
                  ),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to capture product image'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    sheetContext,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.photo_library,
                    color: Theme.of(sheetContext).colorScheme.primary,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing image'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_imageSource != null)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      sheetContext,
                    ).colorScheme.errorContainer,
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(sheetContext).colorScheme.error,
                    ),
                  ),
                  title: const Text('Remove Image'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => _imageSource = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Product' : 'New Product')),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductDetailLoaded) {
            setState(() => _populateFields(state));
          }
          if (state is ProductOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is ProductFailure) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (_isEdit && state is ProductLoading && !_fieldsPopulated) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? screenWidth * 0.1 : 16,
                vertical: 16,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Image Picker ──
                    _buildImagePicker(scheme),
                    const SizedBox(height: 24),

                    // ── Fields: side-by-side on wide screens ──
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildNameField()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildPriceField()),
                        ],
                      )
                    else ...[
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildPriceField(),
                    ],
                    const SizedBox(height: 16),

                    _buildDescriptionField(),
                    const SizedBox(height: 16),

                    // ── Category Dropdown ──
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),

                    // ── Toggles ──
                    _buildToggles(),
                    const SizedBox(height: 24),

                    // ── Submit ──
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_isEdit ? Icons.save : Icons.add),
                      label: Text(_isEdit ? 'Save Changes' : 'Create Product'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Form Sections ─────────────────────────────────────────

  Widget _buildImagePicker(ColorScheme scheme) {
    return Center(
      child: GestureDetector(
        onTap: _showImagePickerSheet,
        child: Stack(
          children: [
            ProductImage(
              imageUrl: _imageSource,
              width: 160,
              height: 160,
              borderRadius: 16,
            ),
            // Camera overlay icon
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 3),
                ),
                child: Icon(
                  _imageSource != null ? Icons.edit : Icons.camera_alt,
                  color: scheme.onPrimary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Product Name',
        hintText: 'e.g. Paracetamol 500mg',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.medication_outlined),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Product name is required';
        if (v.trim().length < 2) return 'At least 2 characters';
        return null;
      },
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: const InputDecoration(
        labelText: 'Price (TZS)',
        hintText: 'e.g. 2500',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.payments_outlined),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Price is required';
        final parsed = double.tryParse(v.trim());
        if (parsed == null || parsed < 1) return 'Enter a valid price';
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Brief product description',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description_outlined),
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildCategoryDropdown() {
    if (_categoriesLoading) return const LinearProgressIndicator();

    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: _categories
          .where((c) => c.isActive)
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: (v) => setState(() => _selectedCategoryId = v),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Category is required';
        return null;
      },
    );
  }

  Widget _buildToggles() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Available'),
            subtitle: Text(
              _isAvailableValue
                  ? 'Product is available for order'
                  : 'Product is unavailable',
            ),
            value: _isAvailableValue,
            onChanged: (v) => setState(() => _isAvailableValue = v),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: const Text('New Product'),
            subtitle: const Text('Display "NEW" tag on this product'),
            value: _isNewValue,
            onChanged: (v) => setState(() => _isNewValue = v),
          ),
          if (_isEdit) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              title: const Text('Featured'),
              subtitle: const Text('Managed via status transitions'),
              value: _isFeaturedValue,
              onChanged: null,
            ),
          ],
        ],
      ),
    );
  }

  // ─── Submit ────────────────────────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    if (_isEdit) {
      final currentState = context.read<ProductBloc>().state;
      if (currentState is ProductDetailLoaded) {
        context.read<ProductBloc>().add(
          ProductUpdateRequested(
            currentState.item.copyWith(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              price: double.tryParse(_priceController.text.trim()) ?? 0,
              categoryId: _selectedCategoryId ?? '',
              isAvailable: _isAvailableValue,
              isNew: _isNewValue,
              imageUrl: _imageSource,
            ),
          ),
        );
      }
    } else {
      context.read<ProductBloc>().add(
        ProductCreateRequested(
          CreateProductParams(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            price: double.tryParse(_priceController.text.trim()) ?? 0,
            categoryId: _selectedCategoryId ?? '',
            isAvailable: _isAvailableValue,
            isFeatured: false,
            isNew: _isNewValue,
            imageUrl: _imageSource,
          ),
        ),
      );
    }
  }
}
