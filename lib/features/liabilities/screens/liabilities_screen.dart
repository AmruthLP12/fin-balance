import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/asset_categories.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/finbalance_logo.dart';
import '../../../core/widgets/section_header.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';
import '../../profile/widgets/profile_menu_button.dart';
import '../widgets/add_liability_dialog.dart';

class LiabilitiesScreen extends ConsumerWidget {
  const LiabilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final liabilities = ref.watch(activeProfileLiabilitiesProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Tooltip(
          message: 'Switch Family Profile',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => ref
                .read(hasSelectedInitialProfileProvider.notifier)
                .state = false,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child:
                  FinBalanceLogo(size: 28, showText: true, showTagline: false),
            ),
          ),
        ),
        actions: const [ProfileMenuButton(radius: 16), SizedBox(width: 8)],
      ),
      body: liabilities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Unable to load loans: $error')),
        data: (items) => ListView(
          padding: AppSpacing.screenPadding,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Loans & Borrowings',
                    style: AppTypography.headlineMedium
                        .copyWith(fontWeight: FontWeight.bold)),
                FilledButton.icon(
                  onPressed: () => AddLiabilityDialog.show(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Loan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.liability,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _SummaryCard(items: items, isDark: isDark),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Active Loans'),
            const SizedBox(height: AppSpacing.sm),
            if (items.isEmpty)
              const FinCard(
                child: Column(
                  children: [
                    Icon(Icons.account_balance_rounded,
                        size: 42, color: AppColors.liability),
                    SizedBox(height: AppSpacing.sm),
                    Text('No loans added yet'),
                    SizedBox(height: 4),
                    Text('Add a loan to include it in your net worth.'),
                  ],
                ),
              )
            else
              ...items.map((item) => _LoanCard(item: item)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<FinancialItem> items;
  final bool isDark;

  const _SummaryCard({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total =
        items.fold<int>(0, (sum, item) => sum + item.currentValuationPaise);
    return FinCard(
      backgroundColor:
          isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.liability.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.account_balance_rounded,
                color: AppColors.liability),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total outstanding',
                  style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary)),
              const SizedBox(height: 2),
              Text(CurrencyFormatter.formatPaise(total),
                  style: AppTypography.titleLarge
                      .copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoanCard extends ConsumerWidget {
  final FinancialItem item;

  const _LoanCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lender = item.lenderName;
    final transactionsAsync = ref.watch(transactionsByItemProvider(
        (profileId: item.profileId, itemId: item.id)));
    final tenure = [
      if ((item.tenureYears ?? 0) > 0) '${item.tenureYears} yrs',
      if ((item.tenureMonths ?? 0) > 0) '${item.tenureMonths} mths',
      if ((item.tenureDays ?? 0) > 0) '${item.tenureDays} days',
    ].join(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FinCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: AppColors.liability),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(item.name,
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.bold)),
                ),
                Text(CurrencyFormatter.formatPaise(item.currentValuationPaise),
                    style: AppTypography.titleMedium.copyWith(
                        color: AppColors.liability,
                        fontWeight: FontWeight.bold)),
                PopupMenuButton<String>(
                  tooltip: 'Loan actions',
                  onSelected: (action) => _handleAction(context, ref, action),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit loan')),
                    PopupMenuItem(
                        value: 'repay', child: Text('Record repayment')),
                    PopupMenuItem(value: 'close', child: Text('Close loan')),
                    PopupMenuItem(value: 'delete', child: Text('Delete loan')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                Text(categoryLabel(item.subType)),
                if (lender != null && lender.isNotEmpty) Text(lender),
                if (item.interestRateBasisPoints != null)
                  Text(
                      '${(item.interestRateBasisPoints! / 100).toStringAsFixed(2)}% ${item.interestRateType ?? ''}'),
                if (item.emiPaise != null)
                  Text('EMI ${CurrencyFormatter.formatPaise(item.emiPaise!)}'),
                if (tenure.isNotEmpty) Text(tenure),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            transactionsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) =>
                  Text('Unable to load payment history: $error'),
              data: (transactions) =>
                  _PaymentHistory(transactions: transactions),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action) async {
    final db = ref.read(databaseProvider);
    if (action == 'edit') {
      await AddLiabilityDialog.show(context, liability: item);
    } else if (action == 'repay') {
      await _showRepaymentDialog(context, ref);
    } else if (action == 'close') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Close loan?'),
          content:
              Text('Close "${item.name}" and remove it from active balances?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Close loan')),
          ],
        ),
      );
      if (confirmed == true) {
        await db.financialItemsDao.updateItem(
          item.copyWith(status: 'closed', updatedAt: DateTime.now().toUtc()),
        );
      }
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete loan?'),
          content: const Text(
              'This permanently deletes the loan. Its payment history is kept as unlinked transactions.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete')),
          ],
        ),
      );
      if (confirmed == true) {
        await db.financialItemsDao.deleteItem(item.id);
      }
    }
  }

  Future<void> _showRepaymentDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record payment for ${item.name}'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
              validator: (value) => double.tryParse(value ?? '') == null
                  ? 'Enter a valid amount'
                  : null,
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, double.parse(controller.text.trim()));
              }
            },
            child: const Text('Save payment'),
          ),
        ],
      ),
    );
    final notes = notesController.text;
    controller.dispose();
    notesController.dispose();
    if (amount == null || !context.mounted) return;
    try {
      await ref.read(transactionsDaoProvider).recordDebtRepayment(
            profileId: item.profileId,
            financialItemId: item.id,
            categoryId: item.categoryId,
            transactionDate: DateTime.now(),
            amountPaise: FinancialPrecision.rupeesToPaise(amount),
            notes: notes,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Payment failed: $error')));
      }
    }
  }
}

class _PaymentHistory extends StatelessWidget {
  final List<Transaction> transactions;

  const _PaymentHistory({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final payments = transactions
        .where((transaction) => transaction.transactionType == 'debt_repayment')
        .toList();
    if (payments.isEmpty) {
      return const Text('No repayments recorded yet.');
    }
    final monthly = <String, int>{};
    for (final payment in payments) {
      final key =
          '${payment.transactionDate.year}-${payment.transactionDate.month.toString().padLeft(2, '0')}';
      monthly[key] = (monthly[key] ?? 0) + payment.amountPaise;
    }
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('Payment history (${payments.length})'),
      subtitle: Text(
          'This month: ${CurrencyFormatter.formatPaise(_currentMonthTotal(payments))}'),
      children: monthly.entries
          .map((entry) => ListTile(
                dense: true,
                title: Text(entry.key),
                trailing: Text(CurrencyFormatter.formatPaise(entry.value)),
              ))
          .toList(),
    );
  }

  int _currentMonthTotal(List<Transaction> payments) {
    final now = DateTime.now();
    return payments
        .where((payment) =>
            payment.transactionDate.year == now.year &&
            payment.transactionDate.month == now.month)
        .fold(0, (sum, payment) => sum + payment.amountPaise);
  }
}
