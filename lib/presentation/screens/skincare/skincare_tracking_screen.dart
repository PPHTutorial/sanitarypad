import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/skincare_service.dart';
import '../../../data/models/skincare_model.dart';

/// Skincare tracking screen
class SkincareTrackingScreen extends ConsumerStatefulWidget {
  const SkincareTrackingScreen({super.key});

  @override
  ConsumerState<SkincareTrackingScreen> createState() =>
      _SkincareTrackingScreenState();
}

class _SkincareTrackingScreenState extends ConsumerState<SkincareTrackingScreen>
    with SingleTickerProviderStateMixin {
  final _skincareService = SkincareService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skincare Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Routine', icon: Icon(Icons.face)),
            Tab(text: 'Products', icon: Icon(Icons.inventory)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRoutineTab(context, user.userId),
          _buildProductsTab(context, user.userId),
        ],
      ),
    );
  }

  Widget _buildRoutineTab(BuildContext context, String userId) {
    final startDate = DateTime.now().subtract(const Duration(days: 30));
    final endDate = DateTime.now().add(const Duration(days: 7));

    return StreamBuilder<List<SkincareEntry>>(
      stream: _skincareService.getEntries(userId, startDate, endDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data ?? [];

        return Column(
          children: [
            // Add Entry Button
            Padding(
              padding: ResponsiveConfig.padding(all: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/skincare-routine-form');
                },
                icon: const Icon(Icons.add),
                label: const Text('Log Skincare Routine'),
                style: ElevatedButton.styleFrom(
                  padding: ResponsiveConfig.padding(vertical: 16),
                ),
              ),
            ),

            // Entries List
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.face_outlined,
                            size: ResponsiveConfig.iconSize(64),
                            color: AppTheme.mediumGray,
                          ),
                          ResponsiveConfig.heightBox(16),
                          Text(
                            'No skincare entries yet',
                            style: ResponsiveConfig.textStyle(
                              size: 16,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: ResponsiveConfig.padding(horizontal: 16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        return _buildEntryCard(context, entries[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductsTab(BuildContext context, String userId) {
    return StreamBuilder<List<SkincareProduct>>(
      stream: _skincareService.getUserProducts(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data ?? [];

        return Column(
          children: [
            // Add Product Button
            Padding(
              padding: ResponsiveConfig.padding(all: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/skincare-product-form');
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  padding: ResponsiveConfig.padding(vertical: 16),
                ),
              ),
            ),

            // Expiring Products Alert
            StreamBuilder<List<SkincareProduct>>(
              stream: _skincareService.getExpiringProducts(userId),
              builder: (context, expiringSnapshot) {
                final expiring = expiringSnapshot.data ?? [];
                if (expiring.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: ResponsiveConfig.margin(horizontal: 16, bottom: 16),
                  padding: ResponsiveConfig.padding(all: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withOpacity(0.1),
                    borderRadius: ResponsiveConfig.borderRadius(8),
                    border: Border.all(color: AppTheme.warningOrange),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: AppTheme.warningOrange,
                      ),
                      ResponsiveConfig.widthBox(8),
                      Expanded(
                        child: Text(
                          '${expiring.length} product(s) expiring soon',
                          style: ResponsiveConfig.textStyle(
                            size: 14,
                            color: AppTheme.warningOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Products List
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: ResponsiveConfig.iconSize(64),
                            color: AppTheme.mediumGray,
                          ),
                          ResponsiveConfig.heightBox(16),
                          Text(
                            'No products yet',
                            style: ResponsiveConfig.textStyle(
                              size: 16,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: ResponsiveConfig.padding(horizontal: 16),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(context, products[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEntryCard(BuildContext context, SkincareEntry entry) {
    return Card(
      margin: ResponsiveConfig.margin(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.lightPink,
          child: Text(
            DateFormat('d').format(entry.date),
            style: ResponsiveConfig.textStyle(
              size: 14,
              weight: FontWeight.bold,
              color: AppTheme.primaryPink,
            ),
          ),
        ),
        title: Text(
          DateFormat('MMM dd, yyyy').format(entry.date),
          style: ResponsiveConfig.textStyle(
            size: 16,
            weight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveConfig.heightBox(4),
            Text(
              'Time: ${entry.timeOfDay}',
              style: ResponsiveConfig.textStyle(size: 14),
            ),
            if (entry.skinCondition != null)
              Text(
                'Condition: ${entry.skinCondition}',
                style: ResponsiveConfig.textStyle(size: 12),
              ),
            if (entry.productsUsed.isNotEmpty)
              Text(
                '${entry.productsUsed.length} product(s) used',
                style: ResponsiveConfig.textStyle(
                  size: 12,
                  color: AppTheme.mediumGray,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            context.push('/skincare-routine-form', extra: entry);
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, SkincareProduct product) {
    return Card(
      margin: ResponsiveConfig.margin(bottom: 12),
      child: ListTile(
        leading: product.imageUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(product.imageUrl!),
              )
            : CircleAvatar(
                backgroundColor: AppTheme.lightPink,
                child: Text(
                  product.name.substring(0, 1).toUpperCase(),
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                    color: AppTheme.primaryPink,
                  ),
                ),
              ),
        title: Text(
          product.name,
          style: ResponsiveConfig.textStyle(
            size: 16,
            weight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.brand != null)
              Text(
                product.brand!,
                style: ResponsiveConfig.textStyle(size: 14),
              ),
            Text(
              product.category.toUpperCase(),
              style: ResponsiveConfig.textStyle(
                size: 12,
                color: AppTheme.primaryPink,
              ),
            ),
            if (product.isExpiringSoon || product.isExpired)
              Container(
                margin: ResponsiveConfig.margin(top: 4),
                padding: ResponsiveConfig.padding(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: product.isExpired
                      ? AppTheme.errorRed
                      : AppTheme.warningOrange,
                  borderRadius: ResponsiveConfig.borderRadius(4),
                ),
                child: Text(
                  product.isExpired ? 'EXPIRED' : 'EXPIRING SOON',
                  style: ResponsiveConfig.textStyle(
                    size: 10,
                    weight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            context.push('/skincare-product-form', extra: product);
          },
        ),
      ),
    );
  }
}
