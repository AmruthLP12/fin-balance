import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../data/assets/recurring_deposit_service.dart';
import '../../../database/app_database.dart';

class DepositDetailsScreen extends ConsumerWidget {
  final FinancialItem holding;

  const DepositDetailsScreen({super.key, required this.holding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(financialItemByIdProvider(holding.id));
    return itemAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Could not load deposit: $error')),
      ),
      data: (item) {
        if (item == null) {
          return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
        }
        final transactionsAsync = ref.watch(transactionsByItemProvider(
          (profileId: item.profileId, itemId: item.id),
        ));
        final recurring = item.subType == 'recurring_deposit';
        final rate = item.interestRateBasisPoints;
        final compounding = switch (item.depositCompoundingMonths) {
          1 => 'Monthly',
          3 => 'Every 3 months',
          6 => 'Every 6 months',
          12 => 'Yearly',
          _ => '—',
        };
        final tenureMonths = item.tenureMonths ?? 0;
        final tenureLabel = tenureMonths >= 12
            ? '${tenureMonths ~/ 12} years${tenureMonths % 12 == 0 ? '' : ' ${tenureMonths % 12} months'}'
            : '$tenureMonths months';

        return Scaffold(
          appBar: AppBar(title: Text(item.name)),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FinCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recurring ? 'Recurring Deposit' : 'Fixed Deposit',
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      CurrencyFormatter.formatPaise(item.currentValuationPaise),
                      style: AppTypography.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _detail('Invested',
                        CurrencyFormatter.formatPaise(item.initialValuePaise)),
                    _detail('Bank', item.bankName ?? '—'),
                    _detail('Account holder', item.accountHolder ?? '—'),
                    _detail(
                      'Interest rate',
                      rate == null
                          ? '—'
                          : '${(rate / 100).toStringAsFixed(rate % 100 == 0 ? 0 : 2)}% p.a.',
                    ),
                    _detail('Compounding', compounding),
                    _detail(
                      'Deposit type',
                      item.depositCumulative == false
                          ? 'Non-cumulative'
                          : 'Cumulative',
                    ),
                    _detail('Tenure', tenureLabel),
                    _detail(
                      'Tax saving u/s 80C',
                      item.depositTaxSaving == true ? 'Yes' : 'No',
                    ),
                    if (item.startDate != null)
                      _detail(
                          'Started', DateFormatter.formatDate(item.startDate!)),
                    if (item.maturityDate != null)
                      _detail('Matures on',
                          DateFormatter.formatDate(item.maturityDate!)),
                  ],
                ),
              ),
              if (recurring) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'RD installments are added to the ledger when due while the app is open, or the next time it opens.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const Text('Transaction history',
                  style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              transactionsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (error, _) =>
                    Text('Could not load transactions: $error'),
                data: (transactions) => transactions.isEmpty
                    ? const Text('No deposit payments recorded yet.')
                    : FinCard(
                        child: Column(
                          children: [
                            for (final (index, transaction)
                                in transactions.indexed) ...[
                              if (index > 0) const Divider(height: 1),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  transaction.source ==
                                          fixedDepositInterestAutoPostSource
                                      ? 'FD interest'
                                      : (recurring
                                          ? 'RD installment'
                                          : 'FD deposit'),
                                ),
                                subtitle: Text(
                                  '${DateFormatter.formatDate(transaction.transactionDate)}'
                                  '${(transaction.notes ?? '').isEmpty ? '' : ' · ${transaction.notes}'}',
                                ),
                                trailing: Text(CurrencyFormatter.formatPaise(
                                    transaction.amountPaise)),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySmall),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end, style: AppTypography.bodyMedium),
            ),
          ],
        ),
      );
}
