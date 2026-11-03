import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';

/// In-app Privacy Policy screen explaining FinBalance's local-first architecture
/// and zero-telemetry privacy principles.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Header summary card
          FinCard(
            backgroundColor: isDark
                ? AppColors.brandPrimary.withValues(alpha: 0.12)
                : AppColors.brandPrimary.withValues(alpha: 0.06),
            borderColor: AppColors.brandPrimary.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.brandPrimaryLight,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Privacy by Design',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'FinBalance is engineered with a strict local-first architecture. Your personal financial records, profile configurations, and transaction history are stored entirely on your local device.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.asset.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Effective: November 2026 • v1.1.0',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.asset,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 14 Sections
          _buildPolicySection(
            number: '1',
            title: 'Introduction & Overview',
            content:
                'FinBalance is a multi-profile personal finance management application that helps individuals and families track assets, liabilities, mutual funds, systematic investment plans (SIPs), cash flow, and overall net worth.\n\nUnlike traditional cloud-based financial services that require personal registration and store sensitive financial details on external remote servers, FinBalance operates directly on your device. We believe your financial data belongs exclusively to you.',
            isDark: isDark,
          ),
          _buildPolicySection(
            number: '2',
            title: 'Information We Collect',
            content:
                'We do not collect, harvest, store, or transmit any personal financial data or identifiers.\n\n• No Personal Identifiers: We do not collect your name, phone number, email address, physical address, PAN, Aadhaar, bank account numbers, or government IDs.\n• No Financial Credentials: We do not connect to bank accounts via screen scraping, Open Banking APIs, or SMS reading.\n• No Analytics or Telemetry: FinBalance contains zero third-party analytics SDKs, user behavior tracking, session recording, or tracking pixels.\n• No Unique Device Identifiers: We do not log or track device IDs (IMEI, advertising ID, MAC address).\n\nAny financial figures, profile details, asset values, and transaction notes you enter exist solely in your device\'s local storage.',
            isDark: isDark,
          ),
          _buildPolicySection(
            number: '3',
            title: 'How We Store Your Data',
            content:
                'All data entered into FinBalance is stored in a private, sandboxed on-device local database managed directly by your operating system.\n\n• Local Storage: All profiles, financial items, holdings, investment schedules, cash flow records, and preferences reside locally within the application sandbox.\n• No Cloud Sync: FinBalance does not operate remote database servers, cloud synchronization backends, or hosted user accounts.\n• Operating System Sandboxing: Your application database is shielded by standard operating system sandboxing mechanisms (such as Android app sandboxing and browser origin boundaries), preventing unauthorized access from other applications on your device unless device security is explicitly compromised.',
            isDark: isDark,
          ),
          _buildPolicySection(
            number: '4',
            title: 'Mutual Fund Market Data & Network Usage',
            content:
                'FinBalance requires an active internet connection exclusively to fetch publicly available mutual fund market data.\n\n• Public Market Rates: The application connects to public, AMFI-compliant mutual fund market data services to download daily Net Asset Value (NAV) updates and scheme master catalogs.\n• No Personal Data Sent: When fetching market data, the application only requests public scheme identifiers (such as AMFI scheme codes). Zero personal data, portfolio amounts, transaction histories, unit balances, or profile information are ever transmitted over the network.\n• Local Offline Caching: Fetched NAV rates and historical mutual fund data are cached in your local on-device database so that your portfolio valuation remains accessible offline.',
            isDark: isDark,
          ),
          _buildPolicySection(
            number: '5',
            title: 'Financial Data Accuracy & Market Delays',
            content:
                'Financial information displayed by FinBalance is intended strictly for personal tracking and informational purposes.\n\n• Market Data Delays: Mutual fund Net Asset Values (NAVs) and other externally retrieved financial information may be delayed and might not reflect the most recent available market value.\n• Difference from Transaction Prices: Displayed values may differ from actual execution, settlement, purchase, or redemption prices provided by your fund house, broker, or depository participant.\n• Subject to Market Schedules: Market prices, NAVs, unit balances, and calculated portfolio valuations are subject to provider availability, market operating schedules, update frequency, and data feed accuracy.\n• Verification Recommended: Users should independently verify all critical financial records and valuations directly with their official financial institutions, asset management companies, or registered intermediaries before making investment or borrowing decisions.\n• No Financial Execution: FinBalance is a personal record-keeping application. It does not execute purchases, redemptions, deposits, withdrawals, transfers, or any financial transactions merely by recording or displaying them.',
            isDark: isDark,
          ),
          _buildPolicySection(
            number: '6',
            title: 'Multi-Profile & Family Privacy',
            content:
                'FinBalance supports multiple financial profiles to help users manage family members\' finances independently.\n\n• Local Profile Isolation: Each profile maintains its own isolated holdings, asset allocations, SIP schedules, and transactions within your device\'s local database.\n• Zero Inter-Profile Sharing Over Network: Profiles are not linked across devices and are never synced to any server. Switching between profiles is entirely an on-device operation.',
            isDark: isDark,
          ),
          _buildPolicySection(
            number: '7',
            title: 'Third-Party Services & Advertising',
            content:
                'FinBalance maintains a transparent approach to third-party integrations and advertising:\n\n• Current Advertising State: The application currently does not display advertisements. This statement describes the current application behaviour only and is not a promise or guarantee about whether advertising may be introduced or changed in the future.\n• Future Disclosures: If advertising or additional third-party services are introduced at a later stage, the applicable privacy disclosures will be updated accordingly. Advertisers do not receive your financial records or balance sheet information.\n• External Public Feeds: The only network requests initiated by the application are directed to public market data services over secure HTTPS/TLS connections to retrieve scheme lists and NAV figures.',
            isDark: isDark,
          ),
          _buildPolicySection(
            number: '8',
            title: 'Security',
            content:
                'We take the security of your financial records seriously:\n\n• Transport Security: All network requests for public mutual fund NAV rates use encrypted HTTPS/TLS connections.\n• OS-Level Protection: Your local database relies on your device\'s operating system security sandbox.\n• User Responsibility: Because data is stored locally without external password gates, your device security is paramount. We strongly recommend protecting your device with a strong passcode, biometric authentication (fingerprint/face recognition), full-disk encryption, and keeping your operating system up to date.',
            isDark: isDark,
          ),
          _buildPolicySection(
            number: '9',
            title: 'Data Retention & Deletion',
            content:
                'Because FinBalance stores all data locally on your device:\n\n• Full User Control: You maintain complete control over data retention.\n• Record Deletion: You can delete individual transactions, SIP schedules, mutual fund holdings, or entire profiles at any time from within the application interface.\n• Permanent Purge: Deleting a profile or tapping "Clear All Data" in Settings permanently purges the respective records from your device\'s local database.\n• App Uninstall: Uninstalling FinBalance completely removes the application and its local database from your device operating system. Because we do not maintain server backups, uninstalled data cannot be recovered by us.',
            isDark: isDark,
          ),
          _buildPolicySection(
            number: '10',
            title: 'Backup & Export',
            content:
                'FinBalance provides local data export and backup utilities to allow you to safeguard your records:\n\n• Local File Control: When you generate an export file or database backup, the file is saved directly to your local file system or shared storage destination chosen by you.\n• No Automatic Uploads: Backup files are never automatically uploaded to any remote server or third-party cloud storage service. You retain full control over where backup files are stored and how they are transferred.',
            isDark: isDark,
          ),
          _buildPolicySection(
            number: '11',
            title: 'Children\'s Privacy',
            content:
                'FinBalance is designed for general audiences and personal finance tracking. We do not knowingly target or collect any personal information from children under the age of 13. Because no personal data is collected or transmitted by the application, FinBalance complies with child privacy protections by default.',
            isDark: isDark,
          ),
          _buildPolicySection(
            number: '12',
            title: 'Changes to This Privacy Policy',
            content:
                'We may update this Privacy Policy from time to time to reflect application improvements, new features, or regulatory requirements. Any updates will be:\n1. Reflected in this document with a revised "Effective Date".\n2. Included in the application\'s in-app Privacy Policy screen.\n\nContinued use of FinBalance following policy updates signifies your acknowledgment and acceptance of the revised terms.',
            isDark: isDark,
          ),
          _buildPolicySection(
            number: '13',
            title: 'Governing Law & Compliance',
            content:
                'FinBalance is developed in accordance with the principles of data minimization, local processing, and user consent set forth in:\n• The Information Technology Act, 2000 (India) and applicable amendments.\n• The Digital Personal Data Protection Act, 2023 (DPDP Act, India).\n\nBy confining all personal financial information to on-device processing and transmitting zero user identifiers, FinBalance inherently adheres to privacy-by-design standards.',
            isDark: isDark,
          ),
          _buildPolicySection(
            number: '14',
            title: 'Effective Date & Version',
            content:
                '• Effective Date: November 2026\n• Application Version: 1.1.0\n• Hosted URL: https://amruthlp.vercel.app/finbalance_policy',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Dedicated Support Section
          FinCard(
            borderColor: AppColors.brandPrimary.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.support_agent_rounded,
                      color: AppColors.brandPrimaryLight,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Support',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'For technical support, feedback, and application inquiries:',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language_rounded, size: 20),
                  title: const Text('Developer Portfolio',
                      style: AppTypography.bodyMedium),
                  subtitle: const Text('https://amruthlp.vercel.app',
                      style: AppTypography.labelSmall),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Portfolio: https://amruthlp.vercel.app'),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.article_outlined, size: 20),
                  title: const Text('Hosted Policy Document',
                      style: AppTypography.bodyMedium),
                  subtitle: const Text(
                      'https://amruthlp.vercel.app/finbalance_policy',
                      style: AppTypography.labelSmall),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Policy: https://amruthlp.vercel.app/finbalance_policy'),
                      ),
                    );
                  },
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.contact_mail_outlined, size: 20),
                  title: Text('Contact Details',
                      style: AppTypography.bodyMedium),
                  subtitle: Text('Contact details will be provided here.',
                      style: AppTypography.labelSmall),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildPolicySection({
    required String number,
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: FinCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceHighlight
                        : AppColors.lightSurfaceHighlight,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    number,
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimaryLight,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              content,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
