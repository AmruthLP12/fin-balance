# Changelog

All notable changes to the FinBalance application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-30

### Added
- **Project Scaffolding:** Initialized Flutter Android project for **FinBalance** (`com.finbalance.app`).
- **Unified Personal Finance Model:** Established overarching identity for Assets, Liabilities, Cash Flow, and Net Worth.
- **Strict Architecture Constraints:** Zero backend, 100% offline-first local SQLite persistence.
- **Design System & Tokens:**
  - `AppColors`: Deep obsidian dark theme surfaces, crisp light theme, emerald green (assets/gains), coral rose (liabilities/debt), warm amber (commitments).
  - `AppTypography`: High-clarity tabular figures for financial amounts.
  - `AppSpacing`: Centralized spacing scale, corner radii, and minimum 48px touch targets.
  - `AppTheme`: Polished Material 3 light and dark theme configurations.
- **Reusable Financial Components:**
  - `FinCard`: Consistent surface container with subtle border.
  - `StatCard`: Key metric cards with change indicators and semantic coloring.
  - `StatusBadge`: Clean status pill (Asset, Liability, Scheduled, Neutral, Brand).
  - `SectionHeader`: Standardized headers with optional action triggers.
  - `EmptyStateView`: Polished empty states explaining offline capabilities.
- **Navigation & Core Screens:**
  - 5-tab `MainScaffold` with Material 3 `NavigationBar`.
  - `OverviewScreen`: Total Net Worth hero card, Asset vs Liability breakdown, Monthly Commitments (SIPs + EMIs), Recent Activity.
  - `AssetsScreen`: Portfolio summary, asset-class filter chips (Mutual Funds, SIPs, Stocks, FDs, Gold), scheme search action.
  - `LiabilitiesScreen`: Outstanding debt card, active EMI commitments, loan category filters (Home, Vehicle, Education, Credit Cards).
  - `AnalyticsScreen`: Net Worth composition ratio, Debt-to-Asset ratio, portfolio XIRR, financial health indicators.
  - `SettingsScreen`: Theme mode selector (System/Dark/Light), currency picker (INR/USD/EUR), sync settings, backup/restore, privacy notice.
- **Formatting Utilities:**
  - `CurrencyFormatter`: Indian Rupee (₹) formatting with decimal control, whole numbers, compact notation (Lakhs/Crores), signed variants, and percentages.
- **State Management:**
  - Configured Riverpod (`flutter_riverpod: ^2.6.1`) with `themeModeProvider`.
- **Developer Workflow:**
  - `Makefile` with targets: `help`, `get`, `analyze`, `format`, `test`, `run`, `build-debug`, `build-release`, `clean`.
  - Configured automatic `/snap/bin/flutter` fallback detection.
  - Strict static analysis rules in `analysis_options.yaml`.
- **Testing:**
  - Unit tests for `CurrencyFormatter` and `AppTheme`.
  - Widget smoke test verifying app launch and navigation across all 5 destinations.

### Documentation
- Updated `README.md` with FinBalance product specifications, architecture, and commands.
- Established `docs/` repository specifications (`docs/prod.md`, `docs/architecture.md`, `docs/essential-architecture.md`, `docs/agent.md`).

