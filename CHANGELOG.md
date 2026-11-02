# Changelog

All notable changes to the FinBalance application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-11-02

### Added
- **Flexible SIP Scheduling & Schedule Periods:**
  - Implemented flexible SIP model separating master plans (`SipPlans`) from schedule periods (`SipSchedulePeriods`), supporting multiple periods with varying amounts and deduction dates across an investment's lifetime.
  - Enabled step-up and step-down adjustments (`EditSipScheduleDialog`): archives the prior schedule period and activates a new period on the effective date without manual installment recreation.
  - Added `SipCard` to `AssetsScreen` with real-time schedule information, deduction day ordinal display, monthly amount in Paise, status badges, and management actions.
  - Added `SipInstallmentsSheet`: drill-down ledger displaying all generated installments, simulation flags, and one-tap actions to record or skip.
- **Bulk Historical SIP Entry:**
  - Implemented `AddSipDialog` with dedicated tab for bulk historical SIP entry across custom date ranges (From Date to To Date, monthly amount, deduction day).
  - Supported toggling between confirmed actual past investments (records `SipInstallments` + `Transactions` in ledger) and simulated projections (records `isSimulated: true` without inflating verified transactions).
- **Zero-Drift Month-End Date Clamping:**
  - Implemented `RecurringDateCalculator`: strictly clamps 31st to 28/29th Feb (leap-year aware) and 30th on 30-day months while calculating strictly from original configured day to prevent progressive date drift.
- **Configurable NAV Caching & Refresh Policy:**
  - Configurable sync frequency policies in `SettingsScreen` and `AppSettings`: `Daily` (24 hours), `Weekly` (7 days), and `Manual Only` (on demand).
  - Cache-first NAV viewing: opening scheme details displays local SQLite cache immediately and avoids repeated remote provider hits when sync is not due.
  - Added Next Eligible Sync timestamp calculation and status display in Settings (`Last sync: ... • Next eligible: ...`).
  - Added 400ms search debounce and 10-minute in-memory query caching in `NavSyncService`.
- **Profile-Selection Startup Flow & Lazy Loading:**
  - Implemented `ProfileSelectionScreen` displayed on cold boot prior to loading dashboard data.
  - Displays all family profiles, avatars, relationship badges, and a prominent "Quick Continue as [Last Profile]" card.
  - Isolated memory and queries to active profile: zero eager loading of other profiles' portfolios or transaction history.
  - Paginated transaction fetching in `TransactionsDao` (`getPaginatedTransactionsForProfile`) for bounded lazy loading.
- **Profile-Isolated Favourites:**
  - Created `ProfileFavoriteSchemes` table enforcing unique constraint on `(profileId, schemeCode)`.
  - Added profile-scoped favourite methods in `MutualFundDao` with atomic toggling and immediate visual feedback via reactive Drift streams.

### Fixed
- **Duplicate Resource Merger Collision:**
  - Resolved Android debug APK build failure caused by duplicate `ic_launcher` in `res/mipmap-hdpi/`.
- **Foreign Key & Conflict Resolution in SipsDao:**
  - Added targeted conflict resolution `onConflict: DoNothing(target: [sipPlanId, scheduledDate])` guaranteeing zero duplicate installments during schedule generation or overlapping periods.

### Testing
- Added `test/unit/sip_scheduling_test.dart` (9 tests covering leap-year clamping, drift prevention, multiple periods, bulk historical generation, simulated vs actual flags, duplicate prevention, and skipping).
- Added `test/unit/favourites_test.dart` (4 tests covering toggle persistence, cross-profile isolation, unique key duplicate prevention, and reactive stream emission).
- Added `test/unit/caching_policy_test.dart` (4 tests covering search query caching, daily/weekly/manual policies, eligible sync calculation, and cache-first network avoidance).
- Added `test/widget/profile_selection_startup_test.dart` (validating cold boot profile picker and transition to main scaffold).
- Total automated test suite expanded to **90 passing tests** (0 failures).

## [0.3.2] - 2026-10-30

### Fixed
- **Mutual Fund Scheme Details Loading:**
  - Resolved loading failure when tapping mutual fund schemes by eliminating silent failure suppression in `MFapiProvider` and `NavSyncService`.
  - Added fallback from `/mf/{schemeCode}` (full history) to `/mf/{schemeCode}/latest` when history requests time out or fail.
  - Implemented offline-first cache fallback in `NavSyncService.getOrFetchSchemeDetails`: returns locally cached scheme metadata even if remote providers are unreachable or offline.
  - Excluded forbidden `User-Agent` HTTP header when executing on Flutter Web (`!kIsWeb`), resolving browser CORS/XHR preflight rejections.
  - Enhanced `SchemeDetailsSheet` with explicit loading, retry, and meaningful offline error states with one-tap retry.
- **Manual NAV Synchronization:**
  - Replaced placeholder SnackBar in `SettingsScreen` with live manual NAV synchronization.
  - Implemented single-scheme synchronization (`syncSchemeNav`) with direct sync button on `SchemeDetailsSheet` and `HoldingDetailsSheet`.
  - Implemented full portfolio synchronization (`syncAllPortfolioSchemes`) updating all held and bookmarked mutual funds across all financial profiles.
  - Added non-regression rule: prevents overwriting newer cached NAVs with older provider quotes.
  - Enforced SQLite duplicate prevention for identical `(schemeCode, navDate)` records in `NavHistory`.
  - Persisted `last_nav_sync_time` in `AppSettings` table and reported sync results with scheme counts and provider attribution.

### Added
- **Full Mutual Fund Holding Management:**
  - `HoldingDetailsSheet`: Tap any `HoldingCard` in `AssetsScreen` to open comprehensive investment metrics: current estimated valuation, net invested capital, absolute return (₹ and %), total units, latest NAV, transaction log, and scheme metadata.
  - `EditHoldingDialog`: Allows editing investment amount, units, purchase NAV, purchase date, and notes on existing holdings without creating duplicates.
  - Two-way interactive calculation: Editing amount calculates units (`Amount / Purchase NAV`), editing units calculates amount (`Units * Purchase NAV`).
  - Enhanced `AddToProfileDialog`: Added customizable purchase NAV, purchase date picker, and notes for historical purchase entry.
  - Manual sync button directly in `AssetsScreen` AppBar for rapid on-demand portfolio valuation refresh.

### Testing
- Added `test/unit/scheme_details_test.dart` (5 tests for parsing, missing metadata, malformed response handling, offline fallback, and endpoint fallback).
- Added `test/unit/nav_sync_test.dart` (5 tests for individual scheme sync, portfolio-wide sync, duplicate prevention, non-regression date protection, and offline reporting).
- Added `test/unit/holding_management_test.dart` (5 tests for adding with purchase NAV/date, editing without duplicates, two-way calculations, multiple purchase aggregation, and cross-profile isolation).
- Added `test/unit/portfolio_valuation_test.dart` (4 tests for current valuation, profit/loss, return %, zero-value handling, and portfolio-wide aggregation).
- Total test suite expanded to 71 passing tests.

### Added
- **Multi-Profile Management & Family Finance UI:**
  - `ProfileFormDialog`: Create and edit family members with name, relationship picker (Self, Spouse, Father, Mother, Child, Other), color avatar palette, optional description, and default profile toggle.
  - `ProfileSelectorButton`: Interactive, accessible header button in AppBar showing active profile avatar, name, and relationship badge.
  - `ProfileSwitcherSheet`: Bottom sheet displaying all available profiles with one-tap switching and persistence in local settings.
  - `ProfileManagementScreen`: Dedicated screen to view, edit, archive/restore, and change the default profile.
  - Accidental deletion protection: Enforced `hasFinancialHistory` check preventing permanent deletion of profiles with existing assets, accounts, or transactions, offering safe Archiving instead.
  - Cross-profile data isolation: Verified that switching profiles dynamically recalibrates `OverviewScreen`, `AssetsScreen`, and all dependent providers with zero stale data leakage.
- **Mutual Fund Holdings Reactive Management:**
  - `AssetsScreen` fully wired to `activeProfileAssetsProvider` with dynamic summary metrics (Total Asset Value, Invested Value, Gain/Loss, Returns %).
  - Category filter chips (`All`, `Mutual Funds`, `Stocks & ETFs`, `Fixed Deposits`, `Gold`, `Retirement`).
  - `HoldingCard`: Displays current value, invested value, gains, units, average cost, and options menu to remove or inspect holdings.
  - Enhanced `AddToProfileDialog` to check for existing holdings and aggregate additional purchases into the same scheme without duplicate records.
- **Flutter Web Support & Responsive UI:**
  - Configured `DriftWebOptions` with `sqlite3.wasm` and `drift_worker.js` for SQLite Wasm execution in browsers via OPFS and IndexedDB.
  - Responsive `MainScaffold`: Automatically adapts navigation layout using a side `NavigationRail` for desktop/tablet screens (>= 720px) and a bottom `NavigationBar` on mobile screens.
  - Updated web scaffolding (`index.html`, `manifest.json`) with official FinBalance branding.
  - Updated `Makefile` with `make build-web` and `make run-web`.
- **Testing:**
  - Added `test/database/profile_management_test.dart` (6 tests for profile creation, editing, default selection, archiving, financial history protection, and multi-profile data isolation).
  - Added `test/unit/mutual_fund_holdings_test.dart` (2 tests for profile-scoped holdings addition, cross-profile isolation, and multi-purchase holding aggregation).
  - Cleaned up widget smoke tests with proper in-memory database setup (52 total passing tests).

## [0.3.0] - 2026-10-30

### Added
- **Provider-Independent NAV Integration Layer:**
  - `NavProvider` abstract interface allowing pluggable provider switching without modifying application logic.
  - `MFapiProvider`: Primary REST adapter for `api.mfapi.in` with debounced search (`/mf/search`) and metadata/NAV retrieval (`/mf/{schemeCode}/latest`).
  - `TigzigProvider`: Secondary adapter with Cloudflare 1006 detection, graceful failure handling, and clear unavailable-provider reporting.
  - `AmfiProvider`: Tertiary fallback parser for official AMFI semicolon-delimited `NAVAll.txt` files with `DD-MMM-YYYY` date conversion.
  - `NavSyncService`: Central coordinator orchestrating multi-provider failover, local SQLite caching, and automatic portfolio valuation propagation.
- **Drift Database Schema Upgrade (Version 2):**
  - Added `MutualFundSchemes` master table: Global reference catalog storing scheme codes, fund houses, categories, plans (Direct/Regular), options (Growth/IDCW), latest NAV in micro-paise, and favourite bookmark state.
  - Added `NavHistory` table: Historical time-series with composite unique key constraint `(scheme_code, nav_date)`.
  - Added `MutualFundDao`: Local scheme search, favourites stream, historical NAV caching with deduplication, and automatic portfolio holdings recalculation.
  - Non-destructive `MigrationStrategy` safely upgrading databases from version 1 to 2.
- **Mutual Fund UI & Profile Asset Addition:**
  - `MutualFundSearchScreen`: Debounced search bar, provider status badge, tabs for "Search Schemes" and "Favourites".
  - `MutualFundCard`: Displays scheme name, AMC, Direct/Regular badge, Growth/IDCW badge, latest NAV, and star bookmark toggle.
  - `SchemeDetailsSheet`: Draggable bottom sheet with full scheme metadata, latest NAV hero card, historical NAV table, and quick actions.
  - `AddToProfileDialog`: Seamlessly links any global master scheme to an individual profile's asset portfolio with unit estimation and double-entry transaction recording.
- **Testing & Verification:**
  - Added unit test suite `test/unit/nav_models_test.dart` for plan/option heuristics, date parsers, and micro-paise conversion without float drift.
  - Added unit test suite `test/unit/nav_providers_test.dart` with mock HTTP adapters for MFapi, Tigzig (Cloudflare 1006 detection), and AMFI text parser.
  - Added database integration tests in `test/database/mutual_fund_dao_test.dart` covering scheme search, favourites, NAV deduplication, and multi-profile holdings valuation propagation (44 passing tests total).

## [0.2.0] - 2026-10-30

### Added
- **Multi-Profile & Family Finance Architecture:**
  - Implemented `FinancialProfiles` table and `ProfilesDao` enabling unlimited individual profiles (Self, Spouse, Father, Mother, Children) within a single installation.
  - Strict data separation: `FinancialAccounts`, `FinancialItems`, `Transactions`, and `RecurringTransactions` carry non-null `profile_id` foreign keys with cascading integrity.
  - Category scoping: Pre-seeded system baseline categories are global (`profile_id IS NULL`), while custom categories are scoped to individual profiles.
  - Cross-profile transaction integrity validation: Prevents transactions from referencing financial items or accounts belonging to different profiles.
  - Active profile state management: Riverpod `ActiveProfileNotifier`, `activeProfileIdProvider`, `allProfilesProvider`, and scoped derivative providers (`activeProfileAccountsProvider`, `activeProfileAssetsProvider`, etc.) with local persistence in `app_settings`.
  - Household overview preparation: Aggregate query capabilities (`calculateHouseholdNetWorth`, `watchHouseholdItems`, `watchHouseholdActiveSchedules`).
- **Drift SQLite Database Layer:**
  - Implemented offline-first local persistence using `drift: ^2.24.2` and `drift_flutter: ^0.2.4`.
  - Configured platform SQLite connection with foreign keys enabled (`PRAGMA foreign_keys = ON;`).
  - Automatic seeding of initial primary profile ("My Profile", `isDefault: true`), active profile preference, and 15 baseline categories.
- **Normalized Schema Architecture (8 Tables):**
  - `FinancialProfiles`: Multi-person profile registry with avatars, relationship labels, default markers, and soft-archive support.
  - `FinancialCategories`: Hierarchical category classification for assets, liabilities, income, and expenses.
  - `FinancialAccounts`: Bank accounts, cash reserves, Demat portfolios, and loan accounts.
  - `FinancialItems`: Unified storage for assets (mutual funds, stocks, FDs, gold) and liabilities (home loans, vehicle loans, credit cards).
  - `Transactions`: Immutable double-entry ledger tracking purchases, redemptions, loan payments, transfers, and cash flows.
  - `ValuationHistory`: Daily NAV and asset valuation time-series with composite unique constraint `(financial_item_id, valuation_date)`.
  - `RecurringTransactions`: Execution schedules for simulated SIP investments and loan EMI payments.
  - `AppSettings`: Typed key-value configuration store for application settings and synchronization states.
- **Data Access Objects (8 DAOs):**
  - `ProfilesDao`, `CategoriesDao`, `AccountsDao`, `FinancialItemsDao`, `TransactionsDao`, `ValuationsDao`, `RecurringTransactionsDao`, `AppSettingsDao`.
  - Reactive `Stream` watchers for UI consumption and atomic `Future` mutations.
  - Atomic upsert support for `ValuationHistory` using Drift `DoUpdate` targeting composite keys.
- **Financial Precision Engine:**
  - `FinancialPrecision` utility module preventing floating-point representation drift.
  - Currency stored as 64-bit integer Paise ($₹1 = 100\text{ paise}$).
  - Mutual fund / stock units stored as 64-bit integer micro-units ($1\text{ unit} = 1,000,000\text{ micro-units}$).
  - NAV stored as 64-bit integer micro-paise ($₹1 = 1,000,000\text{ micro-paise}$) for 4-decimal-place AMFI precision.
  - Interest rates stored in basis points ($1\% = 100\text{ bps}$).
- **Automated In-Memory Test Suite:**
  - Added unit test suite `test/unit/financial_precision_test.dart` for mathematical precision and edge-case conversions.
  - Added comprehensive database integration tests `test/database/app_database_test.dart` running against in-memory SQLite (`NativeDatabase.memory()`).
  - Verified default profile & category seeding, multi-profile switching, profile archiving, account & asset data separation, cross-profile integrity violations, transactions ledger, schedule updates, and valuation uniqueness constraints (26 passing tests).

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
