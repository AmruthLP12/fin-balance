import 'package:flutter/material.dart';
import '../../../core/widgets/open_link.dart';
import '../widgets/support_developer_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/nav_providers.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/finbalance_logo.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/nav/models/nav_models.dart';
import '../../profile/screens/profile_management_screen.dart';
import '../../profile/widgets/profile_menu_button.dart';
import 'privacy_policy_screen.dart';

/// Settings screen for managing application preferences, backup, and sync.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedCurrency = AppConstants.defaultCurrencyCode;
  bool _isSyncing = false;
  PortfolioSyncSummary? _lastSyncSummary;
  String? _lastSyncError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: Tooltip(
          message: 'Switch Family Profile',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              ref.read(hasSelectedInitialProfileProvider.notifier).state =
                  false;
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child:
                  FinBalanceLogo(size: 28, showText: true, showTagline: false),
            ),
          ),
        ),
        actions: const [
          ProfileMenuButton(radius: 16),
          SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Privacy Banner
          FinCard(
            backgroundColor: isDark
                ? AppColors.brandPrimary.withValues(alpha: 0.1)
                : AppColors.brandPrimary.withValues(alpha: 0.05),
            borderColor: AppColors.brandPrimary.withValues(alpha: 0.3),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.brandPrimaryLight,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Local & Private',
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'All investments, liabilities, and balances stay securely on your device. No cloud storage, no account logins.',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Family Profiles
          const SectionHeader(title: 'Family Profiles'),
          FinCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.people_alt_outlined),
                  title: const Text('Manage Family Profiles',
                      style: AppTypography.titleMedium),
                  subtitle: const Text(
                    'Configure family members, switch profiles, set defaults',
                    style: AppTypography.bodyMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileManagementScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Preferences
          const SectionHeader(title: 'Preferences'),
          FinCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('Theme Mode',
                      style: AppTypography.titleMedium),
                  subtitle: Text(
                    _themeModeTitle(currentThemeMode),
                    style: AppTypography.bodyMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showThemePicker,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded),
                  title: const Text('Display Currency',
                      style: AppTypography.titleMedium),
                  subtitle: Text(
                    '$_selectedCurrency (₹)',
                    style: AppTypography.bodyMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showCurrencyPicker,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // NAV & Synchronization
          const SectionHeader(title: 'Data Synchronization'),
          FinCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync_rounded),
                  title: const Text(
                    'NAV Refresh Policy',
                    style: AppTypography.titleMedium,
                  ),
                  subtitle: Text(
                    ref.watch(navRefreshFrequencyProvider) == 'daily'
                        ? 'Daily (every 24 hours)'
                        : ref.watch(navRefreshFrequencyProvider) == 'weekly'
                            ? 'Weekly (every 7 days)'
                            : 'Manual only (on demand)',
                    style: AppTypography.bodyMedium,
                  ),
                  trailing: StatusBadge(
                    label: ref.watch(navRefreshFrequencyProvider).toUpperCase(),
                    type: BadgeType.neutral,
                  ),
                  onTap: _showNavFrequencyPicker,
                ),
                const Divider(),
                FutureBuilder<DateTime?>(
                  future: ref
                      .read(navSyncServiceProvider)
                      .getLastSuccessfulSyncTime(),
                  builder: (context, snapshot) {
                    final lastSync = snapshot.data;
                    final frequency = ref.watch(navRefreshFrequencyProvider);
                    final nextEligible = ref
                        .read(navSyncServiceProvider)
                        .getNextEligibleSync(lastSync, frequency);

                    final lastSyncStr = lastSync != null
                        ? DateFormatter.formatDateTime(lastSync)
                        : 'Never';
                    final nextEligibleStr = frequency == 'manual'
                        ? 'Manual only'
                        : (nextEligible != null &&
                                nextEligible.isBefore(DateTime.now().toUtc()))
                            ? 'Due now'
                            : (nextEligible != null
                                ? DateFormatter.formatDateTime(nextEligible)
                                : 'Now');

                    return ListTile(
                      leading: const Icon(Icons.schedule_rounded),
                      title: const Text('Sync Schedule Status',
                          style: AppTypography.titleMedium),
                      subtitle: Text(
                        'Last sync: $lastSyncStr\nNext eligible: $nextEligibleStr',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: const Text('Manual NAV Sync',
                      style: AppTypography.titleMedium),
                  subtitle: const Text(
                      'Fetch latest published mutual fund values',
                      style: AppTypography.bodyMedium),
                  trailing: OutlinedButton(
                    onPressed: _isSyncing ? null : _runManualNavSync,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: _isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sync Now'),
                  ),
                ),
                if (_lastSyncSummary != null) ...[
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      _lastSyncSummary!.failedCount == 0
                          ? Icons.check_circle_outline_rounded
                          : Icons.warning_amber_rounded,
                      color: _lastSyncSummary!.failedCount == 0
                          ? AppColors.asset
                          : AppColors.warning,
                    ),
                    title: Text(
                      _lastSyncSummary!.failedCount == 0
                          ? 'Last Sync: All Schemes Updated'
                          : 'Last Sync: Partial Failure',
                      style: AppTypography.titleMedium,
                    ),
                    subtitle: Text(
                      'Success: ${_lastSyncSummary!.successCount} / ${_lastSyncSummary!.totalSchemes} schemes updated.${_lastSyncSummary!.failedCount > 0 ? " Failed: ${_lastSyncSummary!.failedCount}." : ""}',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
                if (_lastSyncError != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.liability,
                    ),
                    title: const Text(
                      'Sync Error Details',
                      style: TextStyle(color: AppColors.liability),
                    ),
                    subtitle: Text(
                      _lastSyncError!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.liability,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Backup & Restore
          const SectionHeader(title: 'Backup & Restore'),
          FinCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('Export JSON Backup',
                      style: AppTypography.titleMedium),
                  subtitle: const Text('Save encrypted portable JSON file',
                      style: AppTypography.bodyMedium),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Backup export will be implemented in Milestone 8')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Import Backup',
                      style: AppTypography.titleMedium),
                  subtitle: const Text('Restore holdings from JSON file',
                      style: AppTypography.bodyMedium),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Backup restore will be implemented in Milestone 8')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Support the Developer'),
          const SupportDeveloperCard(),
          const SizedBox(height: AppSpacing.lg),

          // Support Section
          const SectionHeader(title: 'Support'),
          FinCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: const Text('Developer Portfolio',
                      style: AppTypography.titleMedium),
                  subtitle: const Text('https://amruthlp.vercel.app',
                      style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => openLink(context, 'https://amruthlp.vercel.app'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy',
                      style: AppTypography.titleMedium),
                  subtitle: const Text(
                      'Local-first privacy and zero-telemetry policy',
                      style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.contact_support_outlined),
                  title:
                      Text('Contact Details', style: AppTypography.titleMedium),
                  subtitle: Text('Contact details will be provided here.',
                      style: AppTypography.bodySmall),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // About Section
          const SectionHeader(title: 'About'),
          FinCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const FinBalanceLogo(
                      size: 36,
                      showText: true,
                      showTagline: false,
                    ),
                    Text(
                      'v${AppConstants.appVersion}',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${AppConstants.appTagline}\nArchitected for local privacy, offline reliability, and comprehensive personal balance sheets.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.code_rounded,
                      size: 20,
                      color: AppColors.brandPrimaryLight,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Built by Amruth L P',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  String _themeModeTitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follow System';
      case ThemeMode.light:
        return 'Light Theme';
      case ThemeMode.dark:
        return 'Dark Theme';
    }
  }

  void _showThemePicker() {
    final currentThemeMode = ref.read(themeModeProvider);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              const Text('Choose Theme Mode', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                leading: const Icon(Icons.brightness_auto_outlined),
                title: const Text('Follow System'),
                trailing: currentThemeMode == ThemeMode.system
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.light_mode_outlined),
                title: const Text('Light Theme'),
                trailing: currentThemeMode == ThemeMode.light
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Theme'),
                trailing: currentThemeMode == ThemeMode.dark
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              const Text('Select Currency', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                title: const Text('Indian Rupee (₹ INR)'),
                trailing:
                    _selectedCurrency == 'INR' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _selectedCurrency = 'INR');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('US Dollar (\$ USD)'),
                trailing:
                    _selectedCurrency == 'USD' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _selectedCurrency = 'USD');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Euro (€ EUR)'),
                trailing:
                    _selectedCurrency == 'EUR' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _selectedCurrency = 'EUR');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  void _showNavFrequencyPicker() {
    final current = ref.read(navRefreshFrequencyProvider);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              const Text('NAV Refresh Frequency',
                  style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                leading: const Icon(Icons.today_rounded),
                title: const Text('Daily (24 Hours)'),
                subtitle: const Text(
                    'Default for active investors tracking daily market moves'),
                trailing: current == 'daily' ? const Icon(Icons.check) : null,
                onTap: () {
                  ref
                      .read(navRefreshFrequencyProvider.notifier)
                      .setFrequency('daily');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range_rounded),
                title: const Text('Weekly (7 Days)'),
                subtitle: const Text('Conserves battery and network bandwidth'),
                trailing: current == 'weekly' ? const Icon(Icons.check) : null,
                onTap: () {
                  ref
                      .read(navRefreshFrequencyProvider.notifier)
                      .setFrequency('weekly');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.touch_app_rounded),
                title: const Text('Manual Only'),
                subtitle: const Text(
                    'Syncs only when explicitly requested via "Sync Now"'),
                trailing: current == 'manual' ? const Icon(Icons.check) : null,
                onTap: () {
                  ref
                      .read(navRefreshFrequencyProvider.notifier)
                      .setFrequency('manual');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runManualNavSync() async {
    setState(() {
      _isSyncing = true;
      _lastSyncError = null;
    });
    try {
      final syncService = ref.read(navSyncServiceProvider);
      final summary = await syncService.syncAllPortfolioSchemes();
      if (mounted) {
        setState(() => _lastSyncSummary = summary);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(summary.totalSchemes > 0
                ? 'Mutual fund NAV updated successfully: ${summary.successCount} of ${summary.totalSchemes} schemes.'
                : 'No tracked schemes to sync in portfolio.'),
            backgroundColor:
                summary.failedCount == 0 ? AppColors.asset : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _lastSyncError = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Unable to update mutual fund NAV. Please try again later.'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }
}
