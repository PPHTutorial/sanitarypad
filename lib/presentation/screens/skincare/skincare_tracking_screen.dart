import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/skincare_service.dart';
import '../../../data/models/skincare_model.dart';
import '../../../core/widgets/back_button_handler.dart';

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
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB
    });
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

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Skincare Tracker'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: ResponsiveConfig.margin(horizontal: 16, bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryPink,
                  borderRadius: BorderRadius.circular(30),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[700],
                labelStyle: ResponsiveConfig.textStyle(
                  size: 14,
                  weight: FontWeight.w600,
                ),
                unselectedLabelStyle: ResponsiveConfig.textStyle(
                  size: 14,
                  weight: FontWeight.w400,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.face, size: 20),
                    text: 'Routine',
                  ),
                  Tab(
                    icon: Icon(Icons.inventory_2, size: 20),
                    text: 'Products',
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRoutineTab(context, user.userId),
            _buildProductsTab(context, user.userId),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(context),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        if (_tabController.index == 0) {
          context.push('/skincare-routine-form');
        } else {
          context.push('/skincare-product-form');
        }
      },
      backgroundColor: AppTheme.primaryPink,
      icon: Icon(
        _tabController.index == 0 ? Icons.add : Icons.inventory_2,
        color: Colors.white,
      ),
      label: Text(
        _tabController.index == 0 ? 'Log Routine' : 'Add Product',
        style: ResponsiveConfig.textStyle(
          size: 14,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
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

        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: ResponsiveConfig.padding(all: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: ResponsiveConfig.padding(all: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.lightPink.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.face_outlined,
                      size: ResponsiveConfig.iconSize(64),
                      color: AppTheme.primaryPink,
                    ),
                  ),
                  ResponsiveConfig.heightBox(24),
                  Text(
                    'No Routine Logged Yet',
                    style: ResponsiveConfig.textStyle(
                      size: 20,
                      weight: FontWeight.bold,
                    ),
                  ),
                  ResponsiveConfig.heightBox(8),
                  Text(
                    'Start tracking your skincare routine to see your progress',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: ResponsiveConfig.padding(all: 16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            return _buildEntryCard(context, entries[index]);
          },
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
            // Expiring Products Alert
            StreamBuilder<List<SkincareProduct>>(
              stream: _skincareService.getExpiringProducts(userId),
              builder: (context, expiringSnapshot) {
                final expiring = expiringSnapshot.data ?? [];
                if (expiring.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: ResponsiveConfig.margin(all: 16),
                  padding: ResponsiveConfig.padding(all: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warningOrange.withValues(alpha: 0.15),
                        AppTheme.warningOrange.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.warningOrange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: ResponsiveConfig.padding(all: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.warningOrange.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_rounded,
                          color: AppTheme.warningOrange,
                          size: 24,
                        ),
                      ),
                      ResponsiveConfig.widthBox(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiring Soon',
                              style: ResponsiveConfig.textStyle(
                                size: 14,
                                weight: FontWeight.w600,
                                color: AppTheme.warningOrange,
                              ),
                            ),
                            ResponsiveConfig.heightBox(2),
                            Text(
                              '${expiring.length} product${expiring.length > 1 ? 's' : ''} need attention',
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
                );
              },
            ),

            // Products List
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Padding(
                        padding: ResponsiveConfig.padding(all: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: ResponsiveConfig.padding(all: 24),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.lightPink.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: ResponsiveConfig.iconSize(64),
                                color: AppTheme.primaryPink,
                              ),
                            ),
                            ResponsiveConfig.heightBox(24),
                            Text(
                              'No Products Yet',
                              style: ResponsiveConfig.textStyle(
                                size: 20,
                                weight: FontWeight.bold,
                              ),
                            ),
                            ResponsiveConfig.heightBox(8),
                            Text(
                              'Add your skincare products to track them',
                              style: ResponsiveConfig.textStyle(
                                size: 14,
                                color: AppTheme.mediumGray,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: ResponsiveConfig.padding(all: 16),
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
    final isToday = entry.date.year == DateTime.now().year &&
        entry.date.month == DateTime.now().month &&
        entry.date.day == DateTime.now().day;

    return Card(
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: ResponsiveConfig.margin(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          context.push('/skincare-routine-form', extra: entry);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Date Badge
                  Container(
                    padding: ResponsiveConfig.padding(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppTheme.primaryPink
                          : AppTheme.lightPink.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isToday ? Colors.white : AppTheme.primaryPink,
                        ),
                        ResponsiveConfig.widthBox(6),
                        Text(
                          isToday
                              ? 'Today'
                              : DateFormat('MMM dd').format(entry.date),
                          style: ResponsiveConfig.textStyle(
                            size: 12,
                            weight: FontWeight.w600,
                            color:
                                isToday ? Colors.white : AppTheme.primaryPink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Time Badge
                  Container(
                    padding: ResponsiveConfig.padding(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.palePink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          entry.timeOfDay == 'morning'
                              ? Icons.wb_sunny
                              : entry.timeOfDay == 'evening'
                                  ? Icons.nightlight_round
                                  : Icons.all_inclusive,
                          size: 14,
                          color: AppTheme.primaryPink,
                        ),
                        ResponsiveConfig.widthBox(4),
                        Text(
                          entry.timeOfDay.toUpperCase(),
                          style: ResponsiveConfig.textStyle(
                            size: 11,
                            weight: FontWeight.w600,
                            color: AppTheme.primaryPink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveConfig.widthBox(8),
                  // Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 20,
                    color: AppTheme.mediumGray,
                    onPressed: () {
                      context.push('/skincare-routine-form', extra: entry);
                    },
                  ),
                ],
              ),
              ResponsiveConfig.heightBox(12),
              // Skin Condition
              if (entry.skinCondition != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.face,
                      size: 16,
                      color: AppTheme.primaryPink,
                    ),
                    ResponsiveConfig.widthBox(8),
                    Text(
                      'Skin: ${entry.skinCondition!.toUpperCase()}',
                      style: ResponsiveConfig.textStyle(
                        size: 14,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(8),
              ],
              // Products Used
              if (entry.productsUsed.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 16,
                      color: AppTheme.primaryPink,
                    ),
                    ResponsiveConfig.widthBox(8),
                    Expanded(
                      child: Text(
                        '${entry.productsUsed.length} product${entry.productsUsed.length > 1 ? 's' : ''} used',
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(8),
              ],
              // Photos Preview
              if (entry.photoUrls != null && entry.photoUrls!.isNotEmpty) ...[
                ResponsiveConfig.heightBox(8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: entry.photoUrls!.length > 3
                        ? 3
                        : entry.photoUrls!.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: ResponsiveConfig.margin(right: 8),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(entry.photoUrls![index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: entry.photoUrls!.length > 3 && index == 2
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${entry.photoUrls!.length - 3}',
                                    style: ResponsiveConfig.textStyle(
                                      size: 14,
                                      weight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, SkincareProduct product) {
    final isExpired = product.isExpired;
    final isExpiringSoon = product.isExpiringSoon;

    return Card(
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: ResponsiveConfig.margin(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          context.push('/skincare-product-form', extra: product);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.lightPink.withValues(alpha: 0.3),
                  image: product.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imageUrl == null
                    ? Center(
                        child: Text(
                          product.name.substring(0, 1).toUpperCase(),
                          style: ResponsiveConfig.textStyle(
                            size: 24,
                            weight: FontWeight.bold,
                            color: AppTheme.primaryPink,
                          ),
                        ),
                      )
                    : null,
              ),
              ResponsiveConfig.widthBox(12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: ResponsiveConfig.textStyle(
                        size: 16,
                        weight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ResponsiveConfig.heightBox(4),
                    // Brand
                    if (product.brand != null)
                      Text(
                        product.brand!,
                        style: ResponsiveConfig.textStyle(
                          size: 13,
                          color: AppTheme.mediumGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ResponsiveConfig.heightBox(6),
                    // Category Badge
                    Row(
                      children: [
                        Container(
                          padding: ResponsiveConfig.padding(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPink.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.category.toUpperCase(),
                            style: ResponsiveConfig.textStyle(
                              size: 10,
                              weight: FontWeight.w600,
                              color: AppTheme.primaryPink,
                            ),
                          ),
                        ),
                        // Expiry Status
                        if (isExpired || isExpiringSoon) ...[
                          ResponsiveConfig.widthBox(8),
                          Container(
                            padding: ResponsiveConfig.padding(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? AppTheme.errorRed
                                  : AppTheme.warningOrange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isExpired ? Icons.error : Icons.warning,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                ResponsiveConfig.widthBox(4),
                                Text(
                                  isExpired ? 'EXPIRED' : 'EXPIRING',
                                  style: ResponsiveConfig.textStyle(
                                    size: 10,
                                    weight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Edit Button
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                iconSize: 20,
                color: AppTheme.mediumGray,
                onPressed: () {
                  context.push('/skincare-product-form', extra: product);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
