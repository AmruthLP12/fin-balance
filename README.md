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
| **Android build** | Gradle 9.3.1, Android Gradle Plugin 9.1.0, Kotlin 2.4.0 (built-in Kotlin), JDK 17 |

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
│   ├── calculations/             # FinancialCalculator (XIRR Newton-Raphson, P&L, returns) & InvestmentLifecycleSummary (timeline + overview)
│   ├── scheduling/               # InvestmentScheduleService (8 frequencies, zero-drift dates) & RecurringDateCalculator
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
│   ├── app_database.dart         # Drift AppDatabase with schema version 5 & safe migrations
│   ├── connection/               # Multi-platform Drift connection (Native SQLite & Web WASM)
│   ├── precision/                # FinancialPrecision (Paise, micro-units, micro-paise)
│   ├── tables/                   # Drift table definitions (17 normalized tables incl. SIP & SWP plans/periods/installments)
│   └── daos/                     # Data Access Objects (11 specialized DAOs)
├── features/
│   ├── navigation/               # Responsive MainScaffold (NavigationBar on mobile, NavigationRail on desktop)
│   ├── profile/                  # Multi-profile management & switching
│   │   ├── widgets/              # ProfileAvatar, ProfileSelectorButton, ProfileSwitcherSheet, ProfileFormDialog
│   │   └── screens/              # ProfileManagementScreen
│   ├── overview/                 # Net Worth hero dashboard dynamically scoped to active profile
│   ├── assets/                   # Profile holdings, mutual fund catalogue search, details, and full-screen forms
│   │   ├── widgets/              # HoldingCard, SipCard (minimal), MutualFundCard, SchemeDetailsSheet, HoldingDetailsSheet, AddToProfileDialog, AddSipDialog, InvestmentLifecycleCard
│   │   └── screens/              # AssetsScreen, SipDetailsScreen (3 Tabs), EditHoldingScreen, EditSipScheduleScreen, AddSipSchedulePeriodScreen, AddInvestmentTransactionScreen, MutualFundSearchScreen
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
- [x] **SIP Cascade Deletion, Data Consistency & Milestone Scope Control:**
  - Atomic cascade deletion for SIP investment schedules (`deleteSip` in `SipsDao`) inside Drift transactions: cleans up master plans, schedule periods, installments (recorded, upcoming, simulated, pending valuation), and linked ledger transactions.
  - Holding recalculation & cleanup: automatically updates or deletes the holding (`FinancialItems`) without leaving orphaned records, while strictly preserving shared master schemes (`MutualFundSchemes`) and historical NAV records (`NavHistory`).
  - Granular installment actions: individual installment deletion with transaction cleanup, status skipping, and future installment cancellation without affecting past recorded investments.
  - Milestone scope control: restricted liabilities tracking to a polished future milestone preview (Home loans, Personal loans, Vehicle loans, Education loans, Credit card dues, Other liabilities) with zero fake records and liabilities excluded from net worth.
  - Transaction scope control: restricted transaction creation strictly to investment workflows (SIPs), removing manual entry dialogs and quick action buttons.
  - Local theme persistence: integrated `ThemeModeNotifier` backed by `AppSettingsDao` for persistent System, Light, and Dark mode preferences across application launches.
- [x] **Profile Overview, Dashboard Redesign, Navigation & SIP Cash Flow Fixes:**
  - Redesigned startup profile picker (`ProfileSelectionScreen`) with top Family-Wide Financial Overview aggregating Total Family Assets, Liabilities (`₹0 • Upcoming`), and Family Net Worth ($Assets - Liabilities$) across all member profiles.
  - Replaced redundant "Quick Continue as" card and "Last Used" / "Default" badges with clean, scannable profile cards showing initials avatar, display name, relationship label, profile assets, liabilities, and profile net worth.
  - Global Android Back Navigation Flow in `MainScaffold` with `PopScope`: Android Back navigates to Overview (tab 0) before returning to the Profile Selection screen, while nested modals, search, and settings pop to previous screens.
  - Clickable FinBalance Logo Header Shortcut: Removed redundant `ReturnToProfilesButton` and `ProfileSelectorButton` in app headers, making the main `FinBalanceLogo` in headers a one-tap shortcut with tooltip "Switch Family Profile" to return to profile selection, with active `ProfileAvatar` in the actions.
  - Standardized `ProfileAvatar` displaying the profile's first letter initial with deterministic color palette across all screen sizes and themes.
  - Profile Overview Dashboard with FL Chart Asset Allocation donut chart, percentage badges, readable legend, and Recent Investment Activity stream (removed redundant "Active Assets" / "Liabilities" stat cards and holdings list).
  - Fixed critical SIP Cash Flow integration: included confirmed SIP contributions (`investment_purchase`) as investment outflows ($Total Outflow = Expenses + Investment Outflows$, $Net Cash Movement = Income - Total Outflow$).
  - Granular asset categories replacing generic "Retirement" with specific categories (PPF, EPF, GPF, NPS, Bonds, Other Assets) and non-destructive automated migration routine in `AppDatabase`.
  - SIP detail popup layout fixes with responsive `Wrap` layouts and post-save redirect popping back to root workspace with success SnackBar.
- [x] **Category Charts, Profile Menu, Privacy Policy & UI Polish ([0.9.0]):**
  - **Asset & Liability Distribution:** Added dedicated distribution section on individual profile dashboard with an FL Chart donut chart for actual assets (Mutual Funds, Stocks, Gold, FDs, NPS, PPF, EPF, GPF, Bonds, Cash & Bank, Other) with complete legend (names, INR formatted valuations, and percentages). Visually isolated liability breakdown with ₹0 indicator and "Coming in a future milestone" status without combining assets and liabilities or fabricating dummy values.
  - **Profile Avatar Popup Menu (`ProfileMenuButton`):** Tapping the profile avatar in headers opens an anchored popover menu with avatar, profile name, relationship, Switch Profile, Manage Profiles, and Add Family Member. The clickable `FinBalanceLogo` shortcut remains dedicated to instant family profile switching.
  - **Comprehensive Privacy Policy:** Added 15-section in-app `PrivacyPolicyScreen` accessible from Settings, detailing the local-first architecture, zero analytics, sandboxed on-device database, and public AMFI NAV network usage with zero personal data transmission. Created canonical markdown file at `docs/privacy-policy.md` for hosting at `https://amruthlp.vercel.app/finbalance_policy`.
  - **Developer Information:** Added "Built by Amruth L P", version `v1.0.0`, portfolio link (`https://amruthlp.vercel.app`), and Privacy Policy link in the Settings About card.
  - **Provider Neutrality:** Removed all user-facing mentions of `MFapi` in settings, sync statuses, and search views in favor of neutral terminology ("Live Market NAV", "market data service"), while strictly preserving underlying `MFapiProvider` implementation and API adapters.
  - **Search & UI Refinements:** Enforced minimum 3 characters for mutual fund search with helpful hint state and instant timer cancellation on query reset. Removed redundant second favourite star in `SchemeDetailsSheet`. Converted "+ Add Profile" text button on `ProfileSelectionScreen` into a compact icon button with tooltip.
- [x] **Unified Financial Category Chart, Privacy Policy Revisions & Support ([0.9.1]):**
  - **Three Switchable Dashboard Charts (`OverviewScreen`):** Retained existing `Cash Flow` and `Portfolio Assets` charts, adding a third unified `Assets & Liabilities by Category` distribution chart as the default dashboard view. Persisted selection to Drift database (`AppSettingsDao`).
  - **Standardized Financial Categories:** Integrated canonical asset and liability categories (`Mutual Funds / SIP`, `Stocks`, `ETFs`, `Fixed Deposits (FD)`, `Recurring Deposits (RD)`, `PPF`, `EPF`, `GPF`, `NPS`, `Gold`, `Bonds`, `Bank Balance`, `Cash`, `Other Assets`; and for liabilities: `Home Loan`, `Personal Loan`, `Vehicle Loan`, `Education Loan`, `Credit Card Dues`, `EMI / Other Loan Dues`, `Other Liabilities`). Zero-value slices are omitted from the pie chart while maintaining non-zero breakdown legends and ₹0 empty liability previews.
  - **Dedicated Support Section (`SettingsScreen`):** Added a dedicated Support section before About containing developer portfolio link (`https://amruthlp.vercel.app`), direct Privacy Policy navigation, and placeholder `"Contact details will be provided here."`.
  - **Revised Privacy Policy:** Removed Section 13 (Open Source) and standalone Section 14 (Contact Info); removed CHANGELOG.md point 3 under Section 11; added Financial Data Accuracy & Market Delays section; updated Advertising disclosures; renumbered cleanly (1 to 14 + Support); and ensured 100% word-for-word synchronization between `docs/privacy-policy.md` and `PrivacyPolicyScreen`.
- [x] **SIP/SWP Details Polish, Lifecycle Timeline & Form Logic ([0.13.0]):**
  - **Minimal SIP Schedules:** `SipCard` shows only name, scheme, status and `SIP · ₹ · Next: date`; edit and delete live on the details page.
  - **SIP Details:** floating `+` for adding transactions on every tab; SIP/SWP sections use a single `⋯` menu instead of many buttons.
  - **Investment Lifecycle:** status and totals overview plus a dated timeline (`InvestmentLifecycleCard`), with SIP installments rolled up per schedule period.
  - **Form logic:** transaction NAV follows the transaction date and is never invented; SIP-type transactions tick off the matching installment; the Add SIP dialog now uses the start-date-based `createInvestmentSchedule` flow with historical-NAV valuation of past installments.
  - **Privacy policy:** Section 4 wording updated (historical NAV rates used to value past installments) in both `docs/privacy-policy.md` and the in-app screen; no new data collected.
  - **Fixes & cleanup:** daily end-date schedules no longer truncated at 360 dates; no ₹100 fallback NAV (holdings fall back to cost); shared holding-update helper and single XIRR implementation.
- [x] **Android Toolchain Upgrade ([0.13.1]):** removed ignored duplicate `*.gradle.kts` files under `android/`; upgraded to Gradle 9.3.1, AGP 9.1.0 and Kotlin 2.4.0 (built-in Kotlin); debug and release APKs verified.
- [x] **Recurring Transactions from the Form & Market-Aware Hints ([0.14.0]):** SIP Investment and SWP Withdrawal on the transaction form take a frequency and number of installments (first one recorded, rest planned, SIP/SWP created or extended); SWP withdrawals tick off schedule installments; charges, NAV cut-off and units hints follow Indian mutual fund rules; overflow fixes for long SIP names and narrow screens. Not yet: STP, bonus units, tax reporting.
- [ ] **Milestone 5 — Transaction & Valuation Engine:** Simulated installments, lump-sum purchases, redemptions, unit calculations.
- [ ] **Milestone 6 — Dashboard & Overview:** Real-time net worth calculation, active SIPs, upcoming EMIs.
- [ ] **Milestone 7 — Financial Analytics:** Dated-cashflow XIRR (Newton-Raphson), asset allocation, historical charts.
- [ ] **Milestone 8 — Backup, Restore & Reminders:** Portable JSON export/import with validation, local notification reminders.
- [ ] **Milestone 9 — Verification & Release Build:** Automated test suite, static checks, release APK build.

---

## 6. Developer, Support & Privacy Information

- **Built by:** Amruth L P
- **Developer Portfolio:** [https://amruthlp.vercel.app](https://amruthlp.vercel.app)
- **Application Version:** `v1.0.0`
- **Support & Inquiries:** Accessible in-app under `Settings` $\rightarrow$ `Support` (`Contact details will be provided here.`).
- **In-App Privacy Policy:** Open `Settings` $\rightarrow$ `Support` $\rightarrow$ `Privacy Policy`.
- **Privacy Policy Markdown File:** Located in the repository at [`docs/privacy-policy.md`](docs/privacy-policy.md).
- **Public Privacy Policy URL:** Hosted at [https://amruthlp.vercel.app/finbalance_policy](https://amruthlp.vercel.app/finbalance_policy).

### Privacy Policy Hosting Instructions
To host the policy document publicly:
1. Copy or reference `docs/privacy-policy.md` in your Next.js/Vercel project at the route `/finbalance_policy`.
2. Use standard Markdown rendering (such as `react-markdown` or Next.js MDX) to serve the page at `https://amruthlp.vercel.app/finbalance_policy`.
3. The content matches the in-app `PrivacyPolicyScreen` identically, detailing the 14 privacy clauses, local-first on-device database architecture, financial data accuracy and market delays disclosures, and network usage restricted strictly to public AMFI mutual fund NAV rates with zero user data transmission.
