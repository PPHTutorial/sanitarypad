import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../data/models/transaction_model.dart';

class CreditHistoryScreen extends ConsumerWidget {
  const CreditHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).value;
    final transactionsAsync = user != null
        ? ref.watch(userTransactionsProvider(user.userId))
        : const AsyncValue<List<TransactionModel>>.loading();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit History'),
        centerTitle: true,
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.receipt,
                    size: 64,
                    color: colorScheme.primary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isCredit = tx.type == TransactionType.credit;

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCredit
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: FaIcon(
                    isCredit
                        ? FontAwesomeIcons.arrowUp
                        : FontAwesomeIcons.arrowDown,
                    size: 16,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  tx.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  DateFormat('MMMM d, yyyy • h:mm a').format(tx.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Text(
                  '${isCredit ? '+' : '-'}${tx.amount}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load credit history',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (user != null) {
                      ref.invalidate(userTransactionsProvider(user.userId));
                    }
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
