import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/skincare_model.dart';
import '../../../services/skincare_service.dart';
import '../../../services/storage_service.dart';

enum ProductInventoryView {
  all,
  active,
  brands,
  totalValue,
  expiringSoon,
}

class SkincareProductManagementScreen extends ConsumerStatefulWidget {
  const SkincareProductManagementScreen({
    super.key,
    this.view = ProductInventoryView.all,
  });

  final ProductInventoryView view;

  @override
  ConsumerState<SkincareProductManagementScreen> createState() =>
      _SkincareProductManagementScreenState();
}

class _SkincareProductManagementScreenState
    extends ConsumerState<SkincareProductManagementScreen> {
  final SkincareService _skincareService = SkincareService();
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteProduct(
      BuildContext context, SkincareProduct product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product'),
        content: Text(
          'Are you sure you want to permanently delete "${product.name}" from your inventory?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      if (product.imagePath != null) {
        try {
          await _storageService.deleteFile(product.imagePath!);
        } catch (_) {}
      }
      await _skincareService.deleteProduct(product.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${product.name}" deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleArchive(
    BuildContext context,
    SkincareProduct product,
  ) async {
    final shouldArchive = product.isActive;
    try {
      await _skincareService.updateProduct(
        product.copyWith(
          isActive: !product.isActive,
          updatedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shouldArchive
                ? '"${product.name}" archived'
                : '"${product.name}" restored',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating product: ${e.toString()}')),
      );
    }
  }

  void _openEditor(BuildContext context, SkincareProduct? product) {
    context.push('/skincare-product-form', extra: product);
  }

  void _showProductDetails(BuildContext context, SkincareProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (product.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          product.imageUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppTheme.primaryPink,
                        ),
                      ),
                    ResponsiveConfig.widthBox(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: ResponsiveConfig.textStyle(
                              size: 18,
                              weight: FontWeight.bold,
                            ),
                          ),
                          if (product.brand?.isNotEmpty == true)
                            Text(product.brand!),
                          Text(
                            product.category.replaceAll('_', ' ').toUpperCase(),
                            style: ResponsiveConfig.textStyle(
                              size: 12,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(16),
                if (product.notes != null && product.notes!.isNotEmpty) ...[
                  Text(
                    'Notes',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      weight: FontWeight.w600,
                    ),
                  ),
                  ResponsiveConfig.heightBox(4),
                  Text(product.notes!),
                  ResponsiveConfig.heightBox(12),
                ],
                _DetailRow(
                  icon: Icons.event,
                  label: 'Added',
                  value: DateFormat('MMM d, y').format(product.createdAt),
                ),
                if (product.purchaseDate != null)
                  _DetailRow(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Purchase date',
                    value: DateFormat('MMM d, y').format(product.purchaseDate!),
                  ),
                if (product.expirationDate != null)
                  _DetailRow(
                    icon: Icons.event_busy_outlined,
                    label: 'Expires',
                    value:
                        DateFormat('MMM d, y').format(product.expirationDate!),
                  ),
                if (product.price != null)
                  _DetailRow(
                    icon: Icons.attach_money,
                    label: 'Price',
                    value: '\$${product.price!.toStringAsFixed(2)}',
                  ),
                ResponsiveConfig.heightBox(16),
                Row(
                  spacing: 12,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openEditor(context, product);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _toggleArchive(context, product);
                      },
                      icon: Icon(
                        product.isActive
                            ? Icons.archive_outlined
                            : Icons.unarchive_outlined,
                      ),
                      label: Text(product.isActive ? 'Archive' : 'Restore'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteProduct(context, product);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _viewTitle(ProductInventoryView view) {
    switch (view) {
      case ProductInventoryView.all:
        return 'Product Inventory';
      case ProductInventoryView.active:
        return 'Active Products';
      case ProductInventoryView.brands:
        return 'Brands Overview';
      case ProductInventoryView.totalValue:
        return 'Inventory Value';
      case ProductInventoryView.expiringSoon:
        return 'Expiring Soon';
    }
  }

  String? _viewSubtitle(ProductInventoryView view) {
    switch (view) {
      case ProductInventoryView.all:
        return 'Overall snapshot of products across your FemCare+ routine.';
      case ProductInventoryView.active:
        return 'Products currently in rotation. Archive items you are no longer using.';
      case ProductInventoryView.brands:
        return 'Review products by brand to see which labels dominate your shelf.';
      case ProductInventoryView.totalValue:
        return 'Total investment in skincare with price insights per product.';
      case ProductInventoryView.expiringSoon:
        return 'Items nearing expiration. Use, rotate or recycle before they go bad.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_viewTitle(widget.view)),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('User not found. Please log in again.'),
            );
          }

          return StreamBuilder<List<SkincareProduct>>(
            stream: _skincareService.getProducts(user.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = snapshot.data ?? [];
              final view = widget.view;
              final allowArchivedToggle = view == ProductInventoryView.all;
              final showArchived = allowArchivedToggle && _showArchived;
              final query = _searchController.text.trim().toLowerCase();

              Iterable<SkincareProduct> working = products;

              if (view == ProductInventoryView.expiringSoon) {
                working = working.where(
                  (p) => p.isExpiringSoon || p.isExpired,
                );
              } else if (view == ProductInventoryView.active) {
                working = working.where((p) => p.isActive);
              } else if (view == ProductInventoryView.brands ||
                  view == ProductInventoryView.totalValue) {
                working = working.where((p) => p.isActive);
              } else if (!showArchived) {
                working = working.where((p) => p.isActive);
              }

              List<SkincareProduct> filtered = working.where((product) {
                if (query.isEmpty) return true;
                final searchable = [
                  product.name,
                  product.brand ?? '',
                  product.category,
                ].join(' ').toLowerCase();
                return searchable.contains(query);
              }).toList();

              switch (view) {
                case ProductInventoryView.brands:
                  filtered.sort((a, b) {
                    final brandA = (a.brand ?? 'Unbranded').toLowerCase();
                    final brandB = (b.brand ?? 'Unbranded').toLowerCase();
                    final compare = brandA.compareTo(brandB);
                    if (compare != 0) return compare;
                    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                  });
                  break;
                case ProductInventoryView.totalValue:
                  filtered.sort(
                    (a, b) => (b.price ?? 0).compareTo(a.price ?? 0),
                  );
                  break;
                case ProductInventoryView.expiringSoon:
                  filtered.sort((a, b) {
                    final aDate = a.expirationDate ??
                        DateTime.now().add(const Duration(days: 3650));
                    final bDate = b.expirationDate ??
                        DateTime.now().add(const Duration(days: 3650));
                    return aDate.compareTo(bDate);
                  });
                  break;
                default:
                  filtered.sort(
                    (a, b) => b.createdAt.compareTo(a.createdAt),
                  );
                  break;
              }

              final insights = _InventoryInsightsBanner(
                view: view,
                filtered: filtered,
                allProducts: products,
              );

              final searchSection = Padding(
                padding: ResponsiveConfig.padding(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_viewSubtitle(view) != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _viewSubtitle(view)!,
                          style: ResponsiveConfig.textStyle(
                            size: 14,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ),
                    _SearchBar(
                      controller: _searchController,
                      onClear: () => setState(() {
                        _searchController.clear();
                      }),
                    ),
                    if (allowArchivedToggle)
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _showArchived,
                        onChanged: (value) =>
                            setState(() => _showArchived = value),
                        title: const Text('Show archived products'),
                      ),
                  ],
                ),
              );

              if (filtered.isEmpty) {
                return Padding(
                  padding: ResponsiveConfig.padding(all: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      searchSection,
                      if (insights != null) insights,
                      Expanded(
                        child: const _EmptyInventoryState(),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  searchSection,
                  if (insights != null)
                    Padding(
                      padding:
                          ResponsiveConfig.padding(horizontal: 16, vertical: 4),
                      child: insights,
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding:
                          ResponsiveConfig.padding(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return _ProductManagementTile(
                          product: product,
                          onView: () => _showProductDetails(context, product),
                          onEdit: () => _openEditor(context, product),
                          onArchive: () => _toggleArchive(context, product),
                          onDelete: () => _deleteProduct(context, product),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error loading user: $err'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Add product'),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.clear),
              ),
        hintText: 'Search by name, brand or category',
        border: OutlineInputBorder(
          borderRadius: ResponsiveConfig.borderRadius(12),
        ),
      ),
    );
  }
}

class _ProductManagementTile extends StatelessWidget {
  const _ProductManagementTile({
    required this.product,
    required this.onView,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  final SkincareProduct product;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isArchived = !product.isActive;
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(horizontal: 16, vertical: 8),
        child: ListTile(
          contentPadding: ResponsiveConfig.padding(horizontal: 16, vertical: 8),
          onTap: onView,
          leading: product.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product.imageUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPink.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppTheme.primaryPink,
                  ),
                ),
          title: Row(
            children: [
              Expanded(
                  child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
              if (isArchived)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Chip(
                    label: Text(
                      'Archived',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.grey,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          subtitle: Text(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            [
              if (product.brand?.isNotEmpty == true) product.brand!,
              product.category.replaceAll('_', ' ').toUpperCase(),
              /* if (product.expirationDate != null)
              'Expires ${DateFormat('MMM d, y').format(product.expirationDate!)}', */
            ].join(' • '),
          ),
          trailing: PopupMenuButton<String>(
            menuPadding: ResponsiveConfig.padding(horizontal: 24, vertical: 8),
            borderRadius: ResponsiveConfig.borderRadius(12),
            onSelected: (value) {
              switch (value) {
                case 'view':
                  onView();
                  break;
                case 'edit':
                  onEdit();
                  break;
                case 'archive':
                  onArchive();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: ListTile(
                  leading: Icon(Icons.visibility_outlined),
                  title: Text('View details'),
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit Product'),
                ),
              ),
              PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  leading: Icon(
                    product.isActive
                        ? Icons.archive_outlined
                        : Icons.unarchive_outlined,
                  ),
                  title: Text(product.isActive ? 'Archive' : 'Restore'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryPink),
          ResponsiveConfig.widthBox(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ResponsiveConfig.textStyle(
                    size: 12,
                    color: AppTheme.mediumGray,
                  ),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.inventory_2_outlined,
          size: 64,
          color: AppTheme.primaryPink,
        ),
        ResponsiveConfig.heightBox(12),
        Text(
          'No products yet',
          style: ResponsiveConfig.textStyle(
            size: 18,
            weight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        ResponsiveConfig.heightBox(8),
        Text(
          'Add your skincare products to track expiration dates, brands and routine coverage.',
          style: ResponsiveConfig.textStyle(
            size: 14,
            color: AppTheme.mediumGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

Widget? _InventoryInsightsBanner({
  required ProductInventoryView view,
  required List<SkincareProduct> filtered,
  required List<SkincareProduct> allProducts,
}) {
  if (filtered.isEmpty) return null;

  final stats = <MapEntry<String, String>>[];
  String? caption;

  switch (view) {
    case ProductInventoryView.all:
      final active = allProducts.where((p) => p.isActive).length;
      final archived = allProducts.length - active;
      final brands = allProducts
          .where((p) => (p.brand ?? '').trim().isNotEmpty)
          .map((p) => p.brand!.trim())
          .toSet()
          .length;
      final totalValue = allProducts.fold<double>(
        0.0,
        (sum, product) => sum + (product.price ?? 0.0),
      );
      stats
        ..add(MapEntry('Active', active.toString()))
        ..add(MapEntry('Archived', archived.toString()))
        ..add(MapEntry('Brands', brands.toString()))
        ..add(MapEntry('Inventory value', _formatCurrency(totalValue)));
      break;
    case ProductInventoryView.active:
      final categories = filtered.map((p) => p.category).toSet().length;
      final averageValue = filtered.isEmpty
          ? 0.0
          : filtered.fold<double>(0.0, (sum, p) => sum + (p.price ?? 0.0)) /
              filtered.length;
      stats
        ..add(MapEntry('Active products', filtered.length.toString()))
        ..add(MapEntry('Categories', categories.toString()))
        ..add(MapEntry('Avg. price', _formatCurrency(averageValue)));
      break;
    case ProductInventoryView.brands:
      final brandGroups = <String, int>{};
      for (final product in filtered) {
        final key = (product.brand ?? '').trim().isEmpty
            ? 'Unbranded'
            : product.brand!.trim();
        brandGroups[key] = (brandGroups[key] ?? 0) + 1;
      }
      final topBrand = brandGroups.entries.isEmpty
          ? null
          : brandGroups.entries.reduce(
              (a, b) => a.value >= b.value ? a : b,
            );
      stats
        ..add(MapEntry('Unique brands', brandGroups.length.toString()))
        ..add(MapEntry('Most used',
            topBrand == null ? '—' : '${topBrand.key} (${topBrand.value})'));
      caption = 'Tap a product to edit or archive items for a specific brand.';
      break;
    case ProductInventoryView.totalValue:
      final totalValue = filtered.fold<double>(
        0.0,
        (sum, product) => sum + (product.price ?? 0.0),
      );
      final averageValue =
          filtered.isEmpty ? 0.0 : totalValue / filtered.length;
      stats
        ..add(MapEntry('Total value', _formatCurrency(totalValue)))
        ..add(MapEntry('Average price', _formatCurrency(averageValue)))
        ..add(MapEntry('Products counted', filtered.length.toString()));
      break;
    case ProductInventoryView.expiringSoon:
      final soon =
          filtered.where((p) => p.isExpiringSoon && !p.isExpired).length;
      final expired = filtered.where((p) => p.isExpired).length;
      final nextExpiry = filtered
          .where((p) => p.expirationDate != null)
          .map((p) => p.expirationDate!)
          .fold<DateTime?>(
            null,
            (previousValue, element) =>
                previousValue == null || element.isBefore(previousValue)
                    ? element
                    : previousValue,
          );
      stats
        ..add(MapEntry('Expiring soon', soon.toString()))
        ..add(MapEntry('Expired', expired.toString()))
        ..add(MapEntry(
            'Next expiry',
            nextExpiry == null
                ? '—'
                : DateFormat('MMM d, y').format(nextExpiry)));
      caption =
          'Use or rotate these items to keep your regimen fresh and effective.';
      break;
  }

  return Card(
    child: Padding(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (caption != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                caption,
                style: ResponsiveConfig.textStyle(
                  size: 13,
                  color: AppTheme.mediumGray,
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 12,
              children: stats
                  .map((entry) => _buildInsightPill(entry.key, entry.value))
                  .toList(),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildInsightPill(String label, String value) {
  return Container(
    width: 160,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppTheme.primaryPink.withOpacity(0.08),
      borderRadius: ResponsiveConfig.borderRadius(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: ResponsiveConfig.textStyle(
            size: 18,
            weight: FontWeight.w600,
          ),
        ),
        ResponsiveConfig.heightBox(6),
        Text(
          label,
          style: ResponsiveConfig.textStyle(
            size: 12,
            color: AppTheme.mediumGray,
          ),
        ),
      ],
    ),
  );
}

String _formatCurrency(double value) {
  final formatter = NumberFormat.simpleCurrency(
    decimalDigits: value == value.roundToDouble() ? 0 : 2,
  );
  return formatter.format(value);
}
