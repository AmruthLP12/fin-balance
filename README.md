# FinBalance

> **FinBalance** is an offline-first, multi-profile personal finance and net worth management application for Android and Web, built with Flutter and SQLite (Drift).

---

## 1. Product Overview & Architecture

FinBalance models the entire balance sheet of an individual or multi-member household:

1. **Assets (+):** Mutual funds, SIPs, stocks, ETFs, gold, fixed deposits, PPF, EPF, GPF, NPS, bonds, bank balances, and other investments.
2. **Liabilities (−):** Home loans, personal loans, vehicle loans, education loans, credit card dues, and other borrowings.
3. **Cash Flow & Activity:** Scheduled SIP installments, loan EMI payments, income, expenses, deposits, withdrawals, and adjustments.

### Unified Wealth Overview
$$\text{Net Worth} = \text{Total Assets} - \text{Total Liabilities}$$

### Core Tenets
- **100% Offline-First:** All financial balances, liabilities, and records reside locally in SQLite storage via Drift.
- **Multi-Profile Family Finance:** Full data isolation for multiple people (Self, Spouse, Father, Mother, Children) within a single installation. Switching profiles instantly updates all dashboards.
- **Privacy by Design:** Zero bank credentials, broker accounts, or cloud logins required.
- **High-Precision Financial Arithmetic:** Absolute zero floating-point error using integer paise ($10^{-2}$ INR), micro-units ($10^{-6}$ units), and micro-paise ($10^{-6}$ INR).
- **Dual-Platform SQLite (Android & Web):** Native SQLite with isolate sharing on Android; SQLite3 WebAssembly (`sqlite3.wasm`) with dedicated web worker (`drift_worker.js`) on Flutter Web.
- **Replaceable NAV Providers:** Fetches public mutual fund NAVs (MFapi.in, TIGZIG, AMFI) with local SQLite caching and automatic holdings valuation updates.

---

## 2. Technology Stack & Platform Strategies

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.47+ (Android & Web) |
| **Language** | Dart 3.13+ (Strict typing & null safety) |
| **State Management** | Riverpod (`flutter_riverpod: ^2.6.1`) |
| **Persistence (Android)** | Local SQLite via `drift`, `drift_flutter`, `sqlite3_flutter_libs` with isolate sharing |
| **Persistence (Web)** | SQLite Wasm via `drift/wasm.dart`, `sqlite3.wasm`, `drift_worker.js` |
| **Networking** | Dio (`dio: ^5.7.0`) |
| **Visualizations** | FL Chart (`fl_chart: ^0.70.2`) |
| **Reminders** | Flutter Local Notifications (`flutter_local_notifications: ^18.0.1`) |
| **Formatting** | Intl (`intl: ^0.20.2`) |

### Database Platform Strategies
- **Android:** Uses `DriftNativeOptions(shareAcrossIsolates: true)` with database stored in the local application documents directory (`finbalance.sqlite`).
- **Web:** Uses `DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js'))` utilizing browser Origin Private File System (OPFS) and IndexedDB fallbacks.

---

## 3. Directory Structure

```text
lib/
├── main.dart                     # App entry point with ProviderScope
├── app.dart                      # Root MaterialApp & theme configuration
├── core/
│   ├── constants/                # AppConstants (INR, sync intervals, keys)
│   ├── formatting/               # CurrencyFormatter & DateFormatter
│   ├── providers/                # Global state providers (theme, database, DAOs, profiles)
│   ├── theme/                    # AppColors, AppTypography, AppSpacing, AppTheme
│   └── widgets/                  # FinCard, StatCard, StatusBadge, SectionHeader, EmptyStateView
├── data/
│   └── nav/                      # NAV provider layer (MFapi, TIGZIG, AMFI) & sync coordinator
│       ├── models/               # MutualFundSearchResult, NavRecord, MutualFundSchemeDetail
│       ├── nav_provider.dart     # Provider-independent abstract interface
│       ├── mfapi_provider.dart   # Primary MFapi.in REST adapter
│       ├── tigzig_provider.dart  # Secondary TIGZIG adapter with Cloudflare 1006 handling
│       ├── amfi_provider.dart    # Tertiary AMFI text parser fallback
│       └── nav_sync_service.dart # Failover, caching, and valuation propagation orchestrator
├── database/
│   ├── app_database.dart         # Drift AppDatabase with schema version 2 & migrations
│   ├── connection/               # Multi-platform Drift connection (Native SQLite & Web WASM)
│   ├── precision/                # FinancialPrecision (Paise, micro-units, micro-paise)
│   ├── tables/                   # Drift table definitions (10 normalized tables)
│   └── daos/                     # Data Access Objects (9 specialized DAOs)
├── features/
│   ├── navigation/               # Responsive MainScaffold (NavigationBar on mobile, NavigationRail on desktop)
│   ├── profile/                  # Multi-profile management & switching
│   │   ├── widgets/              # ProfileAvatar, ProfileSelectorButton, ProfileSwitcherSheet, ProfileFormDialog
│   │   └── screens/              # ProfileManagementScreen
│   ├── overview/                 # Net Worth hero dashboard dynamically scoped to active profile
│   ├── assets/                   # Profile holdings, mutual fund catalogue search, details, and addition
│   │   ├── widgets/              # HoldingCard, MutualFundCard, SchemeDetailsSheet, HoldingDetailsSheet, AddToProfileDialog, EditHoldingDialog
│   │   └── screens/              # AssetsScreen, MutualFundSearchScreen
│   ├── liabilities/              # Loans, credit card dues, and EMI tracking
│   ├── activity/                 # Transaction ledger, simulated SIPs, EMI flows
│   └── settings/                 # Preferences, profile management shortcut, sync configuration
└── web/                          # Web scaffolding, index.html, manifest.json, sqlite3.wasm, drift_worker.js
```

---

## 4. Development Commands

The repository provides a `Makefile` configured to use the verified system Flutter binary (`FLUTTER := /snap/bin/flutter`):

```bash
# Display available commands
make help

# Install dependencies
make get

# Run static code analysis
make analyze

# Format Dart code
make format

# Run automated tests
make test

# Build Android debug APK (/snap/bin/flutter build apk --debug)
make build-debug

# Build Android release APK (/snap/bin/flutter build apk --release)
make build-release

# Build Flutter Web application (/snap/bin/flutter build web)
make build-web

# Run application locally in Chrome
make run-web

# Clean build artifacts
make clean
```

---

## 5. Implementation Roadmap

- [x] **Milestone 1 — Project Foundation:** Scaffolding, Riverpod, Design System, Theme Tokens, Responsive Navigation (`Overview`, `Assets`, `Liabilities`, `Activity`, `Settings`), Makefile, Documentation.
- [x] **Milestone 2 — Drift Database Layer:** Schema definition (8 normalized tables: Profiles, Categories, Accounts, Items, Transactions, Valuations, Recurring Schedules, Settings), multi-profile family finance data isolation, specialized DAOs with reactive streams, integer precision engine (Paise/micro-units/micro-paise), foreign keys with cascade/restrict, default profile & category seeding, and in-memory test suite.
- [x] **Milestone 3 — Mutual Fund & NAV Integration:** Provider-independent NAV integration layer (`NavProvider`), primary `MFapiProvider`, secondary `TigzigProvider` with Cloudflare 1006 detection, tertiary `AmfiProvider` semicolon text parser, `NavSyncService` coordinator, global master catalog (`MutualFundSchemes` & `NavHistory`), debounced scheme search, favourites stream, scheme details sheet, and profile asset addition modal.
- [x] **Corrective Task — Multi-Profile Management, Holdings Workflow & Flutter Web Support:**
  - Implemented end-to-end profile creation dialog, relationship picker, avatar color palette, and description notes.
  - Implemented interactive profile selector button in header and modal profile switcher sheet.
  - Implemented dedicated Profile Management screen with edit, archive/restore, default toggle, and deletion protection for profiles with financial history.
  - Connected `AssetsScreen` to live profile holdings (`FinancialItems`) with category filters and `HoldingCard` displaying current value, invested value, gains, and units.
  - Connected `OverviewScreen` to calculate dynamic Net Worth, Total Assets, and Total Liabilities scoped to active profile.
  - Enabled Flutter Web compilation with `DriftWebOptions`, `sqlite3.wasm`, and `drift_worker.js`.
  - Added responsive layout with `NavigationRail` for desktop/tablet screens (>= 720px) and bottom `NavigationBar` for mobile screens.
- [x] **Milestone 4 — Flexible SIP Scheduling, NAV Caching Policy & Profile Startup:**
  - Flexible multi-period SIP architecture (`SipPlans`, `SipSchedulePeriods`, `SipInstallments`) supporting step-up, step-down, and changing deduction days over time.
  - Zero-drift month-end clamping with `RecurringDateCalculator` handling leap years (Feb 28/29) and 30-day months without progressive drift.
  - Bulk historical SIP entry with distinction between actual confirmed past investments and simulated projections.
  - Startup `ProfileSelectionScreen` providing cold-boot profile picking, "Quick Continue", and on-demand lazy loading.
  - Configurable NAV synchronization policy (`Daily`, `Weekly`, `Manual Only`) with next-eligible sync timestamp calculation and cache-first scheme viewing.
  - Profile-isolated favourite schemes with atomic toggle and reactive Drift streams.
- [x] **Mobile UX, Navigation, Activity Ledger & Cash Flow Analysis:**
  - Redesigned mobile form layout for adding mutual funds and liabilities with persistent top AppBar Save buttons and keyboard-friendly scroll views.
  - Top-left return to profile picker (`ReturnToProfilesButton`) across all primary sections.
  - Context-aware circular Floating Action Button (`+`) customized across Overview, Assets, Liabilities, and Activity tabs.
  - Centralized NAV synchronization in Settings only with granular status and error details.
  - Real database-driven Activity Ledger with multi-dimension filtering (type, category, date range) and transaction deletion.
  - Dedicated Cash Flow analysis view with period selectors, savings rate calculation, and proportional category progress breakdowns (with strict internal transfer exclusion).
- [ ] **Milestone 5 — Transaction & Valuation Engine:** Simulated installments, lump-sum purchases, redemptions, unit calculations.
- [ ] **Milestone 6 — Dashboard & Overview:** Real-time net worth calculation, active SIPs, upcoming EMIs.
- [ ] **Milestone 7 — Financial Analytics:** Dated-cashflow XIRR (Newton-Raphson), asset allocation, historical charts.
- [ ] **Milestone 8 — Backup, Restore & Reminders:** Portable JSON export/import with validation, local notification reminders.
- [ ] **Milestone 9 — Verification & Release Build:** Automated test suite, static checks, release APK build.

---

## 6. License & Privacy

FinBalance is designed for complete local privacy. No user financial data is transmitted to external servers.
