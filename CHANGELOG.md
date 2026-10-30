# Changelog

All notable changes to the FinBalance application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-10-30

### Added
- **Drift SQLite Database Layer:**
  - Implemented offline-first local persistence using `drift: ^2.24.2` and `drift_flutter: ^0.2.4`.
  - Configured platform SQLite connection with foreign keys enabled (`PRAGMA foreign_keys = ON;`).
  - Implemented automatic initial seed of essential financial categories across 4 classifications (Asset, Liability, Income, Expense).
- **Normalized Schema Architecture (7 Tables):**
  - `FinancialCategories`: Hierarchical category classification for assets, liabilities, income, and expenses.
  - `FinancialAccounts`: Bank accounts, cash reserves, Demat portfolios, and loan accounts.
  - `FinancialItems`: Unified storage for assets (mutual funds, stocks, FDs, gold) and liabilities (home loans, vehicle loans, credit cards).
  - `Transactions`: Immutable double-entry ledger tracking purchases, redemptions, loan payments, transfers, and cash flows.
  - `ValuationHistory`: Daily NAV and asset valuation time-series with composite unique constraint `(financial_item_id, valuation_date)`.
  - `RecurringTransactions`: Execution schedules for simulated SIP investments and loan EMI payments.
  - `AppSettings`: Typed key-value configuration store for application settings and synchronization states.
- **Data Access Objects (7 DAOs):**
  - `CategoriesDao`, `AccountsDao`, `FinancialItemsDao`, `TransactionsDao`, `ValuationsDao`, `RecurringTransactionsDao`, `AppSettingsDao`.
  - Reactive `Stream` watchers for UI consumption and atomic `Future` mutations.
  - Atomic upsert support for `ValuationHistory` using Drift `DoUpdate` targeting composite keys.
- **Financial Precision Engine:**
  - `FinancialPrecision` utility module preventing floating-point representation drift.
  - Currency stored as 64-bit integer Paise ($₹1 = 100\text{ paise}$).
  - Mutual fund / stock units stored as 64-bit integer micro-units ($1\text{ unit} = 1,000,000\text{ micro-units}$).
  - NAV stored as 64-bit integer micro-paise ($₹1 = 1,000,000\text{ micro-paise}$) for 4-decimal-place AMFI precision.
  - Interest rates stored in basis points ($1\% = 100\text{ bps}$).
- **Riverpod Database Providers:**
  - Registered `databaseProvider` and individual DAO providers (`categoriesDaoProvider`, `financialItemsDaoProvider`, etc.).
- **Automated In-Memory Test Suite:**
  - Added unit test suite `test/unit/financial_precision_test.dart` for mathematical precision and edge-case conversions.
  - Added comprehensive database integration tests `test/database/app_database_test.dart` running against in-memory SQLite (`NativeDatabase.memory()`).
  - Verified default category seeding, asset/liability classification queries, foreign key cascading, transactions ledger, schedule updates, and valuation uniqueness constraints.

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
