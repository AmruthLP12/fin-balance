# FinBalance — Project Documentation

**Project type:** Offline-first Android application  
**Working name:** FinBalance  
**Platform:** Android  
**Technology:** Flutter + Dart  
**Database:** SQLite using Drift  
**Architecture:** Local-first, feature-oriented architecture  
**Data providers:** MFapi.in + TIGZIG (configurable public providers)  
**Scope:** Comprehensive personal balance sheet (Assets, Liabilities, Cash Flow, Net Worth)  
**Backend:** None  
**Hosting:** None  
**Authentication:** Not required  
**API keys:** Not required for public NAV endpoints

---

# Document 1: prod.md

# Product Requirements Document (PRD)

## 1. Product Overview

FinBalance is an offline-first Android application designed to help individuals manage and monitor their complete financial position:
- **Assets:** Systematic Investment Plans (SIPs), mutual funds, stocks, fixed deposits, gold, and liquid cash.
- **Liabilities:** Home loans, vehicle loans, education loans, personal loans, and credit card debt.
- **Cash Flow:** Scheduled SIP contributions, loan EMIs, and monthly budget commitments.
- **Net Worth:** Real-time balance calculation (`Total Assets - Total Liabilities`).

The application allows users to configure their existing SIPs and liabilities, tracking scheduled monthly commitments automatically.

For mutual fund assets, it retrieves publicly accessible NAV data and calculates estimated investment values, units, and portfolio performance.

All application data is stored locally on the device in an encrypted/private SQLite database.

The application must work completely without an internet connection, except when optionally synchronizing updated mutual fund NAV information.

## 2. Product Objectives

The primary objectives are:

1. Provide a centralized investment tracking application.
2. Allow users to record existing SIP configurations.
3. Automatically generate scheduled SIP contributions.
4. Retrieve updated mutual fund NAV values.
5. Calculate estimated units and portfolio valuation.
6. Display investment performance and returns.
7. Maintain historical investment records.
8. Provide complete local data ownership.
9. Eliminate dependence on hosted databases and backend services.

## 3. Target Users

Individuals who:

- Have existing mutual fund SIPs.
- Want to monitor their monthly investment commitments.
- Want to track estimated portfolio value.
- Want to understand their investment growth.
- Prefer maintaining their financial information locally.
- Do not want to connect their bank accounts.

## 4. Core Product Principles

### Local-first

All essential application operations must work using local SQLite storage.

### No financial account integration

The application must not connect to bank accounts, UPI accounts, brokers or mutual fund platforms.

### Simulated contribution tracking

Scheduled SIP contributions are automatically recorded as planned investments.

These records are estimates and must never be presented as verified transactions or actual mutual fund allotments.

### Automatic NAV synchronization

NAV information should be retrieved from external providers when internet access is available.

### Data ownership

Users must be able to export, back up, restore and delete their local application data.

## 5. Functional Requirements

### 5.1 Dashboard

The dashboard should display:

- Total invested amount.
- Estimated current portfolio value.
- Estimated profit or loss.
- Absolute return percentage.
- Annualized XIRR.
- Active SIP count.
- Total monthly SIP commitment.
- Upcoming SIP contributions.
- Monthly investment summary.
- Portfolio allocation by fund and category.
- NAV synchronization status.

Dashboard sections:

1. Portfolio overview.
2. Investment performance.
3. Active SIPs.
4. Upcoming contributions.
5. Recent activity.
6. Investment distribution.

### 5.2 Mutual Fund Management

Users should be able to search and select mutual fund schemes.

Scheme information should include:

- Scheme name.
- Scheme code.
- AMC.
- Scheme category.
- Fund type.
- Plan type.
- Option type.
- Latest available NAV.
- NAV date.
- Data provider.

Support:

- Direct plans.
- Regular plans.
- Growth options.
- IDCW options where available.

Scheme search should support:

- Fund name.
- AMC name.
- Scheme code.
- Partial text matching.

Users should be able to mark schemes as favourites.

### 5.3 SIP Management

Users must be able to create and manage multiple SIP configurations.

Required fields:

- SIP name.
- Mutual fund scheme.
- Monthly investment amount.
- Start date.
- Optional end date.
- Deduction date.
- Frequency.
- Initial investment amount, if applicable.
- Notes.
- SIP status.

Supported frequencies:

- Weekly.
- Monthly.
- Quarterly.

Supported SIP statuses:

- Active.
- Paused.
- Completed.
- Stopped.

SIP operations:

- Create SIP.
- Edit SIP.
- Pause SIP.
- Resume SIP.
- Stop SIP.
- Change SIP amount.
- Change scheduled date.
- View contribution history.
- View upcoming contributions.

Changes to an SIP must not rewrite its historical contributions.

### 5.4 Scheduled SIP Contributions

The application should automatically generate scheduled contribution records.

Example:

SIP configuration:

- Amount: ₹5,000.
- Start date: 5 January 2026.
- End date: 5 January 2030.
- Frequency: Monthly.
- Scheduled day: 5.

Expected records:

| Date        | Amount | Status  |
| ----------- | -----: | ------- |
| 05 Jan 2026 | ₹5,000 | Planned |
| 05 Feb 2026 | ₹5,000 | Planned |
| 05 Mar 2026 | ₹5,000 | Planned |

When a scheduled date arrives:

1. Check whether the contribution has already been generated.
2. Create the contribution record.
3. Retrieve the latest available NAV.
4. Calculate estimated units.
5. Update portfolio calculations.
6. Record the contribution date and NAV source.

Contribution processing must be idempotent. The same scheduled contribution must never be generated twice.

Supported contribution statuses:

- Upcoming.
- Recorded.
- Skipped.
- Cancelled.

The application must distinguish between a contribution generated by the application and an actual transaction entered or imported by the user.

### 5.5 Transaction Management

Users must be able to manually add:

- Simulated SIP contributions.
- Manual lump-sum investments.
- Additional purchases.
- Redemptions.
- Unit adjustments.
- Corrections.

Transaction fields:

- Mutual fund.
- Transaction type.
- Transaction date.
- Investment amount.
- NAV.
- Units.
- Source.
- Notes.

Transaction sources:

- Automatic SIP schedule.
- Manual entry.
- CAS import.
- Correction.

The transaction history must be editable.

### 5.6 Portfolio Calculations

Calculate:

- Total invested amount.
- Total estimated units.
- Latest NAV.
- Estimated current value.
- Estimated profit/loss.
- Absolute return.
- Annualized return.
- XIRR.

Formulas:

Estimated units:

Units = Investment Amount / Applicable NAV

Total units:

Total Units = Sum of Purchase Units - Sum of Redeemed Units

Estimated current value:

Current Value = Total Units × Latest NAV

Profit/Loss:

Profit/Loss = Current Value - Net Invested Capital

Absolute return:

Absolute Return = (Profit/Loss / Net Invested Capital) × 100

XIRR must use dated cash flows rather than a simple annualized return calculation.

All calculations must support appropriate decimal precision.

### 5.7 Historical NAV

Store historical NAV values locally.

Required information:

- Scheme code.
- NAV date.
- NAV value.
- Provider.
- Fetch timestamp.

Requirements:

- Avoid duplicate NAV records.
- Do not overwrite newer records with older records.
- Retain historical records.
- Support historical valuation.
- Support NAV trend charts.
- Display the actual NAV date.

### 5.8 SIP Calendar

Provide a calendar showing:

- Upcoming SIP contributions.
- Completed simulated contributions.
- Skipped contributions.
- Paused SIPs.
- Monthly investment commitments.

Users should be able to select a date and view associated SIPs.

### 5.9 Analytics

Provide:

- Overall portfolio growth.
- Monthly investment history.
- Yearly investment summary.
- Fund-wise returns.
- AMC-wise allocation.
- Category-wise allocation.
- Investment distribution.
- Individual SIP performance.
- Historical portfolio valuation.

### 5.10 Notifications

Provide local notifications for:

- Upcoming SIP date.
- SIP contribution recorded.
- NAV synchronization failure.
- Data backup reminders.

Users must be able to configure notification preferences.

Notifications are optional and must not affect contribution calculations.

### 5.11 Backup and Restore

Support:

- Export all user data to JSON.
- Import a previous backup.
- Validate backup structure.
- Handle duplicate records.
- Restore investment history.
- Restore SIP configurations.
- Restore application settings.

NAV cache may be included in backups or rebuilt from external providers.

The user must explicitly confirm before replacing existing data.

### 5.12 Settings

Include:

- Theme selection.
- Currency preference.
- NAV synchronization settings.
- Manual synchronization.
- Notification settings.
- Backup and restore.
- Data management.
- About application.
- Privacy information.

Default currency: INR (₹).

## 6. Non-functional Requirements

### Performance

- Dashboard should load primarily from local database data.
- NAV synchronization must not block normal application usage.
- Large historical datasets should use pagination or efficient queries.
- Charts should avoid loading unnecessary records.

### Reliability

- Database transactions must be atomic.
- Contribution generation must prevent duplicates.
- Failed NAV requests must not corrupt existing records.
- Last successful NAV values must remain available.

### Privacy

- No mandatory user account.
- No cloud database.
- No financial account credentials.
- No analytics or telemetry containing investment details by default.

### Usability

- Mobile-first interface.
- Responsive layouts.
- Clear financial summaries.
- Accessible typography.
- Consistent number and currency formatting.

## 7. Out of Scope

The following are explicitly excluded from the initial release:

- Bank account integration.
- UPI integration.
- Broker integration.
- Actual SIP execution.
- Mutual fund purchase or redemption.
- Payment processing.
- Financial advice.
- Tax filing.
- Hosted user accounts.
- Cloud synchronization.
- Multi-device synchronization.
- Stock market real-time trading data.

## 8. Future Enhancements

Potential future modules:

- Stocks.
- ETFs.
- Sovereign Gold Bonds.
- Physical and digital gold.
- Fixed deposits.
- PPF.
- EPF.
- GPF.
- NPS.
- Bonds.
- SIF investments.
- Loans and liabilities.
- Financial goals.
- Net worth tracking.

These should be implemented as separate investment modules rather than complicating the initial SIP implementation.

## 9. Release Milestones

### MVP

- Local database.
- Mutual fund search.
- SIP configuration.
- Automatic scheduled contributions.
- NAV synchronization.
- Portfolio valuation.
- Basic dashboard.
- Transaction history.

### Release 2

- XIRR.
- Historical charts.
- SIP calendar.
- Notifications.
- Lump-sum investments.
- Backup and restore.

### Release 3

- Advanced analytics.
- Goals.
- Additional asset classes.
- Improved reports.
