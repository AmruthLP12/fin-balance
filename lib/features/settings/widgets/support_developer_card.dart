import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/open_link.dart';

const _kofiUrl = 'https://ko-fi.com/codewithamruth';
const _paypalUrl = 'https://paypal.me/amruthlp';
const _upiId = '9739337301@jupiteraxis';
const _upiUri = 'upi://pay?pa=$_upiId&pn=Amruth&cu=INR';

/// Optional, voluntary support links. Nothing here unlocks features; the QR is generated on-device.
class SupportDeveloperCard extends StatelessWidget {
  const SupportDeveloperCard({super.key});

  void _showUpi(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: QrImageView(data: _upiUri, size: 200),
            ),
            const SizedBox(height: AppSpacing.md),
            const SelectableText(_upiId, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy UPI ID'),
                    onPressed: () async {
                      await Clipboard.setData(
                          const ClipboardData(text: _upiId));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('UPI ID copied')));
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open UPI app'),
                    onPressed: () => openLink(ctx, _upiUri),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FinCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'FinBalance is free, with no ads and no paid features. We will try to keep it that way for as long as community support allows. If it helps you, you can chip in. It is completely optional.',
              style: AppTypography.bodySmall.copyWith(
                height: 1.4,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.local_cafe_outlined),
            title: const Text('Ko-fi', style: AppTypography.titleMedium),
            subtitle: const Text('ko-fi.com/codewithamruth',
                style: AppTypography.bodySmall),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => openLink(context, _kofiUrl),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('PayPal', style: AppTypography.titleMedium),
            subtitle: const Text('paypal.me/amruthlp',
                style: AppTypography.bodySmall),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => openLink(context, _paypalUrl),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.qr_code_2_rounded),
            title: const Text('UPI', style: AppTypography.titleMedium),
            subtitle: const Text(_upiId, style: AppTypography.bodySmall),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showUpi(context),
          ),
        ],
      ),
    );
  }
}
