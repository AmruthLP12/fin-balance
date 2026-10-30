# FinBalance

> **FinBalance** is an offline-first, comprehensive personal finance and net worth management application for Android, built with Flutter and SQLite.

---

## 1. Product Overview & Architecture

FinBalance models the entire balance sheet of an individual:

1. **Assets (+):** Mutual funds, SIPs, stocks, ETFs, gold, fixed deposits, PPF, EPF, GPF, NPS, bonds, bank balances, and other investments.
2. **Liabilities (−):** Home loans, personal loans, vehicle loans, education loans, credit card dues, and other borrowings.
3. **Cash Flow & Activity:** Scheduled SIP installments, loan EMI payments, income, expenses, deposits, withdrawals, and adjustments.

### Unified Wealth Overview
$$\text{Net Worth} = \text{Total Assets} - \text{Total Liabilities}$$

### Core Tenets
- **100% Offline-First:** All financial balances, liabilities, and records reside exclusively in local SQLite storage via Drift.
- **Privacy by Design:** Zero bank credentials, broker accounts, or cloud logins required.
- **Simulated SIP Tracking:** Projects scheduled contributions according to user frequencies and calculates estimated values using published NAV data.
- **Replaceable NAV Providers:** Fetches public mutual fund NAVs (MFapi.in, TIGZIG) with local caching.

---

## 2. Technology Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.47+ |
| **Language** | Dart 3.13+ (Strict typing & null safety) |
| **State Management** | Riverpod (`flutter_riverpod: ^2.6.1`) |
| **Persistence** | SQLite with Drift (`drift`, `drift_flutter`, `sqlite3_flutter_libs`) |
| **Networking** | Dio (`dio: ^5.7.0`) |
| **Visualizations** | FL Chart (`fl_chart: ^0.70.2`) |
| **Reminders** | Flutter Local Notifications (`flutter_local_notifications: ^18.0.1`) |
| **Formatting** | Intl (`intl: ^0.20.2`) |

---

## 3. Directory Structure

```text
lib/
├── main.dart                     # App entry point with ProviderScope
├── app.dart                      # Root MaterialApp & theme configuration
├── core/
│   ├── constants/                # AppConstants (INR, sync intervals, keys)
│   ├── formatting/               # CurrencyFormatter & DateFormatter
│   ├── providers/                # Global state providers (theme, database, DAOs)
│   ├── theme/                    # AppColors, AppTypography, AppSpacing, AppTheme
│   └── widgets/                  # FinCard, StatCard, StatusBadge, SectionHeader, EmptyStateView
├── database/
│   ├── app_database.dart         # Drift AppDatabase with schema version 1 & migrations
│   ├── connection/               # Native SQLite connection via drift_flutter
│   ├── precision/                # FinancialPrecision (Paise, micro-units, micro-paise)
│   ├── tables/                   # Drift table definitions (7 normalized tables)
│   │   ├── financial_categories.dart
│   │   ├── financial_accounts.dart
│   │   ├── financial_items.dart
│   │   ├── transactions.dart
│   │   ├── valuation_history.dart
│   │   ├── recurring_transactions.dart
│   │   └── app_settings.dart
│   └── daos/                     # Data Access Objects (7 specialized DAOs)
│       ├── categories_dao.dart
│       ├── accounts_dao.dart
│       ├── financial_items_dao.dart
│       ├── transactions_dao.dart
│       ├── valuations_dao.dart
│       ├── recurring_transactions_dao.dart
│       └── app_settings_dao.dart
└── features/
    ├── navigation/               # MainScaffold with 5-tab NavigationBar
    ├── overview/                 # Net Worth summary & monthly commitments
    ├── assets/                   # Mutual funds, SIPs, stocks, deposits, and gold
    ├── liabilities/              # Loans, credit card dues, and EMI tracking
    ├── activity/                 # Transaction ledger, simulated SIPs, EMI flows
    └── settings/                 # Preferences, sync configuration, backup & restore
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

# Clean build artifacts
make clean
```

---

## 5. Implementation Roadmap

- [x] **Milestone 1 — Project Foundation:** Scaffolding, Riverpod, Design System, Theme Tokens, 5-Tab Navigation (`Overview`, `Assets`, `Liabilities`, `Activity`, `Settings`), Makefile, Documentation.
- [x] **Milestone 2 — Drift Database Layer:** Schema definition (7 normalized tables: Categories, Accounts, Items, Transactions, Valuations, Recurring Schedules, Settings), 7 specialized DAOs with reactive streams, integer precision engine (Paise/micro-units/micro-paise), foreign keys with cascade/restrict, default category seeding, and in-memory test suite.
- [ ] **Milestone 3 — Mutual Fund & NAV Integration:** Provider adapters (MFapi.in & TIGZIG), search, local NAV caching.
- [ ] **Milestone 4 — SIP & Commitment Scheduling:** Independent date generator, leap year & month-end handlers, duplicate prevention.
- [ ] **Milestone 5 — Transaction & Valuation Engine:** Simulated installments, lump-sum purchases, redemptions, unit calculations.
- [ ] **Milestone 6 — Dashboard & Overview:** Real-time net worth calculation, active SIPs, upcoming EMIs.
- [ ] **Milestone 7 — Financial Analytics:** Dated-cashflow XIRR (Newton-Raphson), asset allocation, historical charts.
- [ ] **Milestone 8 — Backup, Restore & Reminders:** Portable JSON export/import with validation, local notification reminders.
- [ ] **Milestone 9 — Verification & Release Build:** Automated test suite, static checks, release APK build.

---

## 6. License & Privacy

FinBalance is designed for complete local privacy. No user financial data is transmitted to external servers.
