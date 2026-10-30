# Document 4: agent.md

# AI Development Agent Instructions

## 1. Project Context

You are working on an offline-first Android investment tracking application.

The application is designed for users who want to maintain their own SIP and mutual fund investment records.

It does not execute investments, connect to financial institutions or verify actual bank deductions.

It automatically creates simulated SIP contributions based on user-defined schedules and estimates their value using published mutual fund NAV data.

The entire application operates locally on the Android device.

## 2. Mandatory Technology Stack

Use:

- Flutter.
- Dart.
- Riverpod.
- Drift.
- SQLite.
- Dio.
- fl_chart.
- flutter_local_notifications.

Use current stable compatible versions.

Do not introduce unnecessary technologies.

## 3. Strict Project Constraints

The following are mandatory:

1. Android-first application.
2. No backend.
3. No PostgreSQL.
4. No Docker.
5. No website requirement.
6. No cloud database.
7. No mandatory account or login.
8. No bank integration.
9. No broker integration.
10. No paid API requirement.
11. No API keys for the selected public NAV providers.
12. No mandatory background jobs or continuously running services.

All core application data must be persisted locally.

External APIs must only be used for mutual fund scheme and NAV information.

## 4. Architecture Rules

Follow the architecture defined in `architecture.md`.

Follow the database and financial calculation specifications in `essential-architecture.md`.

Do not put business logic inside UI widgets.

Do not access Drift directly from presentation widgets.

Use repositories and application services.

Keep API-specific response parsing isolated inside provider adapters.

Avoid unnecessary abstraction and excessive layers.

## 5. UI/UX Requirements

The application must have a distinctive, polished financial dashboard.

Do not use generic template-looking interfaces.

Design principles:

- Modern financial application appearance.
- Clean dark and light themes.
- Clear visual hierarchy.
- Consistent spacing.
- Good typography.
- Carefully designed data cards.
- Attractive charts.
- Responsive layouts.
- Smooth but restrained animations.
- Clear loading, empty and error states.

Avoid:

- Bootstrap.
- Excessive gradients.
- Excessive card nesting.
- Unnecessary animations.
- Overcrowded dashboards.
- Inconsistent typography.
- Hardcoded dashboard values.

All monetary values must be dynamically calculated.

Use INR formatting by default.

## 6. Financial Accuracy Rules

Financial calculations must be implemented independently of UI components.

Never confuse:

- Scheduled contributions.
- Simulated transactions.
- Actual user-entered transactions.
- Imported transactions.

Never represent an estimated portfolio as an actual verified mutual fund portfolio.

Never silently change historical transaction values when an SIP configuration changes.

Never overwrite newer NAV data with older NAV data.

Never generate duplicate scheduled contributions.

Handle invalid NAV, zero values and missing data safely.

## 7. API Integration Rules

Implement provider adapters for MFapi.in and TIGZIG.

Before implementing:

1. Inspect current provider documentation.
2. Verify actual endpoint availability.
3. Inspect real JSON responses.
4. Check provider terms and usage restrictions.
5. Validate the availability of historical NAV.
6. Verify scheme identifiers and response formats.

Do not invent API response fields.

Do not assume a provider's uptime.

Use a primary/fallback strategy.

Cache NAV data locally.

If external providers are unavailable, continue using the last saved NAV.

The application must never require external APIs just to open the dashboard.

## 8. Database Rules

Use Drift for persistence.

Requirements:

- Typed tables.
- Proper relationships.
- Unique constraints.
- Indexes.
- Database migrations.
- Atomic operations.
- Safe deletion behavior.

Do not store large historical datasets in application preferences.

Use SQLite tables for structured financial records.

## 9. State Management

Use Riverpod.

Requirements:

- Keep providers focused.
- Separate data loading from business calculations.
- Avoid unnecessary rebuilds.
- Dispose resources correctly.
- Avoid global mutable state.
- Handle asynchronous errors explicitly.

## 10. Code Quality

Follow Dart and Flutter conventions.

Requirements:

- Meaningful class and method names.
- Small, maintainable functions.
- Strong typing.
- Null safety.
- Consistent formatting.
- Reusable widgets where appropriate.
- No unnecessary dependencies.
- No duplicated business logic.

Avoid giant files.

Do not introduce complex abstractions without a real need.

Run static analysis and tests regularly.

## 11. Testing Requirements

Every important business rule must have tests.

Mandatory test cases:

### SIP scheduling

- Monthly schedules.
- Weekly schedules.
- Quarterly schedules.
- Month-end dates.
- Leap years.
- End dates.
- Paused SIPs.
- Stopped SIPs.
- Amount changes.

### Transactions

- SIP contribution.
- Lump-sum purchase.
- Redemption.
- Unit adjustment.
- Duplicate prevention.
- NAV unavailable.

### Calculations

- Units purchased.
- Total units.
- Current value.
- Profit/loss.
- Absolute returns.
- XIRR.
- Redemption calculations.

### API

- Successful NAV response.
- Invalid response.
- Timeout.
- Missing scheme.
- Missing NAV.
- Fallback provider.
- Outdated NAV.

### Persistence

- Database creation.
- Database migration.
- Data relationships.
- Backup export.
- Backup import.
- Duplicate backup records.

## 12. Documentation Maintenance

Maintain these files:

- `prod.md`
- `architecture.md`
- `essential-architecture.md`
- `agent.md`
- `CHANGELOG.md`
- `README.md`

Whenever implementation changes affect requirements, architecture, database design or development conventions, update the relevant documentation.

Every completed feature or bug fix must be recorded in `CHANGELOG.md`.

Do not allow the documentation to become outdated.

## 13. Development Workflow

Before implementing a feature:

1. Inspect the existing project structure.
2. Read all relevant documentation.
3. Inspect existing implementation.
4. Identify affected modules.
5. Prepare an implementation plan.
6. Implement the feature.
7. Add or update tests.
8. Run static analysis.
9. Run relevant tests.
10. Update documentation.
11. Update CHANGELOG.md.

Do not rewrite existing working features unnecessarily.

Do not make unrelated changes.

Do not remove existing user data during migrations.

## 14. Build and Verification

Provide working Android debug and release builds.

Suggested Makefile commands:

```makefile
.PHONY: get analyze test build-debug build-release clean

get:
	flutter pub get

analyze:
	flutter analyze

test:
	flutter test

build-debug:
	flutter build apk --debug

build-release:
	flutter build apk --release

clean:
	flutter clean
```

Do not claim a build or test succeeded unless it was actually executed successfully.

## 15. Completion Report

At the end of each completed task, provide:

1. Summary of changes.
2. Files created or modified.
3. Features implemented.
4. Tests executed and their results.
5. Outstanding issues.
6. Documentation updated.
7. Suggested Git commit message.

Always include a suggested conventional commit message.

Example:

```text
feat(sip): implement automatic scheduled contributions
```

## 16. Final Development Principle

Build a reliable investment tracker, not a trading platform.

Prioritize:

1. Financial calculation correctness.
2. Data integrity.
3. Offline reliability.
4. NAV data reliability.
5. User experience.
6. Maintainability.
7. Performance.

Keep the application simple, self-contained and easy to maintain.
