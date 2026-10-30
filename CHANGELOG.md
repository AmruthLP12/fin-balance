# Changelog

All notable changes to the FinBalance application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-30

### Added
- **Project Scaffolding:** Initialized Flutter Android project for **FinBalance** (`com.finbalance.app`).
- **Comprehensive Personal Finance Architecture:**
  - Designed around three pillars: Assets (+), Liabilities (−), and Cash Flow / Activity.
  - Core equation: `Net Worth = Total Assets - Total Liabilities`.
  - Generic architecture ready to support mutual funds, SIPs, stocks, deposits, gold, loans, EMIs, and expenses.
- **Design System & Design Tokens:**
  - `AppColors`: Deep obsidian dark theme (`#090D16`), cool gray light theme (`#F8FAFC`), emerald green for assets/returns (`#10B981`), coral rose for debt/liabilities (`#F43F5E`), and warm amber for scheduled commitments (`#F59E0B`).
  - `AppTypography`: High-clarity tabular numerical figures (`FontFeature.tabularFigures()`) for accurate financial alignment.
  - `AppSpacing`: Centralized spacing scale, corner radii, and minimum 48px touch targets.
  - `AppTheme`: Polished Material 3 light and dark theme configurations.
- **Reusable Financial Components:**
  - `FinCard`: Material-based surface card providing subtle borders and ripple ink splashes.
  - `StatCard`: Financial summary card with delta indicators and semantic coloration.
  - `StatusBadge`: Clean status pill (Asset, Liability, Scheduled, Neutral, Brand).
  - `SectionHeader`: Standardized headers with optional action triggers.
  - `EmptyStateView`: Polished, context-aware empty state explaining the local-first engine.
- **Navigation & Core Screens:**
  - 5-tab `MainScaffold` with Material 3 `NavigationBar`:
    1. `OverviewScreen`: Total Net Worth hero card, Asset vs. Liability breakdown, Monthly Commitments (SIPs + EMIs), and Recent Financial Activity.
    2. `AssetsScreen`: Total Assets Value, category filter chips (All, Mutual Funds, Stocks, FDs, Gold, Retirement), and holdings empty state.
    3. `LiabilitiesScreen`: Total Outstanding Debt card, monthly EMI commitments, loan category filters (Home, Vehicle, Education, Credit Cards), and debt tracking empty state.
    4. `ActivityScreen`: Transaction timeline and cash flow ledger (simulated SIPs, loan payments, manual entries, redemptions).
    5. `SettingsScreen`: Theme mode selector (System / Dark / Light), currency picker (INR / USD / EUR), sync settings, backup/restore, privacy notice.
- **Formatting Utilities:**
  - `CurrencyFormatter`: Indian Rupee (`₹`) formatting with decimal control, whole numbers, compact notation (Lakhs/Crores), signed variants, and percentages.
- **State Management:**
  - Configured Riverpod (`flutter_riverpod: ^2.6.1`) with `themeModeProvider`.
- **Developer Workflow:**
  - `Makefile` with targets: `help`, `get`, `analyze`, `format`, `test`, `run`, `build-debug`, `build-release`, `clean`.
  - Strict static analysis rules in `analysis_options.yaml`.
- **Testing:**
  - Unit tests for `CurrencyFormatter` and `AppTheme`.
  - Widget smoke test verifying app launch and navigation across all 5 destinations: Overview, Assets, Liabilities, Activity, and Settings.
- **Build Verification:**
  - Built universal debug APK at `build/app/outputs/flutter-apk/app-debug.apk`.
