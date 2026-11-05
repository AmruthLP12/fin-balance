# Changelog

All notable changes to the FinBalance application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.20.0] - 2026-11-05

### Added
- **In-app updates for testers.** On launch (silently) and from **Settings > Support > Check for Updates**, the app asks the GitHub Releases API of `AmruthLP12/fin-balance` for the latest release. If its tag is newer than the installed version, a dialog shows the version, size and release notes with **Remind me later** and **Download & install**. The first `.apk` asset is downloaded with a progress bar, its size is checked, and Android's installer is opened. "Last checked" is shown in Settings.
- Android permission `REQUEST_INSTALL_PACKAGES` (Android asks the user to allow installs from FinBalance once).
- Dependencies: `package_info_plus`, `open_filex`.
- Test: version comparison.

### Changed
- `pubspec.yaml` version is now `0.20.0+20` and matches the release tag; the Settings version label reads the installed version instead of a hard-coded `1.0.0`.
- Privacy policy (docs and in-app, identical): states the GitHub update check and download.

### Notes
- Releases must keep an `.apk` asset and a `vX.Y.Z` tag, and must be signed with the same key as the installed app or Android refuses the update. The release build currently uses the debug key, so build every release on the same machine (or set up a release keystore).

## [0.19.0] - 2026-11-05

### Added
- **Waving Karnataka flag** (yellow over red) next to the FinBalance name wherever the full logo is shown (app bars, profile selection page, Settings > About). It is drawn with a lightweight painter (about 20 strips, one repaint boundary) and stands still when the system "remove animations" setting is on.
- **Fixed Income category** grouping PPF, NSC, KVP, SSS (Sukanya Samriddhi), POSS (Post Office Savings), FD, FRD (Flexi Recurring Deposit) and RD. It is one tab on the Assets screen and one expandable-style block on the Overview (the group row plus a row for each instrument, empty ones included). Existing `fixed_deposit` and `recurring_deposit` holdings are included automatically.
- **Loan types:** Home, Car, Business, Loan Against Property, Term, Education and Other loans grouped under **Loans**, plus a separate **Other Borrowings** entry. The add-liability form offers the same options. Older liabilities with other types (e.g. credit card) are shown under Other Borrowings.
- Tests: a `flutter_test_config.dart` that turns the flag animation off so `pumpAndSettle` still settles.

### Changed
- Category definitions now live in `asset_categories.dart` as groups (`assetGroups`, `liabilityGroups`, `groupOf`); standalone Fixed Deposits, Recurring Deposits and PPF tabs are replaced by Fixed Income.

## [0.18.0] - 2026-11-04

### Added
- **More asset categories:** PPF, EPF, NPS, PLI / Insurance, Bonds, Recurring Deposits and Other Assets join Mutual Funds, Stocks & ETFs, Fixed Deposits and Gold. They appear as tabs on the Assets screen and as rows in the Overview category list (single shared list in `asset_categories.dart`). Only mutual funds can be added today; the others show a "planned" empty state.

### Changed
- **Assets tabs:** "All Assets" is now the first tab, and the tab row scrolls so the selected tab (by tap, swipe or an Overview shortcut) is always in view.
- **Overview net worth card merged with the portfolio summary:** one card now shows Net Worth, Total Assets and Total Liabilities side by side (real liabilities total, no "Upcoming" label), then Invested, Current value, Profit / Loss, Return and XIRR beneath. Nothing was dropped; the separate summary card is gone.

## [0.17.0] - 2026-11-04

### Added
- **Support the Developer (Settings):** optional Ko-fi, PayPal and UPI support. UPI opens a sheet with an on-device generated QR code (`qr_flutter`), the UPI ID with a copy button, and an "Open UPI app" button. The card states that FinBalance is free with no ads or paid features and that we will try to keep it that way for as long as community support allows. Nothing is unlocked by supporting.
- **Settings button on the profile selection (start) page.** The Settings screen shows a back button when opened this way.
- **Swipe between Assets categories:** swipe left/right on the Assets tab to move between Mutual Funds, Stocks & ETFs, Fixed Deposits, Gold and All Assets.
- **Tests:** `holdings_list_card_test.dart`.

### Changed
- **Overview category list now shows every category, including empty ones** ("Nothing added yet", no amount), in a fixed order: Mutual Funds, Stocks & ETFs, Fixed Deposits, Recurring Deposits, Gold; Home Loan, Vehicle / Auto Loan, Personal Loan, Education Loan, Credit Card Due, Other Borrowing.
- **Removed the "Total Liabilities ₹0 • Upcoming" block** from the Overview net worth card.
- **Privacy policy (docs and in-app, identical):** Section 7 is now "Third-Party Services, Advertising & Voluntary Support". It states there are no ads, paid features or in-app purchases, the intent to stay ad-free and free as long as support allows (not a guarantee), that support links open externally, that no payment data is seen or stored, and that the UPI QR is generated on-device.
- Android: `<queries>` entry for the `upi` scheme.

## [0.16.0] - 2026-11-04

### Added
- **Category breakdown on the profile Overview:** below the charts, active assets and liabilities are grouped by category (Mutual Funds, Stocks & ETFs, Fixed Deposits, Gold, Home Loan, Personal Loan, ...) with item count and total per category, plus a total for Assets and for Liabilities. Tapping an asset category opens the Assets tab on that category; a liability category opens the Liabilities tab (shared `mainTabProvider` / `assetsCategoryRequestProvider`).
- **Automatic NAV refresh once per launch** when due under the NAV refresh setting (daily / weekly / manual). Previously the setting only controlled the manual button and no automatic refresh ran.
- **Tests:** `nav_cache_test.dart` (history downloaded once, fresh cache never hits the network, manual policy).

### Fixed
- **Developer Portfolio and Hosted Policy links** (Settings and Privacy Policy screens) now open in the browser via `url_launcher` instead of only showing a toast; a toast is shown only if the link cannot be opened. Added the Android `https` `<queries>` entry.
- **Missing NAV for old SIPs / back-dated transactions:** the scheme cache was returned whenever a latest NAV existed, so full history was never downloaded for a scheme first cached through search, the transaction form or a refresh. Full history is now downloaded once per scheme (tracked in app settings) whenever a caller needs it, including the transaction form and the "Retry" valuation button on SIP details.
- **Stale detail cache:** scheme details were served from cache forever; they now respect the refresh policy (fresh cache is served without any network call, a due cache is refreshed with the latest NAV only, and a failed refresh falls back to the cache).
- **Android build warning:** `compileSdk` raised from 35 to 36 (required by `url_launcher_android`); `targetSdk` stays 35.
- **Scheme search** now keeps locally known schemes (e.g. old or closed funds) that the online provider does not list, instead of dropping them whenever the provider returns any result.

## [0.15.0] - 2026-11-04

### Added
- **Portfolio summary card on the profile Overview:** a card above the charts shows, for all active assets of the selected profile, Invested, Current value, Profit / Loss, Return % and XIRR, so the profile can be read at a glance without opening each asset. Computed on-device from existing holdings and transactions (no new data or network use).

## [0.14.0] - 2026-11-04

### Added
- **Frequency & Number of Installments on the Transaction Form (`AddInvestmentTransactionScreen`):** choosing *SIP Investment* or *SWP Withdrawal* now shows Frequency (all frequencies except One Time) and Number of Installments, with a live summary such as "Records this installment now and plans 11 more monthly SIP installments, the last on 04 Oct 2027".
  - 1 installment records just this entry.
  - More than 1 records the entry as installment #1 and plans the rest: it adds a schedule period to the linked SIP (or the holding's active SWP), or creates a new SIP / SWP for the holding when none exists. Everything is saved in one database transaction.
- **SWP withdrawals update the schedule (`SwpsDao.linkTransactionToInstallment`):** a recorded SWP withdrawal ticks off the nearest upcoming SWP installment (within 31 days) and the transaction carries the SWP plan id, mirroring the SIP behaviour from 0.13.0.
- **Market-aware transaction form for Indian mutual funds:**
  - Charges hint per type: stamp duty is typically 0.005% on purchases, SIP and switch-in (with the computed amount); exit load, STT (0.001% on equity funds) and TDS on redemption, SWP and switch-out; TDS on IDCW payout.
  - NAV helper reminds that the applicable NAV follows the fund cut-off (usually 3 PM).
  - "All" button on the units field for redemption, SWP and switch-out fills the exact units held.
  - Auto-calculated units now use 3 decimals, as allotted by registrars.
- **Tests:** `sip_swp_transaction_form_test.dart` (frequency/installment fields, long SIP name, 3-installment SIP, 2-installment SWP).

### Fixed
- **Long SIP names overflowed** the "Linked SIP" dropdown; it now expands to the field width with an ellipsis. The dropdown label is shortened to "Linked SIP".
- **"Transaction Type" row overflowed** on narrow phones (about 360 px wide).
- Help text for SIP and SWP types now describes frequency and installments.

### Notes
- Not added: STP (systematic transfer between schemes), bonus units and capital-gains tax reporting. STP would need its own schedule model; see the README roadmap.

## [0.13.1] - 2026-11-04

### Changed
- **Android toolchain upgrade:** Gradle 8.14 -> 9.3.1, Android Gradle Plugin 8.11.1 -> 9.1.0, Kotlin 2.2.20 -> 2.4.0 (the versions shipped by the installed Flutter 3.47 template). This clears Flutter's "support will soon be dropped" warnings.
- **Built-in Kotlin:** `android/app/build.gradle` no longer applies `kotlin-android`; `kotlinOptions` replaced by `kotlin { compilerOptions { jvmTarget = JVM_17 } }`; the `android.builtInKotlin=false` opt-out was removed from `android/gradle.properties`.

### Removed
- Unused Kotlin-DSL duplicates `android/build.gradle.kts`, `android/settings.gradle.kts` and `android/app/build.gradle.kts` (Gradle already ignored them in favour of the Groovy files, which carry the real config: `com.finbalance.app`, desugaring). This clears the "Both build.gradle and build.gradle.kts exist" warning.

### Testing
- Verified with a clean `make build-debug` (no warnings) and `make build-release`. `android.newDsl=false` and `android.enableJetifier=true` are still set in `gradle.properties`; revisit when AGP drops them. No app code changed in this version.

## [0.13.0] - 2026-11-04

### Added
- **Investment Lifecycle Overview & Timeline (`InvestmentLifecycleCard`):**
  - Overview strip with status (`SIP running`, `SWP running`, `SIP + SWP running`, `Holding`, `Fully redeemed`), held-for duration, and key totals (invested, value, units; SIP installments, withdrawn and dividends when present).
  - Dated timeline with icons and clearer wording: `SIP started`, `SIP revised`, `SIP stopped / completed`, `SWP started`, `Redemption`, `Dividend received`, `Switched in / out`.
  - SIP installments roll up into one line per schedule period (count, amount, units) instead of being listed as "One-time investment". A period revised the next day no longer shows a separate "stopped" event.
  - New `InvestmentLifecycleSummary.buildTimeline` and `buildOverview`; `generateLifecycleEvents` and `generateSummary` now build on them.
- **SIP Transactions Update the Schedule (`SipsDao.linkTransactionToInstallment`):** recording a SIP Investment in the transaction form marks the nearest upcoming installment (within 31 days) of the chosen SIP as recorded, in the same database transaction.
- **Historical NAV Prefill on the Transaction Form:** NAV follows the transaction date (NAV on or before that date, falling back to the latest cached NAV) with an "NAV as of …" note. A NAV the user typed is never overwritten.
- **Privacy Policy wording (`docs/privacy-policy.md` and `PrivacyPolicyScreen`, kept word-for-word identical):** Section 4 now states that historical NAV rates are downloaded to value past investment dates. No new data is collected or transmitted; requests still carry only public scheme codes.
- **Regression tests:** `schedule_range_cap_test.dart` and `sip_transaction_link_test.dart`.

### Changed
- **Minimal SIP Schedule Cards (`SipCard`):** name, scheme, status and one line `SIP · ₹1,000.00 · Next: 05 Dec 2026`. Edit, Delete, Details buttons and installment/valuation metrics removed; tapping opens the details page.
- **Floating `+` on SIP Details:** the Add Transaction button (Transactions tab and app-bar menu) is replaced by a floating `+` available on all three tabs, with bottom padding so it never covers content.
- **Less Imposing Overview:** SIP and SWP sections each use a single `⋯` menu (New/Set up, Edit, Close period) instead of several buttons; large "Set Up…" buttons removed; the app-bar menu keeps only Edit Holding and Delete. Retry for installments awaiting a historical NAV moved into the SIP section.
- **Add SIP Dialog (`AddSipDialog`) Rebuilt:** one form (scheme, amount, frequency, start date, installments) on the same `createInvestmentSchedule` flow as "Add to profile". The start date is the first deduction date; past installments are valued from the historical NAV and added to the holding; NAV history is fetched first and anything without a NAV stays `pending_valuation`. Replaces the Ongoing / Bulk Historical tabs, which created SIPs with no holding link and no units.
- **Transaction Form:** no invented defaults (amount, NAV and units start empty); single Save button.

### Fixed
- **Daily schedules with only an end date** were truncated at 360 dates; they now run to the end date.
- **Invented NAV:** the ₹100 fallback in `TransactionsDao` and the ₹0 / mixed fallbacks in `SipsDao` are gone. With no known NAV a holding is valued at cost.
- **`deleteSwpCascade`** relied on redundant manual steps (and relabelled skipped/cancelled installments as recorded); it now deletes the plan and lets foreign keys cascade.

### Refactored
- One `_applyToHolding` helper replaces five copies of the holding units/invested/valuation update in `SipsDao`.
- `calculateHoldingXirr` and `calculatePortfolioXirr` share one implementation (portfolio skips linked switches).
- `InvestmentScheduleService` uses a single step-based occurrence helper for all frequencies.
- Removed unused `getSipsByFinancialItem`, `getUpcomingInstallmentsForProfile`, `getInstallmentsByPlan` (tests use `getInstallments`) and an unreachable branch in `deleteSip`.

### Testing
- Updated widget and lifecycle tests for the new UI and wording. Full suite: **180 tests passing**, `flutter analyze` clean.

## [0.12.0] - 2026-11-03

### Added
- **Standardized 8 Frequency Options Across SIP and SWP (`ScheduleFrequency`):**
  - Unified enum: One Time (`oneTime`), Daily (`daily`), Weekly (`weekly`), Fortnightly (`fortnightly`), Monthly (`monthly`), Quarterly (`quarterly`), Half-Yearly (`halfYearly`), and Yearly (`yearly`).
  - High-precision date range calculation in `InvestmentScheduleService.generateScheduleDatesRange` with month-end clamping (Jan 31 $\to$ Feb 28 $\to$ Mar 31) and leap-year preservation (Feb 29 $\to$ Feb 28 $\to$ Feb 29) eliminating progressive date drift.
- **Derived Deduction Date from Start / Effective Date:**
  - Removed duplicate deduction day input fields from `AddSipSchedulePeriodScreen`, `EditSipScheduleScreen`, and `AddSwpSchedulePeriodScreen`.
  - Start Date serves as the authoritative first scheduled deduction date, clearly indicated with dedicated UI banner info.
- **Explicit Separation of One-Time Investment vs. SIP Investment:**
  - Added segmented selection to `AddToProfileDialog`.
  - One-time investments record a single authoritative purchase transaction with zero recurring schedule overhead.
  - SIP investments enforce mandatory installment count or end date, strictly isolating planned future installments from current capital, units, and cash flow.
- **Systematic Withdrawal Plan (SWP) Management:**
  - SQLite schema expansion (Schema Version 5): Added `swp_plans`, `swp_schedule_periods`, and `swp_installments` tables with cascading deletion and migration safety.
  - Implemented `SwpsDao` with multi-period lifecycle management (`createSwpWithPeriod`, `addSchedulePeriod`, `closeSchedulePeriod`, `deleteSwpCascade`).
  - Added `AddSwpSchedulePeriodScreen` supporting both Amount per installment and Units per installment modes across all 8 frequencies.
  - Future planned SWP withdrawals never reduce units or current holding valuation until confirmed as transactions.
- **Minimal SIP & SWP Schedule Card Display:**
  - Replaced verbose cards with concise, distraction-free cards: `SIP · ₹1,000 · Next: 05 Dec 2026` or `SWP · 25.0000 Units · Next: 05 Dec 2026`.
  - Removed frequency text, total installment counts, and card-level delete buttons.
  - Dedicated header actions: Add New Period, Edit Period, and Close Period.
- **Contextual Help on Transaction Form:**
  - Added "Explain Types" (`?`) button on `AddInvestmentTransactionScreen`.
  - Responsive modal bottom sheet providing concise, financially accurate explanations for all 8 supported transaction types: One-time Investment, SIP Investment, IDCW Reinvestment, IDCW Payout, Redemption, SWP Withdrawal, Switch Out, and Switch In.
- **Two Distinct Overview Sections (Investment Lifecycle & My Remarks):**
  - **Investment Lifecycle:** Point-wise, chronological event narrative of initial investment, schedule revisions, SWP start/close, redemptions, switches, and dividends (`InvestmentLifecycleSummary.generateLifecycleEvents`).
  - **My Remarks:** Dedicated point-wise user notes with subtle empty prompt (`No remarks added. Tap to add notes.`) and independent editing dialog.
- **Switch Transaction Destination Scheme Search & Catalog Integration:**
  - Live mutual fund catalog search modal (`_SchemePickerSearchDialog`) in `AddInvestmentTransactionScreen`.
  - Displays selected scheme name, fund house, latest NAV, and portfolio holding status.
  - Automatically links to existing holding or creates a new active holding record with ₹0 initial capital contribution (preventing double-counting).
  - Atomically generates linked Switch Out and Switch In transaction legs with clear "Switched out to [Scheme]" and "Switched in from [Scheme]" notes.

## [0.11.0] - 2026-11-03

### Added
- **Dedicated Investment Details Page with 3 Separate Tabs (`SipDetailsScreen`):**
  - **Tab 1: Overview:**
    - Live financial summary: Total Invested, Current Valuation, Profit/Loss, Absolute Return (%), and annualized XIRR/IRR.
    - Investment information card: Scheme Name, AMC/Fund House, Category, Units Held, Latest NAV with date, Start Date, and Owning Profile.
    - SIP Schedule Periods section displaying multi-period investment history, ongoing frequency, and active/closed period statuses.
    - Investment Remarks & Lifecycle Narrative: Distinguishable auto-generated lifecycle summary (`InvestmentLifecycleSummary`) and independently editable user notes dialog.
  - **Tab 2: Transactions:**
    - Complete authoritative transaction log supporting 9 investment transaction types: One-time Purchase (`investment_purchase`), SIP Investment (`sip_investment`), IDCW Reinvestment (`dividend_reinvestment`), IDCW Payout (`dividend_payout`), Redemption (`redemption`), SWP Withdrawal (`swp_withdrawal`), Switch In (`switch_in`), Switch Out (`switch_out`), and Adjustments.
    - Inflow and outflow directional badges and indicators, execution NAV, units allotted/redeemed, charges, and net cash flow amount.
    - Horizontal transaction filter pills (`ALL`, `PURCHASES`, `SIP`, `DIVIDENDS`, `REDEMPTIONS`, `SWP`, `SWITCHES`).
    - Direct shortcut button to record a new transaction.
  - **Tab 3: Performance History:**
    - Dedicated valuation trajectory chart ($\text{units at date} \times \text{NAV at date}$) using FL Chart.
    - Time-range selector chips (`1M`, `3M`, `6M`, `1Y`, `ALL`).
    - Touch-responsive tooltips displaying formatted date and valuation in INR.
    - Clean empty state view when fewer than 2 NAV data points exist.
- **Full-Screen Edit Holding Page (`EditHoldingScreen`):**
  - Replaces modal dialog with full-screen route including AppBar, dismiss confirmation, and Save action.
  - Form validation with two-way sync: Invested Cost $\leftrightarrow$ Units Held based on purchase NAV.
  - Financial calculations impact notice informing user that edits update portfolio valuation and cash flow metrics.
- **Full-Screen Edit SIP Schedule Page (`EditSipScheduleScreen`):**
  - Replaces modal dialog with full-screen route including original Add SIP form fields.
  - Effective date selector preserving past confirmed installments while adding new schedule periods.
- **Support for Multiple SIP Schedule Periods Under One Holding:**
  - Added `AddSipSchedulePeriodScreen` allowing multiple schedule periods (e.g. initial amount closed, new revised amount active).
  - Automatically closes previous period on the day prior to new effective date without duplicating holdings or modifying past records.
- **Full-Screen Add Investment Transaction Page (`AddInvestmentTransactionScreen`):**
  - Supports all 8+ investment transaction types with contextual fields and instructions.
  - Over-redemption guard blocking redemptions or withdrawals greater than current units held.
  - Switch pairing supporting atomic link between Switch Out and Switch In (`linkedTransactionId`).
  - Optional charges field supported across all transaction types with integer paise precision.
- **Transaction Charges & Cash Flow Engine:**
  - Upgraded Drift schema to version 4 adding `chargesPaise`, `netAmountPaise`, `sipPlanId`, and `linkedTransactionId`.
  - Updated `FinancialCalculator.calculateHoldingXirr` and `calculatePortfolioXirr` to account for charges and diverse transaction types.
- **Cleaned Profile Dashboard (`OverviewScreen`):**
  - Removed Recent Activity section from the individual profile dashboard, focusing the view on net worth, asset & liability charts, and cash flow projections.

## [0.10.0] - 2026-11-03

### Added
- **Investment List Redesign & Category Navigation (`AssetsScreen`):**
  - Added clean investment category filter navigation row (`Mutual Funds`, `Stocks & ETFs`, `Fixed Deposits`, `Gold`, `All Assets`) with dynamic item count badges and selected category highlighting.
  - Added compact portfolio summary card with live aggregate valuation, total invested cost, overall P&L (+/-%), and portfolio-wide IRR.
  - Replaced bulky cards with compact investment list cards (`HoldingCard`):
    - Prominent multiline scheme title with zero truncation or text clipping.
    - Category / fund house subtitle with colored return indicator badge.
    - Clean 3-metric row: `INVESTED`, `CURRENT VALUE`, and `IRR / P&L`.
    - Removed embedded transaction tables from cards; tapping any card now opens the dedicated full-screen details view.
  - Added compact search and filter toolbar with active profile indicator and contextual addition shortcut.
- **Dedicated Full-Screen SIP & Investment Details Page (`SipDetailsScreen`):**
  - Created dedicated full-screen page replacing cramped modal bottom sheets.
  - Custom AppBar featuring multiline scheme title, fund house subtitle, interactive favourite star toggle, and overflow actions (Edit Holding, Delete Investment).
  - **Section A — Investment Overview:**
    - Hero valuation display with overall P&L badge and cached NAV disclaimer.
    - 2x2 metric grid: Total Invested, Current Valuation, Absolute Return (%), and Current IRR / XIRR.
    - Holding details strip: Units held, latest NAV, NAV date, and owning profile.
  - **Section B — Historical Performance Chart:**
    - Interactive FL Chart `LineChart` showing portfolio value trajectory over time ($\text{units at } d \times \text{NAV at } d$) calculated from dated transactions.
    - Filter pills (`1M`, `3M`, `6M`, `1Y`, `ALL`) with responsive wrap layout.
    - Touch tooltips displaying formatted date and valuation in INR.
    - Graceful empty state when fewer than 2 NAV data points are available.
  - **Section C — Transaction History:**
    - Chronologically sorted transactions (newest first).
    - Distinct visual indicators and badges for purchase (`+`) and redemption (`-`).
    - Exact breakdown of transaction amount, NAV at execution, units allotted, and transaction date.
  - **Section D — SIP Investment Schedule:**
    - Master SIP schedule card with installment amount, deduction frequency, start date, next installment date, and owning profile.
    - Installment breakdown grouped into four distinct categories with dedicated badges:
      - Confirmed & valued installments (`asset` badge).
      - Historical installments pending NAV valuation (`warning` badge).
      - Planned future installments (`scheduled` badge, clearly isolated from net worth/valuation).
      - Skipped or cancelled installments (`neutral` badge).
    - Quick actions: Edit Schedule, Retry Pending Valuations, and Cancel Future Installments.
- **Shared Financial Calculation Engine (`FinancialCalculator`):**
  - High-precision calculation layer for investment analytics:
    - `calculateAbsoluteReturn`: Exact percentage gain/loss on invested capital.
    - `calculateProfitLossPaise`: Absolute profit or loss in integer paise.
    - `calculateXirr`: Newton-Raphson solver for Internal Rate of Return (IRR / XIRR) based on exact dated cash flows (`DatedCashFlow`).
    - `calculateHoldingXirr` & `calculatePortfolioXirr`: Real-world transaction cash flows combined with terminal valuation.
    - Strict mathematical preconditions: Returns `null` (displayed as `—`) for invalid cash flows or holding durations under 1 day.
- **Layout & Rendering Bug Fixes:**
  - Resolved Flutter debug layout overflow banner ("RenderFlex overflowed by 15 pixels") by wrapping flex children in `Expanded`, replacing oversized headline typography with `titleLarge`, and utilizing `Wrap` for metadata chips and action bars.
  - Fixed unbounded width constraint exceptions in `SectionHeader` and time range selectors.
  - Fixed reactive NAV history fetching by introducing Riverpod's `schemeNavHistoryRangeProvider`, preventing infinite rebuild loops during chart rendering.

### Testing
- Added `test/unit/financial_calculator_test.dart` verifying lump sum growth, SIP cash flows, zero-invested edge cases, and invalid cash flow handling.
- Added `test/widget/investment_redesign_and_sip_details_test.dart` testing the category navigation, portfolio summary, compact holding cards, and full-screen `SipDetailsScreen` with all 4 sections.
- Verified all 150 automated tests passing with 0 errors.

---

## [0.9.1] - 2026-11-03

### Added
- **Unified Financial Category Chart & Switcher (`OverviewScreen`):**
  - Added a third, unified financial category distribution chart (`Assets & Liabilities by Category`) combining assets and liabilities into one comprehensive chart view.
  - Made `Assets & Liabilities by Category` the default chart shown when opening the dashboard.
  - Added interactive 3-option chart switcher: `Assets & Liabilities` (0), `Cash Flow` (1), and `Portfolio Assets` (2), persisted to Drift database via `AppSettingsDao` (`dashboard_selected_chart`).
  - Standardized canonical financial category names via `FinancialCategoryConstants`:
    - **Asset Categories:** Mutual Funds / SIP, Stocks, ETFs, Fixed Deposits (FD), Recurring Deposits (RD), PPF, EPF, GPF, NPS, Gold, Bonds, Bank Balance, Cash, Other Assets.
    - **Liability Categories:** Home Loan, Personal Loan, Vehicle Loan, Education Loan, Credit Card Dues, EMI / Other Loan Dues, Other Liabilities.
  - Clear visual distinction between assets (emerald green) and liabilities (crimson rose).
  - Clean display of actual amounts and category names with automatic exclusion of zero-value slices from the pie chart.
  - Liabilities displayed with ₹0 totals and canonical category preview chips when empty, avoiding fake or placeholder balances.
  - Excluded future planned SIP installments and prevented double-counting.
- **Dedicated Support Section (`SettingsScreen`):**
  - Added dedicated "Support" section before "About" in Settings.
  - Provided direct link to Developer Portfolio (`https://amruthlp.vercel.app`).
  - Provided direct link to Privacy Policy screen.
  - Added contact placeholder: `"Contact details will be provided here."` without dead or fabricated links.
  - Preserved developer attribution ("Built by Amruth L P", `v1.0.0`) in the About card.
- **Privacy Policy Revisions & Synchronization (`docs/privacy-policy.md` & `PrivacyPolicyScreen`):**
  - Removed Section 13 (Open Source & Transparency) and standalone Section 14 (Contact Information).
  - Removed point 3 under Section 11 referencing CHANGELOG.md and release notes.
  - Removed all references to Git repositories, source code repositories, changelogs, and open-source contribution workflows.
  - Added "Financial Data Accuracy & Market Delays" section explaining informational purposes, market NAV delays, difference from transaction execution prices, and lack of transaction execution capabilities.
  - Revised Advertising disclosure to accurately reflect current application behavior without making promises about future advertising or services.
  - Added structured Support section with developer portfolio and hosted policy document links (`https://amruthlp.vercel.app/finbalance_policy`).
  - Renumbered remaining sections consistently from 1 to 14.
  - Maintained 100% word-for-word synchronization between `docs/privacy-policy.md` and `PrivacyPolicyScreen`.
- **UI Responsiveness:**
  - Resolved horizontal RenderFlex overflow issues across `OverviewScreen` headers and metric rows on narrow screens with `SingleChildScrollView` and `Wrap` layouts.

### Testing
- Updated `test/widget/category_charts_and_policy_test.dart` to verify the 3 switchable chart modes, default unified category chart, canonical category labels, revised 14-section Privacy Policy structure, and Settings Support section.
- Updated `test/widget/profile_overview_and_cashflow_test.dart` to verify default `Assets & Liabilities by Category` chart and mode switching to `Portfolio Assets`.
- Total automated test suite passing with **143 tests** (0 failures).

---

## [0.9.0] - 2026-11-03

### Added
- **Asset & Liability Distribution Dashboard (`OverviewScreen`):**
  - Added dedicated "Asset & Liability Distribution" section on the individual profile dashboard with an interactive segmented switch (`[Assets | Liabilities]`).
  - Donut chart visualization powered by `fl_chart` for profile assets grouped by category (Mutual Funds, Stocks, Gold, Fixed Deposits, NPS, PPF, EPF, GPF, Bonds, Cash & Bank, Other Assets).
  - Clear, responsive legend with colored category indicators, category names, INR-formatted amounts (`CurrencyFormatter.formatPaise`), and percentage allocations.
  - Interactive touch response scaling tapped slice radius for inspection.
  - Visually isolated liability distribution card showing `Total Liabilities: ₹0`, StatusBadge "Coming in a future milestone", and planned liability category preview tags (Home Loans, Personal Loans, Vehicle Loans, Education Loans, Credit Card Dues, Other Liabilities). Zero dummy values or combined positive percentages.
  - Preserved independent Cash Flow graph completely unchanged.
- **Profile Avatar Popup Menu (`ProfileMenuButton`):**
  - Created reusable `ProfileMenuButton` replacing immediate navigation on avatar tap across Overview, Assets, Liabilities, Activity, Settings, and desktop NavigationRail.
  - Displays compact anchored popover menu with avatar initials, profile name, relationship badge, and actions: "Switch Profile", "Manage Profiles", and "Add Family Member".
  - Tapping outside cleanly dismisses the menu without unintended navigation.
  - Clickable `FinBalanceLogo` header shortcut remains dedicated to instant family profile switching.
- **In-App Privacy Policy Page (`PrivacyPolicyScreen`):**
  - Added dedicated, comprehensive 15-section Privacy Policy screen accessible from Settings.
  - Formatted without any mentions of SQLite or specific API provider names.
  - Clearly explains local-first on-device database architecture, zero telemetry/analytics SDKs, zero user tracking, and network usage strictly limited to public AMFI mutual fund NAV rates with zero personal data transmission.
- **Standalone Markdown Privacy Policy Document (`docs/privacy-policy.md`):**
  - Created canonical markdown policy document at `docs/privacy-policy.md` matching in-app wording.
  - Added developer and hosting documentation in `README.md` for public deployment at `https://amruthlp.vercel.app/finbalance_policy`.
- **Developer Information in Settings (`SettingsScreen`):**
  - Added "Built by Amruth L P", version `v1.0.0`, developer portfolio link `https://amruthlp.vercel.app`, and Privacy Policy navigation tile to Settings About card.
  - Removed internal SQLite references from user-facing About card copy.
- **Mutual Fund Search Minimum 3 Characters & Reset:**
  - Enforced minimum 3 characters threshold in `schemeSearchResultsProvider` and `MutualFundSearchScreen` before issuing search requests.
  - Displayed informative hint state "Enter at least 3 characters to search" when query length is 1-2 characters.
  - Clearing search input immediately cancels debounce timer and resets results to empty.
- **UI Polish & Provider Neutrality:**
  - Removed duplicate favourite star icon button beside "Add to Portfolio Assets" button in `SchemeDetailsSheet`, keeping the single prominent star in the header.
  - Converted `+ Add Profile` text button on `ProfileSelectionScreen` into a compact icon button (`IconButton(icon: Icon(Icons.add_rounded), tooltip: 'Add Profile')`).
  - Removed all user-facing mentions of `MFapi` from search screens, sync subtitles, and snackbars in favor of neutral terminology ("Live Market NAV", "market data service").

---

## [0.8.0] - 2026-11-02

### Added
- **Family-Wide Financial Overview on Profile Selection (`ProfileSelectionScreen`):**
  - Redesigned opening startup/profile switching screen with a top family-wide financial overview card aggregating Total Family Assets, Liabilities (`₹0 • Upcoming`), and Family Net Worth ($Assets - Liabilities$) across all member profiles.
  - Replaced redundant "Quick Continue as" card and "Last Used" / "Default" badges with clean, scannable profile cards showing initials avatar, display name, relationship label, profile assets, liabilities, and profile net worth.
  - Completely removed unnecessary top-right close `X` icon to preserve navigation hierarchy.
- **Global Android Back Navigation Flow (`MainScaffold`):**
  - Integrated `PopScope` on `MainScaffold` ensuring Android Back switches to Overview (tab 0) before returning to the Profile Selection screen.
  - Preserved standard stack popping from nested modals, search, holding details, and settings back to previous screens; only root profile selection screen permits platform app exit.
- **Clickable FinBalance Logo Header Shortcut:**
  - Removed separate `ReturnToProfilesButton` / `ProfileSelectorButton` in app headers.
  - Transformed the `FinBalanceLogo` in the main header into an intuitive clickable shortcut with tooltip "Switch Family Profile" to immediately return to the profile switcher.
  - Added compact `ProfileAvatar` displaying the active profile's initial in the AppBar actions.
- **Standardized Profile Avatar (`ProfileAvatar`):**
  - Standardized `ProfileAvatar` to consistently display the uppercase first letter of the profile name across all screen sizes and themes.
  - Added deterministic high-contrast color palette generation based on profile name hash with custom `colorHex` fallback.
  - Added `ProfileAvatar.active({double radius = 18})` Consumer helper for displaying the active profile.
- **Individual Profile Dashboard Redesign (`OverviewScreen`):**
  - Added Asset Category Allocation donut chart powered by `fl_chart` with interactive percentage badges, readable sorted legend, and clean empty state.
  - Removed redundant "Active Assets" StatCard, "Liabilities" StatCard, and redundant "Holdings" list cards.
  - Added Recent Investment Activity ledger stream displaying the 5 most recent profile transactions.
- **SIP Cash Flow Integration (`ActivityScreen`):**
  - Fixed critical omission where Cash Flow analysis only tracked `income` and `expense` types, ignoring `investment_purchase`.
  - Added confirmed SIP contributions and mutual fund purchases as investment outflows ($Total Outflow = Expenses + Investment Outflow$, $Net Cash Movement = Income - Total Outflow$).
  - Added dedicated Investment Outflows summary card and categorized breakdown section in Cash Flow view.
- **Granular Asset Categories & Migration (`AppDatabase`):**
  - Replaced generic "Retirement" category with specific categories: PPF, EPF, GPF, NPS, Bonds, and Other Assets.
  - Implemented automatic non-destructive migration routine `_migrateRetirementCategory()` in `beforeOpen` remapping legacy retirement items by subType/name.
  - Updated category filter chips and holdings filters in `AssetsScreen`.
- **SIP Detail Popup Layout & Post-Save Redirect:**
  - Responsive `Wrap` layouts in `SchemeDetailsSheet` and `AddToProfileDialog` preventing horizontal overflow on long scheme names or NAV cards on narrow mobile screens.
  - Auto-switches active profile and pops back to the primary workspace root (`Navigator.popUntil((route) => route.isFirst)`) after saving an investment schedule with success SnackBar.

### Testing
- Added `test/widget/profile_overview_and_cashflow_test.dart` (4 tests verifying family overview calculation, category allocation chart, SIP cash flow integration, and asset category migration).
- Updated `test/widget/app_smoke_test.dart`, `test/widget/contextual_fab_and_navigation_test.dart`, `test/widget/profile_selection_startup_test.dart`, and `test/widget_test.dart`.
- Total automated test suite expanded to **138 passing tests** (0 failures).

## [0.7.0] - 2026-11-02

### Added
- **SIP Cascade Deletion & Financial Consistency Engine (`SipsDao`):**
  - Atomic `deleteSip(int sipPlanId)` executed inside a Drift database transaction (`transaction(() async { ... })`).
  - Completely cascades across SIP schedule periods, generated installments (historical, upcoming, simulated, and pending valuation), and exclusively linked investment transactions.
  - Recalculates or cleans up linked holdings (`FinancialItems`): decrements units and invested capital using `FinancialPrecision`. If no other SIPs or transactions exist, automatically removes the holding.
  - Added individual installment deletion `deleteInstallment(int installmentId)` removing linked transactions and updating holding units/valuation.
  - Added `cancelFutureInstallments(int sipPlanId)` cancelling upcoming occurrences and stopping the SIP plan while strictly preserving historical investments and accumulated units.
  - Added `deleteHoldingCascade(int holdingId)` in `FinancialItemsDao` cascading deletion across all linked SIPs, installments, and holding transactions.
  - Absolute preservation of shared reference data: never deletes master mutual fund schemes (`MutualFundSchemes`) or historical NAV entries (`NavHistory`).
  - Added confirmation dialogs across UI (`SipCard`, `SipInstallmentsSheet`, `HoldingDetailsSheet`, `AssetsScreen`) detailing scheme name, profile name, installment count, and confirmed transaction amounts.
- **Milestone Scope Control (Liabilities):**
  - Converted Liabilities section into a full-width, polished placeholder UI explaining liability tracking is planned for an upcoming milestone.
  - Showcases planned categories: Home Loans, Personal Loans, Vehicle Loans, Education Loans, Credit Card Dues, and Other Liabilities.
  - Excluded liabilities from Net Worth calculation across Overview dashboard and asset-only balance sheet calculations.
  - Removed liability addition forms and triggers from navigation and FAB.
- **Milestone Scope Control (Manual Transactions):**
  - Restricted transaction generation strictly to supported investment workflows (SIPs).
  - Removed manual transaction addition buttons and dialog triggers from `MainScaffold` and `ActivityScreen`.
  - Context-aware FAB restricted to investment workflows on Overview and Assets tabs; suppressed on Liabilities, Activity, and Settings tabs.
- **Persistent Theme Selection (`ThemeModeNotifier`):**
  - Implemented `ThemeModeNotifier` backed by Drift's `AppSettingsDao` (`'theme_mode'` key).
  - Connected Settings theme picker to switch between System, Light, and Dark modes with instant reactive update and persistent cold-start restoration.

### Testing
- Added `test/unit/sip_cascade_deletion_test.dart` (3 tests verifying atomic SIP deletion, multi-SIP holding retention, and profile isolation).
- Added `test/unit/installment_lifecycle_test.dart` (4 tests verifying individual installment deletion, upcoming deletion, skip/cancel status, and future installment cancellation).
- Added `test/unit/scope_control_and_theme_test.dart` (3 tests verifying theme persistence via `AppSettingsDao`, milestone net worth calculation, and holding cascade deletion).
- Updated `test/widget/contextual_fab_and_navigation_test.dart` to match milestone scope control rules.
- Total automated test suite expanded to **134 passing tests** (0 failures).

## [0.6.0] - 2026-11-02

### Added
- **Mobile UX Overhaul for Investment Addition Forms (`AddToProfileDialog`):**
  - Converted dialog to edge-to-edge mobile page (`Scaffold` with persistent top AppBar).
  - Placed Save action in persistent top-right AppBar header, maintaining accessibility when the soft keyboard is open or during long scrolls.
  - Enforced single-column layout on mobile viewports with zero cramped corner gaps or horizontal overflow.
  - Reorganized field hierarchy: Mutual Fund Scheme $\rightarrow$ Amount per installment $\rightarrow$ Start Date $\rightarrow$ Frequency $\rightarrow$ Number of Installments $\rightarrow$ Profile $\rightarrow$ Notes.
  - Real-time non-overlapping schedule calculation card with breakdown of past actual vs future planned capital.
  - Collapsible installment preview (`ExpansionTile`) showing upcoming deduction dates and amounts.
- **Top-Left Return to Profile Selection (`ReturnToProfilesButton`):**
  - Dedicated top-left action with `Icons.switch_account_rounded` integrated across Overview, Assets, Liabilities, Activity, and Settings screens.
  - Toggles `hasSelectedInitialProfileProvider.state = false` returning to the family member selector without deleting, disconnecting, or clearing active profile data.
  - Added dismiss button in `ProfileSelectionScreen` when an active profile exists, allowing users to return to dashboard immediately if opened accidentally.
- **Context-Aware Circular Floating Action Button (`+`):**
  - Replaced the large "Add Mutual Fund" text FAB with a compact circular `+` button in `MainScaffold`.
  - Contextual behavior based on current active tab:
    - Overview (0): Quick financial actions bottom sheet (Add Mutual Fund, Add Liability, Record Income, Record Expense).
    - Assets (1): Asset actions bottom sheet (Mutual Fund Schedule, Other Asset classes).
    - Liabilities (2): Direct launch of mobile-optimized `AddLiabilityDialog`.
    - Activity & Cash Flow (3): Transaction actions bottom sheet (Add Income, Add Expense, Add Transfer).
    - Settings (4): Suppressed (`floatingActionButton: null`).
- **Settings-Only Centralized NAV Synchronization:**
  - Removed all sync triggers and refresh icons from Overview AppBar, Assets AppBar, Mutual Fund cards, and detail sheets.
  - Consolidated all sync operations in Settings: Refresh Policy (`Daily`, `Weekly`, `Manual`), Sync Schedule Status (`Last sync: ... • Next eligible: ...`), and `Sync Now` manual trigger.
  - Detailed sync execution status: Displays updated schemes count, primary provider (`MFapi`), and granular error details on failure.
- **Unified Activity Ledger & Filter System (`ActivityScreen`):**
  - Connected directly to Drift database via `TransactionsDao`.
  - Multi-dimension filter bar: Type (All, Income, Expense, Investment, Transfer), Date Presets (All, Today, This Month, Last Month, Custom Date Range), and Category filter with quick Reset.
  - Live summary metrics: Total Income, Total Expenses, Investments, Net Cash Movement.
  - Detailed transaction card and drill-down bottom sheet with delete confirmation dialog.
- **Dedicated Cash Flow Analysis (`ActivityScreen` Tab 2):**
  - Period selector: This Month, Last Month, 3 Months, 6 Months, This Year, Custom Date Range.
  - Metric summary: Total Inflow, Total Outflow, Net Cash Flow, Savings Rate (`(Income - Expenses) / Income * 100%`).
  - Proportional category breakdown bars for Income Sources and Expense Breakdown (sorted descending by expenditure).
  - Quick action shortcuts: "Add Income" and "Add Expense".
  - Strict exclusion: Internal transfers between user accounts are strictly excluded from income and expense calculations.

### Testing
- Added `test/unit/mobile_form_ux_test.dart` (3 tests verifying persistent top Save buttons, field order, mobile scrollability, and form validation).
- Added `test/unit/activity_and_cash_flow_test.dart` (4 tests verifying income/expense calculations, savings rate, transfer exclusion, transaction deletion, and category grouping).
- Added `test/widget/contextual_fab_and_navigation_test.dart` (3 tests verifying contextual circular FAB, ReturnToProfilesButton navigation, and Settings-only NAV refresh).
- Total automated test suite expanded to **124 passing tests** (0 failures).

## [0.5.0] - 2026-11-02

### Added
- **Redesigned Mutual Fund Investment Schedule Form (`AddToProfileDialog`):**
  - Replaced manual single lumpsum entry with automated investment schedule generator.
  - Configurable fields: Mutual Fund Scheme header with latest NAV and date, Financial Profile selector, Amount per installment, Start Date picker, Frequency selector (Daily, Weekly, Monthly, Quarterly, Yearly, One-time), Number of Installments (automatically locked to 1 for One-time), Description/notes, and Confirmed vs Estimated toggle.
  - Live dynamic schedule calculation card: Real-time projection of schedule end date, total installments, past actual count and amount, future planned count and amount, and total scheduled capital.
- **Reusable Investment Schedule Service (`InvestmentScheduleService`):**
  - High-reliability recurring date calculator supporting daily, weekly, monthly, quarterly, yearly, and one-time schedules.
  - Zero progressive date drift with leap-year aware month-end clamping (e.g. Jan 31 -> Feb 28/29 -> Mar 31).
  - Dynamic local-date partitioning into Past ($\le \text{today}$) and Future ($> \text{today}$).
- **Historical NAV-Based Unit Calculation & Valuation Lifecycle:**
  - `MutualFundDao.getNavOnOrBefore`: Evaluates historical NAV applicable for each past installment date, with weekend (Saturday/Sunday $\rightarrow$ Friday) and market holiday fallbacks to the preceding trading day.
  - Missing historical NAVs are recorded as `pending_valuation` without inventing synthetic quotes.
  - Added `revaluePendingInstallments` to recover and value pending installments once historical NAV data is synced.
  - Guaranteed financial isolation: Future installments are strictly recorded as `upcoming` simulated occurrences with null units and null purchase NAV. Future amounts are never calculated using today's NAV and never added to current portfolio valuation or net worth.
  - Multi-schedule accumulation: Multiple investment schedules for the same scheme under the same profile accumulate units and invested capital into a unified holding without overwriting.
- **Investment Details & Schedule Editing:**
  - `SipCard`: Displays investment frequency, total installments, past vs future counts and amounts, confirmed invested capital, planned future investment, accumulated units, current valuation, and valuation status badge with one-tap retry for pending valuations.
  - `EditSipScheduleDialog`: Allows modifying frequency, amount per installment, and remaining installments starting on a user-specified effective date. Updates only future occurrences on or after the effective date, strictly preserving past confirmed transactions, recorded units, and historical purchase NAVs.
- **Complete Logo & Application Branding Redesign:**
  - Modern geometric fintech visual identity representing Assets (+) Emerald Green (`#10B981`), Liabilities (−) Cobalt Blue (`#2563EB`), and Net Worth Equilibrium Fulcrum Golden Amber (`#F59E0B`).
  - Android adaptive launcher vector drawables (`ic_launcher_foreground.xml`, `ic_launcher_background.xml`).
  - Generated all Android launcher mipmap densities (`mipmap-mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
  - Generated Web branding assets: `favicon.png`, `Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, and `Icon-maskable-512.png`.
  - In-app vector Flutter widget `FinBalanceLogo` with light/dark theme adaptation, scalable sizing, and optional tagline ("Assets • Liabilities • Balance").
  - Integrated `FinBalanceLogo` across `ProfileSelectionScreen`, `SettingsScreen`, and `MainScaffold`.

### Testing
- Added `test/unit/investment_schedule_calculator_test.dart` (9 tests for schedule rules, frequencies, month-end clamping, leap years, and past/future partitioning).
- Added `test/unit/historical_nav_unit_calculation_test.dart` (6 tests for exact NAV lookup, weekend fallback, holiday fallback, missing NAV graceful handling, future NAV isolation, and integer micro-precision units).
- Added `test/unit/investment_financial_accuracy_test.dart` (3 tests for past/future financial isolation, multi-schedule holding accumulation, and simulated vs confirmed status).
- Added `test/unit/schedule_editing_test.dart` (schedule updates from effective date with strict preservation of historical records and transactions).
- Added `test/unit/branding_assets_test.dart` (5 tests verifying Android mipmap files, adaptive XML drawables, web icons/favicon/manifest, and `FinBalanceLogo` widget rendering across themes).
- Total automated test suite expanded to **114 passing tests** (0 failures).

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
