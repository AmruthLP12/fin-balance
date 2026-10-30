import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/nav_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../profile/screens/profile_management_screen.dart';

/// Settings screen for managing application preferences, backup, and sync.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  ThemeMode _selectedTheme = ThemeMode.system;
  String _selectedCurrency = AppConstants.defaultCurrencyCode;
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
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
                    _themeModeTitle(_selectedTheme),
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
                const ListTile(
                  leading: Icon(Icons.sync_rounded),
                  title: Text(
                    'NAV Freshness Threshold',
                    style: AppTypography.titleMedium,
                  ),
                  subtitle: Text(
                    'Refresh after 24 hours',
                    style: AppTypography.bodyMedium,
                  ),
                  trailing: StatusBadge(
                    label: '24 Hours',
                    type: BadgeType.neutral,
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: const Text('Manual NAV Sync',
                      style: AppTypography.titleMedium),
                  subtitle: const Text(
                      'Fetch latest published values from MFapi',
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

          // About Section
          const SectionHeader(title: 'About'),
          FinCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${AppConstants.appTagline}\nArchitected for privacy, SQLite persistence, and comprehensive personal balance sheets.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
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
                trailing: _selectedTheme == ThemeMode.system
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  setState(() => _selectedTheme = ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.light_mode_outlined),
                title: const Text('Light Theme'),
                trailing: _selectedTheme == ThemeMode.light
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  setState(() => _selectedTheme = ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Theme'),
                trailing: _selectedTheme == ThemeMode.dark
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  setState(() => _selectedTheme = ThemeMode.dark);
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

  Future<void> _runManualNavSync() async {
    setState(() => _isSyncing = true);
    try {
      final syncService = ref.read(navSyncServiceProvider);
      final summary = await syncService.syncAllPortfolioSchemes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(summary.totalSchemes > 0
                ? 'NAV sync complete: Updated ${summary.successCount} of ${summary.totalSchemes} schemes (${summary.primaryProvider ?? "MFapi"}).'
                : 'No tracked schemes to sync in portfolio.'),
            backgroundColor:
                summary.failedCount == 0 ? AppColors.asset : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NAV sync failed: $e'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }
}
