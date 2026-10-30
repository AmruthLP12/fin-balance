# Flutter Architecture Skill

Use this skill for Flutter screens, state management, dependency wiring,
and app structure.

## Required process

1.  Read `architecture.md` and `essential-architecture.md`.
2.  Inspect existing code and current package versions.
3.  Keep presentation, domain, data, and platform concerns separated.
4.  Add only the files and abstractions needed for the feature.

## Rules

-   Use Flutter/Dart null safety and current stable compatible
    dependencies.
-   Use Riverpod for state and dependency wiring.
-   Widgets render state and send user actions; they do not contain SQL
    or core timer calculations.
-   Domain services should be plain Dart wherever practical.
-   Prefer small, feature-oriented modules and reusable widgets.
-   Keep theme values in centralized design tokens.
-   Avoid giant screens, duplicated timer logic, global mutable state,
    and speculative architecture.
-   Run `dart format`, `flutter analyze`, and relevant tests after
    changes.

## UI quality

The interface must feel like a designed personal gaming utility, not a
generic admin template. Keep visual hierarchy, spacing, typography,
contrast, empty states, and small-screen behavior intentional.
