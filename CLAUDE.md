# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Idly Express** — a Flutter mobile app for tracking sales and profit for an idly (South Indian food) business. Targets Android primarily; Firebase must be configured before running.

## Commands

```bash
# Run the app (connected device or emulator required)
flutter run

# Build release APK
flutter build apk --release

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code
flutter analyze

# Format code
dart format lib/

# Get dependencies
flutter pub get
```

## Architecture

**State management:** `provider` package with two `ChangeNotifier` providers registered in `main.dart`:
- `SalesProvider` — all sales data, aggregations (today/month/year stats), CSV import/export
- `ExpenseProvider` — expense tracking by category

**Data layer (offline-first):**
- `DatabaseService` (singleton) — SQLite via `sqflite`. DB version 3. Three tables: `sales_entries`, `shops` (for autocomplete), `expenses`. All write mutations go through `DatabaseService` then `SalesProvider.loadData()` reloads all cached lists.
- `SyncService` (singleton, extends `ChangeNotifier`) — pushes unsynced local records to Cloud Firestore when connectivity is available. Sync is one-directional (local → Firestore). Triggered automatically on write and on connectivity restoration. Multi-device pull is not yet implemented.

**Screens:** `DashboardScreen` is the home route. Other screens: `AddEntryScreen`, `ReportsScreen`, `ExpensesScreen`, `ShopBalancesScreen`, `ProfitScreen`.

**Models:**
- `SalesEntry` — immutable value object with computed fields (`totalSalesAmount`, `profit`, `pendingAmount`). Enums for `ProductType` (Idly, Sandhagai, Idiyappam), `SaleType` (wholesale/retail), `PaymentStatus` (paid/pending). Enum values are stored by index in SQLite — **never reorder enum members**.
- `Expense` — simpler model with category, amount, date.

**Constants** (`lib/core/constants.dart`): all enums, DB table/file names, default rate values, currency symbol.

## Key Constraints

- Firebase (`google-services.json`) is already included in `android/app/`. The app calls `Firebase.initializeApp()` at startup and will crash without a valid Firebase project.
- DB schema migrations use `onUpgrade`; adding columns requires a version bump and `ALTER TABLE` in `_onUpgrade`. Dropping/recreating tables loses data — avoid for production migrations.
- `paidAmount` defaults to the full sale amount (fully paid) when not explicitly set — see `SalesEntry` constructor.
- Float tolerance of `0.1` is used for `isFullyPaid` to handle rounding in currency math.
