# FinBalance

> **FinBalance** is a modern, offline-first personal finance and net worth tracking application for Android, built with Flutter and SQLite.

---

## 1. Product Overview

FinBalance helps individuals maintain a complete, private financial balance sheet on their device:

- **Assets:** Mutual funds (SIP & lump sum), stocks, ETFs, fixed deposits, gold, PPF, EPF, and cash.
- **Liabilities:** Home loans, vehicle loans, education loans, personal loans, and credit card debt.
- **Cash Flow:** Scheduled SIP contributions, loan EMIs, deposits, and planned commitments.
- **Overview:** Dynamic Net Worth (`Total Assets - Total Liabilities`), debt-to-asset ratios, and dated-cashflow returns (XIRR).

### Key Differentiators
- **100% Offline-First:** All financial balances, transactions, and configurations reside exclusively in local SQLite database storage.
- **No Financial Integrations:** Zero bank logins, broker connections, or UPI credentials required.
- **Simulated SIP Tracking:** Automatically generates expected contributions according to user schedules and estimates value using public AMFI/NAV data.
- **Replaceable NAV Providers:** Retrieves mutual fund NAVs from public endpoints (MFapi.in and TIGZIG) with local caching.

---

## 2. Technology Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.47+ |
| **Language** | Dart 3.13+ (Strict typing & null safety) |
| **State Management** | Riverpod (`flutter_riverpod`) |
| **Persistence** | SQLite with Drift (`drift`, `drift_flutter`, `sqlite3_flutter_libs`) |
| **Networking** | Dio (`dio`) |
| **Visualizations** | FL Chart (`fl_chart`) |
| **Reminders** | Flutter Local Notifications (`flutter_local_notifications`) |
| **Formatting** | Intl (`intl`) |

---

## 3. Architecture & Directory Structure

FinBalance is organized around a clean, feature-oriented architecture:

```text
lib/
├── main.dart                     # App entry point with ProviderScope
├── app.dart                      # Root MaterialApp & theme configuration
├── core/
│   ├── constants/                # AppConstants (INR, sync intervals, keys)
│   ├── formatting/               # CurrencyFormatter & DateFormatter
│   ├── providers/                # Global state providers (e.g. themeModeProvider)
│   ├── theme/                    # AppColors, AppTypography, AppSpacing, AppTheme
│   └── widgets/                  # FinCard, StatCard, StatusBadge, SectionHeader, EmptyStateView
├── features/
│   ├── navigation/               # MainScaffold with 5-tab NavigationBar
│   ├── overview/                 # Net Worth summary & monthly commitments
│   ├── assets/                   # Mutual funds, SIPs, and asset holdings
│   ├── liabilities/              # Loans, EMIs, and debt payoff tracking
│   ├── analytics/                # Net worth composition, XIRR & financial health
│   └── settings/                 # Preferences, sync configuration, backup & restore
```

---

## 4. Development Commands

A comprehensive `Makefile` is provided for common development tasks:

```bash
# Display help and command list
make help

# Install dependencies
make get

# Run static code analysis
make analyze

# Format Dart code
make format

# Run automated tests
make test

# Build Android debug APK
make build-debug

# Build Android release APK
make build-release

# Clean build artifacts
make clean
```

---

## 5. Implementation Roadmap

- [x] **Milestone 1 — Project Foundation:** Scaffolding, Riverpod, Design System, Theme Tokens, 5-Tab Navigation, Makefile, Documentation.
- [ ] **Milestone 2 — Drift Database Layer:** Schema definition (Assets, Liabilities, Schemes, NAVHistory, Transactions, Settings), DAOs, migrations.
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

