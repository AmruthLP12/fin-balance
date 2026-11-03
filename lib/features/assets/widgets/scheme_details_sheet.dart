import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/nav_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/nav/models/nav_models.dart';
import '../../../database/precision/financial_precision.dart';
import 'add_to_profile_dialog.dart';

/// Bottom sheet displaying mutual fund scheme details, latest NAV, and historical data.
class SchemeDetailsSheet extends ConsumerStatefulWidget {
  final int schemeCode;

  const SchemeDetailsSheet({super.key, required this.schemeCode});

  @override
  ConsumerState<SchemeDetailsSheet> createState() => _SchemeDetailsSheetState();
}

class _SchemeDetailsSheetState extends ConsumerState<SchemeDetailsSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final detailsAsync = ref.watch(schemeDetailsProvider(widget.schemeCode));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: detailsAsync.when(
                  data: (details) {
                    if (details == null) {
                      return _buildErrorState(
                        'Scheme details could not be loaded from online providers. Please check your internet connection.',
                      );
                    }
                    return _buildDetailsContent(
                      context,
                      ref,
                      details,
                      scrollController,
                      isDark,
                    );
                  },
                  loading: () => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: AppSpacing.md),
                        Text('Fetching latest scheme & NAV details...'),
                      ],
                    ),
                  ),
                  error: (err, _) => _buildErrorState(
                    'Failed to load scheme: $err',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.liability,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Scheme Could Not Be Loaded',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              onPressed: () =>
                  ref.refresh(schemeDetailsProvider(widget.schemeCode)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsContent(
    BuildContext context,
    WidgetRef ref,
    MutualFundSchemeDetail details,
    ScrollController scrollController,
    bool isDark,
  ) {
    return ListView(
      controller: scrollController,
      padding: AppSpacing.screenPadding,
      children: [
        // Title & Badges
        Text(
          details.schemeName,
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        if (details.fundHouse != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            details.fundHouse!,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            StatusBadge(
              label: details.planType,
              type: details.planType == 'Direct'
                  ? BadgeType.brand
                  : BadgeType.neutral,
            ),
            StatusBadge(
              label: details.optionType,
              type: details.optionType == 'Growth'
                  ? BadgeType.asset
                  : BadgeType.scheduled,
            ),
            if (details.schemeCategory != null)
              StatusBadge(
                label: details.schemeCategory!,
                type: BadgeType.neutral,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Latest NAV Hero Card
        FinCard(
          backgroundColor: isDark
              ? AppColors.darkSurfaceElevated
              : AppColors.lightSurfaceElevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LATEST NET ASSET VALUE',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _buildFavoriteButton(details),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (details.latestNav != null) ...[
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  children: [
                    Text(
                      '₹${FinancialPrecision.microPaiseToNav(details.latestNav!.navMicroPaise).toStringAsFixed(4)}',
                      style: AppTypography.heroAmount.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'as of ${DateFormatter.formatDate(details.latestNav!.date)}',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  'NAV not published yet',
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Scheme Metadata Grid
        FinCard(
          child: Column(
            children: [
              _buildMetaRow(
                  'AMFI Scheme Code', details.schemeCode.toString(), isDark),
              if (details.isin != null) ...[
                const Divider(height: AppSpacing.sm),
                _buildMetaRow('ISIN', details.isin!, isDark),
              ],
              if (details.schemeType != null) ...[
                const Divider(height: AppSpacing.sm),
                _buildMetaRow('Scheme Type', details.schemeType!, isDark),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Action Button: Add to Portfolio
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.add_chart_rounded),
            label: const Text('Add to Portfolio Assets'),
            onPressed: () => AddToProfileDialog.show(context, scheme: details),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Historical NAV records preview
        if (details.navHistory.isNotEmpty) ...[
          Text(
            'Historical NAV Datapoints',
            style:
                AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          FinCard(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: details.navHistory.take(15).length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = details.navHistory[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormatter.formatDate(record.date),
                        style: AppTypography.bodyMedium,
                      ),
                      Text(
                        '₹${FinancialPrecision.microPaiseToNav(record.navMicroPaise).toStringAsFixed(4)}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildFavoriteButton(MutualFundSchemeDetail details) {
    final isFavAsync = ref.watch(isSchemeFavoriteProvider(details.schemeCode));
    final isFav = isFavAsync.value ?? false;

    return IconButton(
      icon: Icon(
        isFav ? Icons.star_rounded : Icons.star_border_rounded,
        color: isFav ? AppColors.scheduled : null,
        size: 22,
      ),
      tooltip: isFav ? 'Remove Favorite' : 'Add to Favorites',
      onPressed: () async {
        final profileId = ref.read(activeProfileIdProvider);
        final dao = ref.read(mutualFundDaoProvider);
        final nowFav = await dao.toggleFavorite(
          profileId: profileId,
          schemeCode: details.schemeCode,
          schemeName: details.schemeName,
          fundHouse: details.fundHouse,
          planType: details.planType,
          optionType: details.optionType,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  nowFav ? 'Added to favourites!' : 'Removed from favourites.'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }

  Widget _buildMetaRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
