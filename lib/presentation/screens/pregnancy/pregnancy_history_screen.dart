import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/responsive_config.dart';
import '../../../../data/models/pregnancy_model.dart';
import '../../../../services/pregnancy_service.dart';
import '../../../../core/providers/auth_provider.dart';

class PregnancyHistoryScreen extends ConsumerWidget {
  const PregnancyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;
    final pregnancyService = ref.read(pregnancyServiceProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pregnancy History'),
      ),
      body: StreamBuilder<List<Pregnancy>>(
        stream: pregnancyService.getPregnancyHistory(user.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pregnancies = snapshot.data ?? [];

          if (pregnancies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 64,
                    color: AppTheme.mediumGray.withOpacity(0.5),
                  ),
                  ResponsiveConfig.heightBox(16),
                  Text(
                    'No past pregnancies found.',
                    style: ResponsiveConfig.textStyle(
                      size: 16,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: ResponsiveConfig.padding(all: 16),
            itemCount: pregnancies.length,
            itemBuilder: (context, index) {
              final pregnancy = pregnancies[index];
              final isCurrent = index == 0 && pregnancy.currentWeek < 42;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isCurrent
                        ? AppTheme.primaryPink.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isCurrent
                              ? AppTheme.primaryPink
                              : AppTheme.mediumGray)
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCurrent ? Icons.favorite : Icons.history,
                      color: isCurrent
                          ? AppTheme.primaryPink
                          : AppTheme.mediumGray,
                    ),
                  ),
                  title: Text(
                    isCurrent ? 'Current Journey' : 'Past Journey',
                    style: ResponsiveConfig.textStyle(
                      size: 16,
                      weight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'LMP: ${DateFormat('MMM d, y').format(pregnancy.lastMenstrualPeriod)}\n'
                    'Due Date: ${pregnancy.dueDate != null ? DateFormat('MMM d, y').format(pregnancy.dueDate!) : 'N/A'}',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    context.push('/pregnancy/details/${pregnancy.id}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
