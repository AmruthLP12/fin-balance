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
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';
import '../../profile/widgets/profile_menu_button.dart';
import '../loan_calculator.dart';
import '../widgets/add_liability_dialog.dart';
import 'loan_details_screen.dart';

class LiabilitiesScreen extends ConsumerStatefulWidget {
  const LiabilitiesScreen({super.key});

  @override
  ConsumerState<LiabilitiesScreen> createState() => _LiabilitiesScreenState();
}

class _LiabilitiesScreenState extends ConsumerState<LiabilitiesScreen> {
  String _filter = 'ongoing';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final liabilities = ref.watch(activeProfileAllLiabilitiesProvider);

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
        data: (all) {
          final ongoing = all.where(LoanCalculator.isOngoing).toList();
          final closed = all.where(LoanCalculator.isClosed).toList();
          final shown = switch (_filter) {
            'closed' => closed,
            'all' => all,
            _ => ongoing,
          };
          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('Loans & Borrowings',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headlineMedium
                            .copyWith(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
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
              _SummaryCard(ongoing: ongoing, isDark: isDark),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final (value, label, count) in [
                    ('ongoing', 'Ongoing', ongoing.length),
                    ('closed', 'Closed', closed.length),
                    ('all', 'All', all.length),
                  ])
                    ChoiceChip(
                      label: Text('$label ($count)'),
                      selected: _filter == value,
                      onSelected: (_) => setState(() => _filter = value),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (shown.isEmpty)
                FinCard(
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_rounded,
                          size: 42, color: AppColors.liability),
                      const SizedBox(height: AppSpacing.sm),
                      Text(switch (_filter) {
                        'closed' => 'No closed loans',
                        'all' => 'No loans added yet',
                        _ => 'No ongoing loans',
                      }),
                      const SizedBox(height: 4),
                      const Text(
                          'Only loans that still have an amount to pay count towards your net worth.',
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              else
                ...shown.map((item) => _LoanCard(item: item)),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<FinancialItem> ongoing;
  final bool isDark;

  const _SummaryCard({required this.ongoing, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total =
        ongoing.fold<int>(0, (sum, item) => sum + item.currentValuationPaise);
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total remaining',
                    style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary)),
                const SizedBox(height: 2),
                Text(CurrencyFormatter.formatPaiseCompact(total),
                    style: AppTypography.titleLarge
                        .copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text('${ongoing.length} ongoing', style: AppTypography.labelSmall),
        ],
      ),
    );
  }
}

/// Minimal loan row (like the SIP card): the main facts only. Tap for details.
class _LoanCard extends StatelessWidget {
  final FinancialItem item;

  const _LoanCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final lender = item.lenderName;
    final closed = LoanCalculator.isClosed(item);
    final months = LoanCalculator.remainingMonths(item);
    final line = <String>[
      if (!closed && item.emiPaise != null)
        'EMI ${CurrencyFormatter.formatPaiseCompact(item.emiPaise!)}',
      if (!closed && LoanCalculator.termEnded(item))
        'Term ended'
      else if (!closed && months > 0)
        '$months months left',
      if (closed) 'Fully repaid / closed',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FinCard(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => LoanDetailsScreen(item: item))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                      [
                        categoryLabel(item.subType),
                        if (lender != null && lender.isNotEmpty) lender,
                      ].join(' · '),
                      style: AppTypography.labelSmall.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (line.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(line,
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!closed)
                  Text(
                      CurrencyFormatter.formatPaiseCompact(
                          item.currentValuationPaise),
                      style: AppTypography.titleMedium.copyWith(
                          color: AppColors.liability,
                          fontWeight: FontWeight.bold)),
                if (!closed)
                  Text('remaining',
                      style: AppTypography.labelSmall.copyWith(color: muted)),
                const SizedBox(height: 4),
                StatusBadge(
                    label: LoanCalculator.status(item).toUpperCase(),
                    type: loanBadgeType(item)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
