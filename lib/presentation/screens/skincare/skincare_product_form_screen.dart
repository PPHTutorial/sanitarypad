import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/skincare_service.dart';
import '../../../data/models/skincare_model.dart';

/// Skincare product form screen
class SkincareProductFormScreen extends ConsumerStatefulWidget {
  final SkincareProduct? product;

  const SkincareProductFormScreen({super.key, this.product});

  @override
  ConsumerState<SkincareProductFormScreen> createState() =>
      _SkincareProductFormScreenState();
}

class _SkincareProductFormScreenState
    extends ConsumerState<SkincareProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skincareService = SkincareService();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'cleanser';
  DateTime? _purchaseDate;
  DateTime? _expirationDate;
  bool _isLoading = false;

  final List<String> _categories = [
    'cleanser',
    'moisturizer',
    'serum',
    'sunscreen',
    'toner',
    'exfoliant',
    'mask',
    'eye_cream',
    'treatment',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _brandController.text = widget.product!.brand ?? '';
      _priceController.text = widget.product!.price?.toString() ?? '';
      _notesController.text = widget.product!.notes ?? '';
      _selectedCategory = widget.product!.category;
      _purchaseDate = widget.product!.purchaseDate;
      _expirationDate = widget.product!.expirationDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final price = _priceController.text.trim().isEmpty
          ? null
          : double.tryParse(_priceController.text.trim());

      if (widget.product != null) {
        // Update existing
        final updated = widget.product!.copyWith(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          brand: _brandController.text.trim().isEmpty
              ? null
              : _brandController.text.trim(),
          purchaseDate: _purchaseDate,
          expirationDate: _expirationDate,
          price: price,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await _skincareService.updateProduct(updated);
      } else {
        // Create new
        final product = SkincareProduct(
          userId: user.userId,
          name: _nameController.text.trim(),
          category: _selectedCategory,
          brand: _brandController.text.trim().isEmpty
              ? null
              : _brandController.text.trim(),
          purchaseDate: _purchaseDate,
          expirationDate: _expirationDate,
          price: price,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: DateTime.now(),
        );
        await _skincareService.createProduct(product);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product != null ? 'Product updated' : 'Product added',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _selectExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expirationDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() => _expirationDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              ResponsiveConfig.heightBox(16),

              // Brand
              TextFormField(
                controller: _brandController,
                decoration: InputDecoration(
                  labelText: 'Brand (Optional)',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
              ),
              ResponsiveConfig.heightBox(16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category.replaceAll('_', ' ').toUpperCase(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              ResponsiveConfig.heightBox(16),

              // Purchase Date
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Purchase Date (Optional)',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                controller: TextEditingController(
                  text: _purchaseDate != null
                      ? DateFormat('yyyy-MM-dd').format(_purchaseDate!)
                      : '',
                ),
                onTap: _selectPurchaseDate,
              ),
              ResponsiveConfig.heightBox(16),

              // Expiration Date
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Expiration Date (Optional)',
                  prefixIcon: const Icon(Icons.event_busy),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                controller: TextEditingController(
                  text: _expirationDate != null
                      ? DateFormat('yyyy-MM-dd').format(_expirationDate!)
                      : '',
                ),
                onTap: _selectExpirationDate,
              ),
              ResponsiveConfig.heightBox(16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price (Optional)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              ResponsiveConfig.heightBox(16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                maxLines: 3,
              ),
              ResponsiveConfig.heightBox(24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: ResponsiveConfig.padding(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.product != null
                            ? 'Update Product'
                            : 'Add Product',
                        style: ResponsiveConfig.textStyle(
                          size: 16,
                          weight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
