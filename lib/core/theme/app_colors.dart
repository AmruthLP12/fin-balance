import 'package:flutter/material.dart';

/// Centralized color palette for FinBalance.
///
/// Designed specifically for personal finance and net worth tracking:
/// - Pure, focused slate backgrounds for high contrast and financial readability.
/// - Vibrant emerald green for Assets, gains, and positive cash flow.
/// - Refined rose coral for Liabilities, debts, and outflows.
/// - Warm amber for pending, scheduled, and simulated actions.
/// - Electric indigo for primary brand accents and interactive states.
class AppColors {
  AppColors._();

  // Core Brand Tokens
  static const Color brandPrimary = Color(0xFF2563EB); // Royal Blue
  static const Color brandPrimaryLight = Color(0xFF60A5FA);
  static const Color brandAccent = Color(0xFF06B6D4); // Cyan Accent

  // Financial Semantics
  static const Color asset = Color(0xFF10B981); // Emerald Green (Assets, Gains)
  static const Color assetLight = Color(0xFF34D399);
  static const Color assetBackgroundDark = Color(0xFF064E3B);
  static const Color assetBackgroundLight = Color(0xFFD1FAE5);

  static const Color liability = Color(0xFFF43F5E); // Rose/Coral (Debts, EMIs)
  static const Color liabilityLight = Color(0xFFFB7185);
  static const Color liabilityBackgroundDark = Color(0xFF4C0519);
  static const Color liabilityBackgroundLight = Color(0xFFFFE4E6);

  static const Color scheduled = Color(0xFFF59E0B); // Amber (Pending / SIP)
  static const Color scheduledBackgroundDark = Color(0xFF451A03);
  static const Color scheduledBackgroundLight = Color(0xFFFEF3C7);

  // Dark Theme Surfaces
  static const Color darkBackground = Color(0xFF090D16); // Deep Obsidian
  static const Color darkSurface = Color(0xFF111827); // Dark Slate 900
  static const Color darkSurfaceElevated = Color(0xFF1F2937); // Slate 800
  static const Color darkSurfaceHighlight = Color(0xFF374151); // Slate 700
  static const Color darkBorder = Color(0xFF1E293B); // Subtle border
  static const Color darkBorderStrong = Color(0xFF334155);

  // Dark Theme Typography
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Theme Surfaces
  static const Color lightBackground = Color(0xFFF8FAFC); // Cool Gray 50
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9); // Gray 100
  static const Color lightSurfaceHighlight = Color(0xFFE2E8F0); // Gray 200
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderStrong = Color(0xFFCBD5E1);

  // Light Theme Typography
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightTextMuted = Color(0xFF94A3B8); // Slate 400
}
