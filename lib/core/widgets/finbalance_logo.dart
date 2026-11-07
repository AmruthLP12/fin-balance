import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'waving_flag.dart';

/// Dedicated FinBalance vector branding logo widget.
/// Represents:
///   - Assets (+) in Emerald Green
///   - Liabilities (-) in Cobalt Blue
///   - Net Worth Balance in Golden Amber
/// Supports scalable sizes, light/dark themes, and optional tagline.
class FinBalanceLogo extends StatelessWidget {
  /// Size of the logo symbol mark.
  final double size;

  /// Whether to display the text label ("FinBalance").
  final bool showText;

  /// Whether to display the tagline ("Assets • Liabilities • Balance").
  final bool showTagline;

  /// Layout axis between icon mark and typography.
  final Axis axis;

  /// Optional custom text color. If null, adapts to active Theme brightness.
  final Color? textColor;

  const FinBalanceLogo({
    super.key,
    this.size = 40.0,
    this.showText = true,
    this.showTagline = false,
    this.axis = Axis.horizontal,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = textColor ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FinBalanceMarkPainter(),
      ),
    );

    if (!showText) {
      return mark;
    }

    final textColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: axis == Axis.horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IndianFlag(width: (size * 0.7).clamp(18.0, 40.0)),
            SizedBox(width: size * 0.16),
            Text(
              'Fin',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: size * 0.52,
                color: primaryTextColor,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Balance',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: size * 0.52,
                color: AppColors.brandPrimaryLight,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(width: size * 0.2),
            WavingFlag(width: (size * 0.7).clamp(18.0, 40.0)),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 2),
          Text(
            'Assets • Liabilities • Balance',
            style: AppTypography.labelSmall.copyWith(
              color: secondaryTextColor,
              fontSize: (size * 0.22).clamp(10.0, 14.0),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );

    if (axis == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          mark,
          SizedBox(width: size * 0.3),
          Flexible(child: textColumn),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          mark,
          const SizedBox(height: AppSpacing.sm),
          textColumn,
        ],
      );
    }
  }
}

/// Custom painter for the FinBalance equilibrium geometric mark.
class _FinBalanceMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;
    final r = size.width / 2.0;

    // Background circle or rounded tile
    final bgPaint = Paint()
      ..color = const Color(0xFF0B1324)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.width * 0.04).clamp(1.0, 3.0);

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(cx, cy), width: size.width, height: size.height),
      Radius.circular(size.width * 0.26),
    );
    canvas.drawRRect(cardRect, bgPaint);
    canvas.drawRRect(cardRect, borderPaint);

    final geoR = r * 0.72;

    // 1. Assets Wing (+) - Emerald #10B981 & #059669
    final assetPaint1 = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    final assetPaint2 = Paint()
      ..color = const Color(0xFF059669)
      ..style = PaintingStyle.fill;

    final assetPath1 = Path()
      ..moveTo(cx - geoR * 0.72, cy)
      ..lineTo(cx - geoR * 0.18, cy - geoR * 0.72)
      ..lineTo(cx, cy - geoR * 0.50)
      ..lineTo(cx - geoR * 0.38, cy - geoR * 0.04)
      ..close();
    canvas.drawPath(assetPath1, assetPaint1);

    final assetPath2 = Path()
      ..moveTo(cx, cy - geoR * 0.50)
      ..lineTo(cx + geoR * 0.28, cy - geoR * 0.72)
      ..lineTo(cx + geoR * 0.44, cy - geoR * 0.52)
      ..lineTo(cx + geoR * 0.16, cy - geoR * 0.30)
      ..close();
    canvas.drawPath(assetPath2, assetPaint2);

    // 2. Liabilities Wing (-) - Cobalt #3B82F6 & #2563EB
    final liabPaint1 = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    final liabPaint2 = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.fill;

    final liabPath1 = Path()
      ..moveTo(cx + geoR * 0.72, cy)
      ..lineTo(cx + geoR * 0.18, cy + geoR * 0.72)
      ..lineTo(cx, cy + geoR * 0.50)
      ..lineTo(cx + geoR * 0.38, cy + geoR * 0.04)
      ..close();
    canvas.drawPath(liabPath1, liabPaint1);

    final liabPath2 = Path()
      ..moveTo(cx, cy + geoR * 0.50)
      ..lineTo(cx - geoR * 0.28, cy + geoR * 0.72)
      ..lineTo(cx - geoR * 0.44, cy + geoR * 0.52)
      ..lineTo(cx - geoR * 0.16, cy + geoR * 0.30)
      ..close();
    canvas.drawPath(liabPath2, liabPaint2);

    // 3. Central Balance Fulcrum - Amber Gold #F59E0B
    final goldPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    final goldGlowPaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..style = PaintingStyle.fill;

    final dSize = geoR * 0.26;
    final diamond = Path()
      ..moveTo(cx, cy - dSize)
      ..lineTo(cx + dSize, cy)
      ..lineTo(cx, cy + dSize)
      ..lineTo(cx - dSize, cy)
      ..close();
    canvas.drawPath(diamond, goldPaint);

    final dInner = geoR * 0.13;
    final diamondInner = Path()
      ..moveTo(cx, cy - dInner)
      ..lineTo(cx + dInner, cy)
      ..lineTo(cx, cy + dInner)
      ..lineTo(cx - dInner, cy)
      ..close();
    canvas.drawPath(diamondInner, goldGlowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
