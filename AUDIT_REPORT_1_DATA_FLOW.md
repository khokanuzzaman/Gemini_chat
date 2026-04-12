# AUDIT_REPORT_1_DATA_FLOW

## 1. Summary

Static audit scope:
- Scanned `263` Dart files under `lib/`
- Inventoried `126` Riverpod providers (`125` direct provider definitions + `1` alias: `goalsProvider`)
- Focus areas: refresh-token propagation, invalidation chains, cross-feature reactive reads, notifier build patterns, SharedPreferences/cache consistency, wallet-balance correctness

Issue count:
- Critical: `1`
- High: `6`
- Medium: `5`
- Low: `4`

Primary conclusions:
- Expense and income wallet delta math is correct in the audited mutation paths, but wallet-sync failures are swallowed after the core record mutation commits. That can silently corrupt wallet balances and all wallet-derived UI.
- Expense refresh tokens are broadly wired correctly. Income refresh tokens are also wired correctly in the core income providers. The main stale-data gaps are outside those tokens: anomaly cache freshness, prediction cache/state, category-to-budget propagation, and a non-reactive `goalSavingsProvider`.
- The RAG context builder mostly reads live Isar data and is therefore fresh for expenses, budgets, goals, and recurring data. Its anomaly and prediction sub-contexts inherit the anomaly/prediction staleness issues described below.

Verified-good chains:
- `cashFlowProvider` watches both `expenseRefreshTokenProvider` and `incomeRefreshTokenProvider`
- `walletMonthlySpentProvider(walletId)` watches `expenseRefreshTokenProvider`
- `walletBreakdownForMonthProvider(month)` watches `expenseRefreshTokenProvider`
- `totalBalanceProvider` depends on `walletProvider`
- Expense save/delete/update signs are correct
- Income save/delete/update signs are correct
- Chat streaming state is cleaned up in `finally` blocks; no stuck responding-state bug was found in `ChatNotifier`

## 2. Critical Issues

### C1. Wallet balance sync failures are swallowed after the main expense/income mutation commits
- Severity: Critical
- File path: `lib/features/expense/presentation/providers/expense_providers.dart`; `lib/features/income/presentation/providers/income_providers.dart`; `lib/features/wallet/data/datasources/wallet_local_datasource.dart`
- Line number(s): `lib/features/expense/presentation/providers/expense_providers.dart:387-402`, `lib/features/expense/presentation/providers/expense_providers.dart:768-779`, `lib/features/income/presentation/providers/income_providers.dart:352-363`, `lib/features/wallet/data/datasources/wallet_local_datasource.dart:78-89`
- Current behavior: expense and income mutations commit the expense/income record first, then call `_adjustWalletBalance(...)`. Both `_adjustWalletBalance(...)` helpers catch and only `debugPrint(...)` wallet-sync failures. `WalletLocalDataSource.adjustBalance(...)` also returns silently if the wallet is missing.
- Expected behavior: the wallet balance update must either be part of the same transactional unit as the record mutation, or the mutation must surface a hard failure and compensate/rollback the already-written record.
- Impact: wallet balances, net worth, wallet breakdowns, and any wallet-derived dashboard data can become permanently wrong without any user-visible error. A retry can then duplicate the expense/income while the first write already succeeded.
- Suggested fix: make record-write + wallet-adjust a single atomic unit where possible, or propagate wallet-sync failure out of the mutation and run an explicit compensating rollback/reconciliation path.

## 3. High Priority Issues

### H1. Expense refresh-token rebuilds do not guarantee fresh anomaly data
- Severity: High
- File path: `lib/features/anomaly/presentation/providers/anomaly_provider.dart`; `lib/features/category/presentation/providers/category_provider.dart`; `lib/features/settings/settings_screen.dart`
- Line number(s): `lib/features/anomaly/presentation/providers/anomaly_provider.dart:69-91`, `lib/features/category/presentation/providers/category_provider.dart:95-116`, `lib/features/category/presentation/providers/category_provider.dart:267-269`, `lib/features/settings/settings_screen.dart:625-630`
- Current behavior: `AnomalyNotifier.build()` watches `expenseRefreshTokenProvider`, reloads cached alerts, then only calls `detectIfNeeded()`, which skips re-detection unless the last run is at least 6 hours old. Category rename/delete paths only bump `expenseRefreshTokenProvider`; demo-seed also only bumps the token.
- Expected behavior: any mutation path that changes anomaly inputs should force fresh anomaly detection, not only a token-triggered rebuild of cached state.
- Impact: the anomaly card and anomaly notifications can continue showing alerts for deleted expenses, renamed categories, or pre-seed data for up to 6 hours.
- Suggested fix: make expense/category/demo-seed paths call `anomalyProvider.notifier.reDetect()` explicitly, or teach `AnomalyNotifier.build()` to bypass the 6-hour cache when the expense refresh token changes.

### H2. Prediction state is not reactive to most expense mutations, so dashboard and RAG can use stale predictions
- Severity: High
- File path: `lib/features/prediction/presentation/providers/prediction_provider.dart`; `lib/features/expense/presentation/providers/expense_providers.dart`; `lib/features/expense/presentation/screens/dashboard_screen.dart`; `lib/features/prediction/presentation/widgets/prediction_card.dart`; `lib/features/expense/presentation/screens/analytics_screen.dart`; `lib/features/chat/presentation/providers/chat_provider.dart`
- Line number(s): `lib/features/prediction/presentation/providers/prediction_provider.dart:97-240`, `lib/features/expense/presentation/providers/expense_providers.dart:717-726`, `lib/features/expense/presentation/screens/dashboard_screen.dart:55`, `lib/features/prediction/presentation/widgets/prediction_card.dart:26-34`, `lib/features/expense/presentation/screens/analytics_screen.dart:132-141`, `lib/features/chat/presentation/providers/chat_provider.dart:49-55`
- Current behavior: `predictionProvider` has no refresh token. It refreshes only when `PredictionCard`/analytics explicitly calls `loadPrediction()`, or when `registerExpenseSaves()` reaches 10 saved expenses. Expense updates, expense deletes, demo-seed, clear-all-data, and fewer than 10 saves do not refresh prediction state.
- Expected behavior: visible prediction consumers and RAG prediction context should be invalidated whenever the underlying expense data changes materially.
- Impact: the dashboard prediction teaser and AI/RAG answers can reflect stale forecast data even though current expenses have changed.
- Suggested fix: add a dedicated prediction refresh signal, invalidate prediction on every expense mutation/reset/seed, and keep remote throttling separate from local state invalidation.

### H3. Data reset and demo-seed flows leave prediction cache and prediction counters behind
- Severity: High
- File path: `lib/features/settings/settings_screen.dart`; `lib/features/prediction/data/repositories/prediction_repository_impl.dart`; `lib/features/prediction/presentation/providers/prediction_provider.dart`
- Line number(s): `lib/features/settings/settings_screen.dart:596-616`, `lib/features/settings/settings_screen.dart:625-630`, `lib/features/prediction/data/repositories/prediction_repository_impl.dart:38-65`, `lib/features/prediction/presentation/providers/prediction_provider.dart:90`, `lib/features/prediction/presentation/providers/prediction_provider.dart:231-239`
- Current behavior: clear-all-data removes many Isar collections, but not `predictionCacheModels`, and it does not reset `expenses_since_predict` or invalidate/reset `predictionProvider`. Demo-seed only clears expenses and bumps `expenseRefreshTokenProvider`.
- Expected behavior: reset and seed operations should also clear prediction cache/state/counters.
- Impact: after a full reset or demo-seed, the user can still see an old forecast generated from pre-reset data.
- Suggested fix: clear `predictionCacheModels`, reset `expenses_since_predict`, and invalidate/reset `predictionProvider` in reset/seed flows.

### H4. Category rename/delete does not propagate into budget settings or active budget maps
- Severity: High
- File path: `lib/features/category/presentation/providers/category_provider.dart`; `lib/core/notifications/budget_settings.dart`; `lib/core/notifications/notification_provider.dart`; `lib/features/budget/presentation/providers/budget_provider.dart`
- Line number(s): `lib/features/category/presentation/providers/category_provider.dart:95-116`, `lib/core/notifications/budget_settings.dart:95-110`, `lib/core/notifications/notification_provider.dart:71-88`, `lib/features/budget/presentation/providers/budget_provider.dart:228-259`
- Current behavior: category rename/delete updates expense rows and the category registry, but it does not remap `budgetSettingsProvider.categoryBudgets` or `budgetProvider.activeBudget.categoryBudgets`.
- Expected behavior: category rename/delete should also remap or clean related budget maps.
- Impact: budget-alert lookup for the renamed category can return `null`, so alerts silently stop firing for that category until the user manually resaves budgets. Active budget allocations can also keep dead category keys.
- Suggested fix: add a category-to-budget remapping step in category update/delete mutations and invalidate any budget consumers afterward.

### H5. Expense updates do not run budget-alert checks
- Severity: High
- File path: `lib/features/expense/presentation/providers/expense_providers.dart`
- Line number(s): `lib/features/expense/presentation/providers/expense_providers.dart:278-305`, `lib/features/expense/presentation/providers/expense_providers.dart:574-576`, `lib/features/expense/presentation/providers/expense_providers.dart:627-630`, `lib/features/expense/presentation/providers/expense_providers.dart:668-670`, `lib/features/expense/presentation/providers/expense_providers.dart:706-708`
- Current behavior: expense save paths call `notificationProvider.checkBudgetAlert(...)`; `ExpenseListController.updateExpense(...)` does not.
- Expected behavior: editing an expense amount or moving it to another category should re-check the affected category budgets.
- Impact: a user can cross a category budget threshold by editing an expense and never receive the alert that would have fired on a normal save.
- Suggested fix: after a successful expense update, re-check at least the new category, and ideally both the old and new categories when they differ.

### H6. Post-commit side-effect failures can make a successful mutation look like a failed mutation
- Severity: High
- File path: `lib/features/expense/presentation/providers/expense_providers.dart`; `lib/features/income/presentation/providers/income_providers.dart`
- Line number(s): `lib/features/expense/presentation/providers/expense_providers.dart:567-576`, `lib/features/expense/presentation/providers/expense_providers.dart:614-630`, `lib/features/expense/presentation/providers/expense_providers.dart:661-670`, `lib/features/expense/presentation/providers/expense_providers.dart:699-708`, `lib/features/expense/presentation/providers/expense_providers.dart:717-726`, `lib/features/income/presentation/providers/income_providers.dart:152-158`, `lib/features/income/presentation/providers/income_providers.dart:181-187`, `lib/features/income/presentation/providers/income_providers.dart:215-223`, `lib/features/income/presentation/providers/income_providers.dart:240-247`, `lib/features/income/presentation/providers/income_providers.dart:265-297`, `lib/features/income/presentation/providers/income_providers.dart:347-349`
- Current behavior: expense/income records are written before later side effects such as `setActiveWalletId(...)`, `reDetect()`, `registerExpenseSaves(...)`, and `checkBudgetAlert(...)`. If a later awaited step throws, the method returns an error string even though the main record mutation already succeeded.
- Expected behavior: the user-visible mutation result should reflect the commit result, while non-critical side-effect failures are handled separately.
- Impact: the UI can tell the user that save/update/delete failed, but the record is already persisted. A retry can create duplicates or compound wallet drift.
- Suggested fix: split mutation commit from post-commit side effects, capture side-effect failures separately, and avoid returning a hard failure after the primary write already succeeded.

## 4. Medium Priority Issues

### M1. `goalSavingsProvider` is a mutable `FutureProvider.family` with no reactive dependency
- Severity: Medium
- File path: `lib/features/goals/presentation/providers/goal_provider.dart`
- Line number(s): `lib/features/goals/presentation/providers/goal_provider.dart:98-103`, `lib/features/goals/presentation/providers/goal_provider.dart:176`, `lib/features/goals/presentation/providers/goal_provider.dart:209`, `lib/features/goals/presentation/providers/goal_provider.dart:231-232`
- Current behavior: `goalSavingsProvider(goalId)` calls `ref.read(goalProvider.notifier).getSavingsForGoal(goalId)` and does not watch `goalProvider`, a refresh token, or any datasource stream. It refreshes only when manually invalidated in `deleteGoal(...)` and `addSaving(...)`.
- Expected behavior: the provider should either watch a goal refresh signal or be rebuilt from a notifier that updates whenever goal savings change.
- Impact: savings details can go stale if any future goal mutation path writes savings without remembering to invalidate the family instance.
- Suggested fix: introduce a goal refresh token or move goal savings into the goal notifier state/own async notifier.

### M2. `active_wallet_id` persistence is never repaired by wallet mutations
- Severity: Medium
- File path: `lib/features/wallet/presentation/providers/wallet_provider.dart`; `lib/core/preferences/app_preferences.dart`; `lib/main.dart`
- Line number(s): `lib/features/wallet/presentation/providers/wallet_provider.dart:157-175`, `lib/core/preferences/app_preferences.dart:65-72`, `lib/main.dart:287-295`
- Current behavior: the active wallet preference is only written from expense/income mutation controllers and clear-all-data. Wallet add/update/archive/delete never clears or remaps the stored active wallet id.
- Expected behavior: wallet deletion/archive should clear or replace `active_wallet_id` when it points at the removed wallet.
- Impact: SharedPreferences can retain a deleted/archived wallet id. The in-memory `activeWalletProvider` falls back to the first/cash wallet, so the bug is masked until later persistence-dependent logic relies on the stale preference.
- Suggested fix: update `activeWalletIdProvider` and `AppPreferences.setActiveWalletId(...)` inside wallet archive/delete flows when the active wallet is affected.

### M3. `category_budgets` is a dead cache key that is written but never read
- Severity: Medium
- File path: `lib/features/budget/presentation/providers/budget_provider.dart`; `lib/core/notifications/budget_settings.dart`
- Line number(s): `lib/features/budget/presentation/providers/budget_provider.dart:445-450`, `lib/core/notifications/budget_settings.dart:8`, `lib/core/notifications/budget_settings.dart:128-135`
- Current behavior: `_updateNotificationBudgets(...)` writes the real budget data to `budgetSettingsProvider`, then separately writes raw JSON to `'category_budgets'`. No reader for `'category_budgets'` exists in `lib/`.
- Expected behavior: budget data should have a single authoritative persisted representation.
- Impact: the app now has an orphaned cache entry that can drift from `budget_settings` and confuse migrations, debugging, and future features.
- Suggested fix: remove the dead key or document and actually consume it consistently.

### M4. Several `Notifier.build()` loaders are fire-and-forget microtasks with no error guard
- Severity: Medium
- File path: `lib/features/budget/presentation/providers/budget_provider.dart`; `lib/features/goals/presentation/providers/goal_provider.dart`; `lib/features/split/presentation/providers/split_bill_provider.dart`
- Line number(s): `lib/features/budget/presentation/providers/budget_provider.dart:126-132`, `lib/features/budget/presentation/providers/budget_provider.dart:262-271`, `lib/features/goals/presentation/providers/goal_provider.dart:109-119`, `lib/features/split/presentation/providers/split_bill_provider.dart:59-69`
- Current behavior: these notifiers return an initial sync state, then schedule `_load...()` in `Future.microtask(...)` without wrapping the load in `try/catch`.
- Expected behavior: load errors should be translated into explicit state, not uncaught async exceptions or permanently half-loaded state.
- Impact: if the underlying repository throws, the screen can remain in an incorrect loading state or fail with an uncaught async error outside an `AsyncValue`.
- Suggested fix: convert these into `AsyncNotifier`s, or keep `Notifier` but capture loader failures into state explicitly.

### M5. Mutation error handling is inconsistent across features
- Severity: Medium
- File path: `lib/features/wallet/presentation/providers/wallet_provider.dart`; `lib/features/budget/presentation/providers/budget_provider.dart`; `lib/features/goals/presentation/providers/goal_provider.dart`; `lib/features/split/presentation/providers/split_bill_provider.dart`
- Line number(s): `lib/features/wallet/presentation/providers/wallet_provider.dart:157-179`, `lib/features/budget/presentation/providers/budget_provider.dart:144-259`, `lib/features/goals/presentation/providers/goal_provider.dart:136-229`, `lib/features/split/presentation/providers/split_bill_provider.dart:72-93`
- Current behavior: expense/income mutations return `Future<String?>` and catch many failures; wallet/budget/goal/split mutations mostly return `Future<void>` and let failures bubble without a uniform error contract.
- Expected behavior: comparable mutation surfaces should report errors consistently.
- Impact: UI code has to guess which features fail via return value, which fail via thrown exception, and which silently log; this increases inconsistent stale-state and retry behavior.
- Suggested fix: standardize on one mutation contract per app layer, ideally a typed result/error surface plus rollback rules.

## 5. Low Priority Issues

### L1. Some derived providers and services bypass repository/use-case layers
- Severity: Low
- File path: `lib/features/wallet/presentation/providers/wallet_provider.dart`; `lib/core/notifications/notification_provider.dart`; `lib/features/budget/presentation/widgets/budget_dashboard.dart`
- Line number(s): `lib/features/wallet/presentation/providers/wallet_provider.dart:103-113`, `lib/features/wallet/presentation/providers/wallet_provider.dart:118-148`, `lib/core/notifications/notification_provider.dart:66-76`, `lib/features/budget/presentation/widgets/budget_dashboard.dart:27-30`
- Current behavior: wallet breakdown providers instantiate `ExpenseRepositoryImpl` directly; `NotificationNotifier` reads `ExpenseLocalDataSource` directly; `BudgetDashboard` issues its own repository future in-widget.
- Expected behavior: cross-feature data should usually flow through shared repository/use-case providers.
- Impact: dependency graphs become harder to reason about and test. Future refresh-token bugs are easier to introduce because data access is duplicated.
- Suggested fix: route these reads through shared provider/use-case entry points.

### L2. `ConnectivityNotifier.build()` uses `ref.read(...)` inside build
- Severity: Low
- File path: `lib/core/network/connectivity_provider.dart`
- Line number(s): `lib/core/network/connectivity_provider.dart:19-30`
- Current behavior: `build()` calls `ref.read(connectivityServiceProvider)` and starts a subscription.
- Expected behavior: build-time reactive dependencies are usually watched, though in this case the service provider is effectively static.
- Impact: low immediate risk, but it is still a Riverpod anti-pattern that makes dependency intent less explicit.
- Suggested fix: either keep it documented as a static service dependency or switch to a more explicit pattern.

### L3. `RecurringNotifier.build()` rewrites recurring patterns on every expense refresh
- Severity: Low
- File path: `lib/features/recurring/presentation/providers/recurring_provider.dart`
- Line number(s): `lib/features/recurring/presentation/providers/recurring_provider.dart:23-31`, `lib/features/recurring/presentation/providers/recurring_provider.dart:47-63`
- Current behavior: every `expenseRefreshTokenProvider` bump triggers `_detectAndSave()` before loading state.
- Expected behavior: recurring detection should be idempotent and ideally avoid unnecessary writes.
- Impact: no infinite Riverpod loop was found, but every expense mutation performs recurring detection and persists patterns again.
- Suggested fix: memoize detection inputs/signatures or separate read-refresh from write-refresh.

### L4. `BudgetSettingsScreen` snapshots draft budgets once and does not react to concurrent budget changes while open
- Severity: Low
- File path: `lib/features/settings/budget_settings_screen.dart`
- Line number(s): `lib/features/settings/budget_settings_screen.dart:23-29`, `lib/features/settings/budget_settings_screen.dart:160-165`
- Current behavior: `_draftBudgets` is initialized from `ref.read(budgetSettingsProvider)` in `initState()` and only filled with `putIfAbsent(...)` afterward.
- Expected behavior: if another screen mutates `budgetSettingsProvider` while this screen is open, the drafts should resync or clearly own the edit session.
- Impact: low likelihood, but the screen can show stale draft values during concurrent edits.
- Suggested fix: either resync drafts on provider change or explicitly isolate the edit session and discard stale changes on save.

## 6. Provider Dependency Graph

Primary refresh-token graph:
- `expenseRefreshTokenProvider`
  - `DashboardController.build()`
  - `ExpenseListController.build()`
  - `AnalyticsController.build()`
  - `cashFlowProvider`
  - `walletMonthlySpentProvider(walletId)`
  - `walletBreakdownForMonthProvider(month)`
  - `AnomalyNotifier.build()`
  - `RecurringNotifier.build()`
  - `BudgetDashboard` widget-level `FutureBuilder` refresh trigger
- `incomeRefreshTokenProvider`
  - `IncomeListController.build()`
  - `thisMonthIncomeProvider`
  - `lastMonthIncomeProvider`
  - `incomeBySourceThisMonthProvider`
  - `cashFlowProvider`

Wallet graph:
- expense mutation helpers and income mutation helpers call `walletLocalDataSource.adjustBalance(...)`
- wallet sync invalidates `walletProvider`
- `walletProvider` feeds:
  - `activeWalletProvider`
  - `walletByIdProvider(id)`
  - `totalBalanceProvider`
  - dashboard wallet/net-worth sections
  - expense/income wallet resolution via `walletProvider.future`

Budget graph:
- `budgetProvider` feeds `budgetPlanProvider`
- `budgetProvider._updateNotificationBudgets(...)` writes into `budgetSettingsProvider`
- `notificationProvider.checkBudgetAlert(category)` reads `budgetSettingsProvider.categoryBudgets[category]`

Category graph:
- `categoryProvider` updates `CategoryRegistry`
- chat prompt builders fetch categories live via `getCategoriesUseCaseProvider`
- `RagContextBuilder` uses `CategoryRegistry.categories` only for query-keyword/category-name matching; expense/budget/goal/recurring payloads are loaded live from Isar

Anomaly graph:
- expense save/update/delete paths call `anomalyProvider.notifier.reDetect()`
- category rename/delete and demo-seed do not call `reDetect()`, only `expenseRefreshTokenProvider++`
- `ragContextBuilderProvider` injects anomaly context via `anomalyProvider.notifier.getActiveAlerts()`

Prediction graph:
- no refresh token exists
- `PredictionCard` and analytics screen explicitly call `predictionProvider.notifier.loadPrediction()`
- expense save paths increment `registerExpenseSaves(...)`, which force-refreshes only every 10 saves
- `dashboard_screen.dart` reads `predictionProvider.prediction`
- `ragContextBuilderProvider` returns current in-memory prediction first, then cached prediction

Broken links found:
- Expense/category/demo-seed changes do not guarantee fresh anomaly recomputation
- Expense update/delete/clear/seed do not invalidate prediction state
- Category rename/delete does not cascade into budget maps used by alerts
- `goalSavingsProvider(goalId)` is not attached to any refresh token or watched provider

## 7. Wallet Balance Audit Results

| Mutation | Code path | Expected wallet delta | Actual implementation | Result | Notes |
|---|---|---:|---:|---|---|
| Expense save | `ExpenseMutationController.saveDetectedExpense` | `-amount` | `-expense.amount` | Correct | Wallet sync failure is swallowed |
| Expense batch save | `ExpenseMutationController.saveDetectedExpenses` | `-sum(amounts)` | loop of `-expense.amount` per row | Correct | No transaction; partial wallet sync possible |
| Receipt save | `ExpenseMutationController.saveReceiptExpense` | `-amount` | `-expense.amount` | Correct | Same silent-failure caveat |
| Manual expense save | `ExpenseMutationController.saveManualExpense` | `-amount` | `-normalizedExpense.amount` | Correct | Same silent-failure caveat |
| Expense delete | `ExpenseListController.deleteExpense` | `+oldAmount` | `refundAmount` | Correct | Same silent-failure caveat |
| Expense update, same wallet | `ExpenseListController._syncWalletBalanceAfterUpdate` | `oldAmount - newAmount` | `(previous.amount) - updated.amount` | Correct | Same silent-failure caveat |
| Expense update, different wallet | `ExpenseListController._syncWalletBalanceAfterUpdate` | `+oldAmount` on old, `-newAmount` on new | `+previous.amount`, `-updated.amount` | Correct | Same silent-failure caveat |
| Manual income save | `IncomeMutationController.saveManualIncome` | `+amount` | `+normalized.amount` | Correct | Wallet sync failure is swallowed |
| Detected income save | `IncomeMutationController.saveDetectedIncome` | `+amount` | `+normalized.amount` | Correct | Same silent-failure caveat |
| Income batch save | `IncomeMutationController.saveDetectedIncomeBatch` | `+sum(amounts)` | loop of `+entry.amount` per row | Correct | No transaction; partial wallet sync possible |
| Income delete | `IncomeMutationController.deleteIncome` | `-oldAmount` | `-refundAmount` | Correct | Same silent-failure caveat |
| Income update, same wallet | `IncomeMutationController.updateIncome` | `newAmount - oldAmount` | `newIncome.amount - oldIncome.amount` | Correct | Same silent-failure caveat |
| Income update, different wallet | `IncomeMutationController.updateIncome` | `-oldAmount` on old, `+newAmount` on new | `-oldIncome.amount`, `+newIncome.amount` | Correct | Same silent-failure caveat |

## 8. Recommended Fix Order

1. Fix the wallet-sync atomicity problem first. It is the only issue in this audit that can silently corrupt balances and every wallet-derived UI.
2. Make anomaly refresh truly data-driven on every expense/category/seed mutation path.
3. Introduce a real prediction invalidation model, then clear/reset prediction caches in reset/seed flows.
4. Propagate category rename/delete into budget settings and active budget maps, then add budget-alert checks to expense updates.
5. Separate mutation commit success from post-commit side-effect failures so the UI cannot report a false failure after persistence already succeeded.
6. Add a reactive dependency or refresh token for `goalSavingsProvider`.
7. Repair `active_wallet_id` persistence on wallet archive/delete and remove the orphaned `category_budgets` cache.
8. Standardize error handling for non-expense/income mutation notifiers and clean up low-priority Riverpod anti-patterns.

## Appendix A. SharedPreferences And Cache Inventory

| Key | Reads | Writes | Risk assessment |
|---|---|---|---|
| `notification_permission_asked` | `main.dart:60-61` | `main.dart:63-64` | Low. One-time permission flag only. |
| `onboarding_complete` | `AppPreferences.isOnboardingComplete()` | `AppPreferences.setOnboardingComplete()` | Low. No conflicting in-memory cache found in audited files. |
| `rag_enabled` | `AppPreferences.isRagEnabled()`, `main.dart:288-294` | `AppPreferences.setRagEnabled()` | Low. Hydrated at startup and manually mirrored to `ragEnabledProvider`. |
| `theme_mode` | `AppPreferences.themeMode()` | `AppPreferences.setThemeMode()` | Low. Bootstrapped into `themeBootstrapProvider`, then managed by `themeProvider`. |
| `default_category` | `AppPreferences.defaultCategory()` | `AppPreferences.setDefaultCategory()` | Low. No stale-cache bug found in this audit. |
| `currency_symbol` | `AppPreferences.currencySymbol()` | `AppPreferences.setCurrencySymbol()` | Low. No stale-cache bug found in this audit. |
| `date_format` | `AppPreferences.dateFormat()` | `AppPreferences.setDateFormat()` | Low. No stale-cache bug found in this audit. |
| `active_wallet_id` | `main.dart:289`, expense/income `_resolveWalletId()` | expense/income `_rememberActiveWallet()`, clear-all-data writes `0` | Medium. Wallet mutations never repair stale/deleted ids. |
| `seeded` | `ExpenseSeedData.seedIfNeeded()` | `ExpenseSeedData.seedIfNeeded()`, `ExpenseSeedData.forceSeed()` | Low. One-way migration/demo flag; no reset bug found. |
| `expense_wallet_migration_v1` | `ExpenseMigration.migrateExpensesToDefaultWallet()` | same | Low. Proper one-way migration guard. |
| `notification_settings` | `NotificationNotifier.build()` | `NotificationNotifier.updateSettings()` | Low. Single authoritative key. |
| `budget_settings` | `BudgetSettingsNotifier.build()` | `BudgetSettingsNotifier._save()`, `BudgetNotifier._updateNotificationBudgets()` | Medium. Category rename/delete does not remap existing keys. |
| `category_budgets` | no readers found in `lib/` | `BudgetNotifier._updateNotificationBudgets()` | Medium. Dead cache; guaranteed divergence over time. |
| `biometric_enabled` | `BiometricNotifier.build()` | `BiometricNotifier.enable()`, `BiometricNotifier.disable()` | Low. Local preference only. |
| `biometric_lock_timeout` | `BiometricNotifier.build()` | `BiometricNotifier.setLockTimeout()` | Low. Local preference only. |
| `anomaly_alerts_v2` | `AnomalyNotifier.build()` | `AnomalyNotifier._persistState()`, `AnomalyNotifier.clear()` | High. Can remain stale when token changes do not force `reDetect()`. |
| `anomaly_last_detected_v2` | `AnomalyNotifier.build()` | `AnomalyNotifier._persistState()`, `AnomalyNotifier.clear()` | High. Same freshness problem as anomaly cache. |
| `anomaly_last_high_signature_v2` | `AnomalyNotifier._notifyHighSeverity()` | same, `AnomalyNotifier.clear()` | Medium. Notification dedupe state can outlive dataset changes until anomalies are explicitly cleared/recomputed. |
| `expenses_since_predict` | `PredictionNotifier.registerExpenseSaves()` | same | High. Not cleared on reset/seed; ignores deletes/updates. |

RAG freshness verification:
- Fresh/live from Isar: expenses, today expenses, period expenses, budget plan, goals, recurring patterns
- Fresh/live category prompt list: chat/receipt datasources call `getCategoriesUseCaseProvider` per request
- Potentially stale inside RAG: anomaly alerts (`anomalyProvider.getActiveAlerts()`), prediction (`predictionProvider.prediction` or cached prediction)

## Appendix B. Provider Inventory

Legend:
- `deps` lists direct `ref.watch(...)` / `ref.read(...)` dependencies in the provider body or the notifier `build()` path
- `refresh` lists refresh tokens explicitly watched
- `family` is `yes` only for family providers

### Chat

- `expenseParserProvider` | `Provider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-` | refresh `-` | family `no`
- `ragContextBuilderProvider` | `Provider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `watch(expenseLocalDataSourceProvider, budgetPlanLocalDataSourceProvider, goalLocalDataSourceProvider, recurringLocalDataSourceProvider)`; runtime closures `read(anomalyProvider.notifier, predictionProvider, predictionProvider.notifier)` | refresh `-` | family `no`
- `voiceRecorderServiceProvider` | `Provider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-`; `ref.onDispose(...)` | refresh `-` | family `no`
- `ocrServiceProvider` | `Provider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-`; `ref.onDispose(...)` | refresh `-` | family `no`
- `receiptScannerServiceProvider` | `Provider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `watch(ocrServiceProvider)` | refresh `-` | family `no`
- `openAiChatDataSourceProvider` | `Provider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `watch(connectivityServiceProvider)`; runtime category loader `read(getCategoriesUseCaseProvider)` | refresh `-` | family `no`
- `openAiVoiceDataSourceProvider` | `Provider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `watch(connectivityServiceProvider)` | refresh `-` | family `no`
- `openAiReceiptDataSourceProvider` | `Provider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `watch(connectivityServiceProvider)`; runtime category loader `read(getCategoriesUseCaseProvider)` | refresh `-` | family `no`
- `chatRepositoryProvider` | `Provider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `watch(openAiChatDataSourceProvider, openAiVoiceDataSourceProvider, openAiReceiptDataSourceProvider, ragContextBuilderProvider, isarProvider)` | refresh `-` | family `no`
- `sendMessageUseCaseProvider` | `Provider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `watch(chatRepositoryProvider)` | refresh `-` | family `no`
- `sendVoiceMessageUseCaseProvider` | `Provider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `watch(chatRepositoryProvider)` | refresh `-` | family `no`
- `scanReceiptUseCaseProvider` | `Provider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `watch(chatRepositoryProvider)` | refresh `-` | family `no`
- `chatStreamingTextProvider` | `StateProvider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-` | refresh `-` | family `no`
- `isRespondingProvider` | `StateProvider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-` | refresh `-` | family `no`
- `isRecordingProvider` | `StateProvider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-` | refresh `-` | family `no`
- `isScanningProvider` | `StateProvider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-` | refresh `-` | family `no`
- `recordingDurationProvider` | `StateProvider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-` | refresh `-` | family `no`
- `chatErrorMessageProvider` | `StateProvider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-` | refresh `-` | family `no`
- `openAiRateLimitSnapshotProvider` | `StateProvider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-` | refresh `-` | family `no`
- `ragEnabledProvider` | `StateProvider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-` | refresh `-` | family `no`
- `lastMessageUsedRagProvider` | `StateProvider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-` | refresh `-` | family `no`
- `latestRagStructuredDataProvider` | `StateProvider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-` | refresh `-` | family `no`
- `ragResponseMapProvider` | `StateProvider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-` | refresh `-` | family `no`
- `parsedExpenseResultMapProvider` | `StateProvider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `-` | refresh `-` | family `no`
- `chatProvider` | `AsyncNotifierProvider` | `lib/features/chat/presentation/providers/chat_provider.dart` | deps `build: read(chatRepositoryProvider)`; runtime reads many chat state providers, scanner/voice services, use cases, and RAG builders | refresh `-` | family `no`

### Expense

- `expenseRefreshTokenProvider` | `StateProvider` | `lib/features/expense/presentation/providers/expense_refresh_provider.dart` | deps `-` | refresh `self` | family `no`
- `expenseRepositoryProvider` | `Provider` | `lib/features/expense/presentation/providers/expense_providers.dart` | deps `watch(expenseLocalDataSourceProvider)` | refresh `-` | family `no`
- `getDashboardDataUseCaseProvider` | `Provider` | `lib/features/expense/presentation/providers/expense_providers.dart` | deps `watch(expenseRepositoryProvider)` | refresh `-` | family `no`
- `getExpenseListUseCaseProvider` | `Provider` | `lib/features/expense/presentation/providers/expense_providers.dart` | deps `watch(expenseRepositoryProvider)` | refresh `-` | family `no`
- `getAnalyticsUseCaseProvider` | `Provider` | `lib/features/expense/presentation/providers/expense_providers.dart` | deps `watch(expenseRepositoryProvider)` | refresh `-` | family `no`
- `deleteExpenseUseCaseProvider` | `Provider` | `lib/features/expense/presentation/providers/expense_providers.dart` | deps `watch(expenseRepositoryProvider)` | refresh `-` | family `no`
- `updateExpenseUseCaseProvider` | `Provider` | `lib/features/expense/presentation/providers/expense_providers.dart` | deps `watch(expenseRepositoryProvider)` | refresh `-` | family `no`
- `saveExpenseUseCaseProvider` | `Provider` | `lib/features/expense/presentation/providers/expense_providers.dart` | deps `watch(expenseRepositoryProvider)` | refresh `-` | family `no`
- `dashboardControllerProvider` | `AsyncNotifierProvider` | `lib/features/expense/presentation/providers/expense_providers.dart` | deps `build: watch(expenseRefreshTokenProvider), read(getDashboardDataUseCaseProvider)` | refresh `expenseRefreshTokenProvider` | family `no`
- `expenseListControllerProvider` | `AsyncNotifierProvider` | `lib/features/expense/presentation/providers/expense_providers.dart` | deps `build: watch(expenseRefreshTokenProvider), read(getExpenseListUseCaseProvider)` | refresh `expenseRefreshTokenProvider` | family `no`
- `analyticsControllerProvider` | `AsyncNotifierProvider` | `lib/features/expense/presentation/providers/expense_providers.dart` | deps `build: watch(expenseRefreshTokenProvider), read(getAnalyticsUseCaseProvider)` | refresh `expenseRefreshTokenProvider` | family `no`
- `expenseMutationControllerProvider` | `Provider` | `lib/features/expense/presentation/providers/expense_providers.dart` | deps `-`; runtime reads `saveExpenseUseCaseProvider, walletLocalDataSourceProvider, activeWalletProvider, walletProvider.future, notificationProvider.notifier, anomalyProvider.notifier, predictionProvider.notifier` | refresh `-` | family `no`
- `cashFlowProvider` | `FutureProvider` | `lib/features/expense/presentation/providers/expense_providers.dart` | deps `watch(expenseRefreshTokenProvider, incomeRefreshTokenProvider)`; runtime reads `expenseRepositoryProvider, getIncomeTotalsUseCaseProvider` | refresh `expenseRefreshTokenProvider, incomeRefreshTokenProvider` | family `no`

### Income

- `incomeRefreshTokenProvider` | `StateProvider` | `lib/features/income/presentation/providers/income_providers.dart` | deps `-` | refresh `self` | family `no`
- `incomeLocalDataSourceProvider` | `Provider` | `lib/features/income/presentation/providers/income_providers.dart` | deps `watch(isarProvider)` | refresh `-` | family `no`
- `incomeRepositoryProvider` | `Provider` | `lib/features/income/presentation/providers/income_providers.dart` | deps `watch(incomeLocalDataSourceProvider)` | refresh `-` | family `no`
- `getAllIncomeUseCaseProvider` | `Provider` | `lib/features/income/presentation/providers/income_providers.dart` | deps `watch(incomeRepositoryProvider)` | refresh `-` | family `no`
- `getIncomeForMonthUseCaseProvider` | `Provider` | `lib/features/income/presentation/providers/income_providers.dart` | deps `watch(incomeRepositoryProvider)` | refresh `-` | family `no`
- `saveIncomeUseCaseProvider` | `Provider` | `lib/features/income/presentation/providers/income_providers.dart` | deps `watch(incomeRepositoryProvider)` | refresh `-` | family `no`
- `deleteIncomeUseCaseProvider` | `Provider` | `lib/features/income/presentation/providers/income_providers.dart` | deps `watch(incomeRepositoryProvider)` | refresh `-` | family `no`
- `updateIncomeUseCaseProvider` | `Provider` | `lib/features/income/presentation/providers/income_providers.dart` | deps `watch(incomeRepositoryProvider)` | refresh `-` | family `no`
- `getIncomeTotalsUseCaseProvider` | `Provider` | `lib/features/income/presentation/providers/income_providers.dart` | deps `watch(incomeRepositoryProvider)` | refresh `-` | family `no`
- `incomeListControllerProvider` | `AsyncNotifierProvider` | `lib/features/income/presentation/providers/income_providers.dart` | deps `build: watch(incomeRefreshTokenProvider), read(getAllIncomeUseCaseProvider)` | refresh `incomeRefreshTokenProvider` | family `no`
- `thisMonthIncomeProvider` | `FutureProvider` | `lib/features/income/presentation/providers/income_providers.dart` | deps `watch(incomeRefreshTokenProvider)`; runtime reads `getIncomeTotalsUseCaseProvider` | refresh `incomeRefreshTokenProvider` | family `no`
- `lastMonthIncomeProvider` | `FutureProvider` | `lib/features/income/presentation/providers/income_providers.dart` | deps `watch(incomeRefreshTokenProvider)`; runtime reads `getIncomeTotalsUseCaseProvider` | refresh `incomeRefreshTokenProvider` | family `no`
- `incomeBySourceThisMonthProvider` | `FutureProvider` | `lib/features/income/presentation/providers/income_providers.dart` | deps `watch(incomeRefreshTokenProvider)`; runtime reads `getIncomeTotalsUseCaseProvider` | refresh `incomeRefreshTokenProvider` | family `no`
- `incomeMutationControllerProvider` | `Provider` | `lib/features/income/presentation/providers/income_providers.dart` | deps `-`; runtime reads `save/update/delete income use cases, walletLocalDataSourceProvider, activeWalletProvider, walletProvider.future` | refresh `-` | family `no`

### Wallet

- `walletLocalDataSourceProvider` | `Provider` | `lib/features/wallet/presentation/providers/wallet_provider.dart` | deps `watch(isarProvider)` | refresh `-` | family `no`
- `walletRepositoryProvider` | `Provider` | `lib/features/wallet/presentation/providers/wallet_provider.dart` | deps `watch(walletLocalDataSourceProvider)` | refresh `-` | family `no`
- `getWalletsUseCaseProvider` | `Provider` | `lib/features/wallet/presentation/providers/wallet_provider.dart` | deps `watch(walletRepositoryProvider)` | refresh `-` | family `no`
- `saveWalletUseCaseProvider` | `Provider` | `lib/features/wallet/presentation/providers/wallet_provider.dart` | deps `watch(walletRepositoryProvider)` | refresh `-` | family `no`
- `deleteWalletUseCaseProvider` | `Provider` | `lib/features/wallet/presentation/providers/wallet_provider.dart` | deps `watch(walletRepositoryProvider)` | refresh `-` | family `no`
- `archiveWalletUseCaseProvider` | `Provider` | `lib/features/wallet/presentation/providers/wallet_provider.dart` | deps `watch(walletRepositoryProvider)` | refresh `-` | family `no`
- `walletProvider` | `AsyncNotifierProvider` | `lib/features/wallet/presentation/providers/wallet_provider.dart` | deps `build: read(getWalletsUseCaseProvider)` | refresh `manual invalidate/refresh` | family `no`
- `activeWalletIdProvider` | `StateProvider` | `lib/features/wallet/presentation/providers/wallet_provider.dart` | deps `-` | refresh `-` | family `no`
- `activeWalletProvider` | `Provider` | `lib/features/wallet/presentation/providers/wallet_provider.dart` | deps `watch(activeWalletIdProvider, walletProvider)` | refresh `walletProvider` | family `no`
- `walletByIdProvider` | `Provider.family` | `lib/features/wallet/presentation/providers/wallet_provider.dart` | deps `watch(walletProvider)` | refresh `walletProvider` | family `yes`
- `totalBalanceProvider` | `Provider` | `lib/features/wallet/presentation/providers/wallet_provider.dart` | deps `watch(walletProvider)` | refresh `walletProvider` | family `no`
- `walletMonthlySpentProvider` | `FutureProvider.family` | `lib/features/wallet/presentation/providers/wallet_provider.dart` | deps `watch(expenseRefreshTokenProvider, expenseLocalDataSourceProvider)` | refresh `expenseRefreshTokenProvider` | family `yes`
- `walletBreakdownForMonthProvider` | `FutureProvider.family` | `lib/features/wallet/presentation/providers/wallet_provider.dart` | deps `watch(expenseRefreshTokenProvider, expenseLocalDataSourceProvider)` | refresh `expenseRefreshTokenProvider` | family `yes`

### Budget

- `budgetPlanLocalDataSourceProvider` | `Provider` | `lib/features/budget/presentation/providers/budget_provider.dart` | deps `watch(isarProvider)` | refresh `-` | family `no`
- `budgetPlannerDataSourceProvider` | `Provider` | `lib/features/budget/presentation/providers/budget_provider.dart` | deps `watch(connectivityServiceProvider)` | refresh `-` | family `no`
- `budgetRepositoryProvider` | `Provider` | `lib/features/budget/presentation/providers/budget_provider.dart` | deps `watch(budgetPlanLocalDataSourceProvider)` | refresh `-` | family `no`
- `getActiveBudgetUseCaseProvider` | `Provider` | `lib/features/budget/presentation/providers/budget_provider.dart` | deps `watch(budgetRepositoryProvider)` | refresh `-` | family `no`
- `getAllBudgetsUseCaseProvider` | `Provider` | `lib/features/budget/presentation/providers/budget_provider.dart` | deps `watch(budgetRepositoryProvider)` | refresh `-` | family `no`
- `saveBudgetUseCaseProvider` | `Provider` | `lib/features/budget/presentation/providers/budget_provider.dart` | deps `watch(budgetRepositoryProvider)` | refresh `-` | family `no`
- `updateBudgetUseCaseProvider` | `Provider` | `lib/features/budget/presentation/providers/budget_provider.dart` | deps `watch(budgetRepositoryProvider)` | refresh `-` | family `no`
- `setActiveBudgetUseCaseProvider` | `Provider` | `lib/features/budget/presentation/providers/budget_provider.dart` | deps `watch(budgetRepositoryProvider)` | refresh `-` | family `no`
- `deactivateAllUseCaseProvider` | `Provider` | `lib/features/budget/presentation/providers/budget_provider.dart` | deps `watch(budgetRepositoryProvider)` | refresh `-` | family `no`
- `budgetProvider` | `NotifierProvider` | `lib/features/budget/presentation/providers/budget_provider.dart` | deps `build: none`; microtask loader `read(getActiveBudgetUseCaseProvider, getAllBudgetsUseCaseProvider)`; runtime reads `connectivityServiceProvider, categoryProvider, budgetPlannerDataSourceProvider, expenseRepositoryProvider, budgetSettingsProvider, sharedPreferencesProvider` | refresh `manual invalidate/refresh` | family `no`
- `budgetPlanProvider` | `Provider` | `lib/features/budget/presentation/providers/budget_plan_provider.dart` | deps `watch(budgetProvider)` | refresh `budgetProvider` | family `no`

### Goals

- `goalLocalDataSourceProvider` | `Provider` | `lib/features/goals/presentation/providers/goal_provider.dart` | deps `watch(isarProvider)` | refresh `-` | family `no`
- `goalRepositoryProvider` | `Provider` | `lib/features/goals/presentation/providers/goal_provider.dart` | deps `watch(goalLocalDataSourceProvider)` | refresh `-` | family `no`
- `getAllGoalsUseCaseProvider` | `Provider` | `lib/features/goals/presentation/providers/goal_provider.dart` | deps `watch(goalRepositoryProvider)` | refresh `-` | family `no`
- `saveGoalUseCaseProvider` | `Provider` | `lib/features/goals/presentation/providers/goal_provider.dart` | deps `watch(goalRepositoryProvider)` | refresh `-` | family `no`
- `updateGoalUseCaseProvider` | `Provider` | `lib/features/goals/presentation/providers/goal_provider.dart` | deps `watch(goalRepositoryProvider)` | refresh `-` | family `no`
- `deleteGoalUseCaseProvider` | `Provider` | `lib/features/goals/presentation/providers/goal_provider.dart` | deps `watch(goalRepositoryProvider)` | refresh `-` | family `no`
- `addSavingUseCaseProvider` | `Provider` | `lib/features/goals/presentation/providers/goal_provider.dart` | deps `watch(goalRepositoryProvider)` | refresh `-` | family `no`
- `getGoalSavingsUseCaseProvider` | `Provider` | `lib/features/goals/presentation/providers/goal_provider.dart` | deps `watch(goalRepositoryProvider)` | refresh `-` | family `no`
- `markAchievedUseCaseProvider` | `Provider` | `lib/features/goals/presentation/providers/goal_provider.dart` | deps `watch(goalRepositoryProvider)` | refresh `-` | family `no`
- `cancelGoalUseCaseProvider` | `Provider` | `lib/features/goals/presentation/providers/goal_provider.dart` | deps `watch(goalRepositoryProvider)` | refresh `-` | family `no`
- `goalProvider` | `NotifierProvider` | `lib/features/goals/presentation/providers/goal_provider.dart` | deps `build: none`; microtask loader `read(getAllGoalsUseCaseProvider, markAchievedUseCaseProvider)` | refresh `manual reload` | family `no`
- `goalsProvider` | `Alias of goalProvider` | `lib/features/goals/presentation/providers/goal_provider.dart` | deps `same as goalProvider` | refresh `same as goalProvider` | family `no`
- `goalSavingsProvider` | `FutureProvider.family` | `lib/features/goals/presentation/providers/goal_provider.dart` | deps `read(goalProvider.notifier)` | refresh `manual invalidate only` | family `yes`

### Anomaly

- `anomalyProvider` | `NotifierProvider` | `lib/features/anomaly/presentation/providers/anomaly_provider.dart` | deps `build: watch(expenseRefreshTokenProvider), read(sharedPreferencesProvider)`; runtime reads `expenseRepositoryProvider, sharedPreferencesProvider` | refresh `expenseRefreshTokenProvider` | family `no`

### Recurring

- `recurringLocalDataSourceProvider` | `Provider` | `lib/features/recurring/presentation/providers/recurring_provider.dart` | deps `watch(isarProvider)` | refresh `-` | family `no`
- `recurringProvider` | `AsyncNotifierProvider` | `lib/features/recurring/presentation/providers/recurring_provider.dart` | deps `build: watch(expenseRefreshTokenProvider), read(expenseRepositoryProvider, recurringLocalDataSourceProvider)` | refresh `expenseRefreshTokenProvider` | family `no`

### Prediction

- `predictionDataSourceProvider` | `Provider` | `lib/features/prediction/presentation/providers/prediction_provider.dart` | deps `watch(connectivityServiceProvider)` | refresh `-` | family `no`
- `predictionExpenseRepositoryProvider` | `Provider` | `lib/features/prediction/presentation/providers/prediction_provider.dart` | deps `watch(expenseLocalDataSourceProvider)` | refresh `-` | family `no`
- `predictionRepositoryProvider` | `Provider` | `lib/features/prediction/presentation/providers/prediction_provider.dart` | deps `watch(predictionDataSourceProvider, isarProvider)` | refresh `-` | family `no`
- `getPredictionUseCaseProvider` | `Provider` | `lib/features/prediction/presentation/providers/prediction_provider.dart` | deps `watch(predictionRepositoryProvider)` | refresh `-` | family `no`
- `predictionProvider` | `NotifierProvider` | `lib/features/prediction/presentation/providers/prediction_provider.dart` | deps `build: none`; runtime reads `predictionRepositoryProvider, connectivityServiceProvider, predictionExpenseRepositoryProvider, getPredictionUseCaseProvider, sharedPreferencesProvider` | refresh `none` | family `no`

### Split Bill

- `splitBillLocalDataSourceProvider` | `Provider` | `lib/features/split/presentation/providers/split_bill_provider.dart` | deps `watch(isarProvider)` | refresh `-` | family `no`
- `splitBillRepositoryProvider` | `Provider` | `lib/features/split/presentation/providers/split_bill_provider.dart` | deps `watch(splitBillLocalDataSourceProvider)` | refresh `-` | family `no`
- `getAllSplitsUseCaseProvider` | `Provider` | `lib/features/split/presentation/providers/split_bill_provider.dart` | deps `watch(splitBillRepositoryProvider)` | refresh `-` | family `no`
- `saveSplitUseCaseProvider` | `Provider` | `lib/features/split/presentation/providers/split_bill_provider.dart` | deps `watch(splitBillRepositoryProvider)` | refresh `-` | family `no`
- `updateSplitUseCaseProvider` | `Provider` | `lib/features/split/presentation/providers/split_bill_provider.dart` | deps `watch(splitBillRepositoryProvider)` | refresh `-` | family `no`
- `deleteSplitUseCaseProvider` | `Provider` | `lib/features/split/presentation/providers/split_bill_provider.dart` | deps `watch(splitBillRepositoryProvider)` | refresh `-` | family `no`
- `markSettledUseCaseProvider` | `Provider` | `lib/features/split/presentation/providers/split_bill_provider.dart` | deps `watch(splitBillRepositoryProvider)` | refresh `-` | family `no`
- `splitBillReadyProvider` | `StateProvider` | `lib/features/split/presentation/providers/split_bill_provider.dart` | deps `-` | refresh `-` | family `no`
- `splitBillProvider` | `NotifierProvider` | `lib/features/split/presentation/providers/split_bill_provider.dart` | deps `build: none`; microtask loader `read(getAllSplitsUseCaseProvider, splitBillReadyProvider.notifier)` | refresh `manual reload` | family `no`

### Category

- `categoryLocalDataSourceProvider` | `Provider` | `lib/features/category/presentation/providers/category_provider.dart` | deps `watch(isarProvider)` | refresh `-` | family `no`
- `categoryRepositoryProvider` | `Provider` | `lib/features/category/presentation/providers/category_provider.dart` | deps `watch(categoryLocalDataSourceProvider)` | refresh `-` | family `no`
- `getCategoriesUseCaseProvider` | `Provider` | `lib/features/category/presentation/providers/category_provider.dart` | deps `watch(categoryRepositoryProvider)` | refresh `-` | family `no`
- `addCategoryUseCaseProvider` | `Provider` | `lib/features/category/presentation/providers/category_provider.dart` | deps `watch(categoryRepositoryProvider)` | refresh `-` | family `no`
- `updateCategoryUseCaseProvider` | `Provider` | `lib/features/category/presentation/providers/category_provider.dart` | deps `watch(categoryRepositoryProvider)` | refresh `-` | family `no`
- `deleteCategoryUseCaseProvider` | `Provider` | `lib/features/category/presentation/providers/category_provider.dart` | deps `watch(categoryRepositoryProvider)` | refresh `-` | family `no`
- `categoryProvider` | `NotifierProvider` | `lib/features/category/presentation/providers/category_provider.dart` | deps `build: none`; microtask loader `read(getCategoriesUseCaseProvider)`; runtime reads `add/update/delete category use cases, categoryLocalDataSourceProvider, isarProvider, expenseRefreshTokenProvider.notifier` | refresh `manual state changes` | family `no`

### Notification

- `notificationProvider` | `NotifierProvider` | `lib/core/notifications/notification_provider.dart` | deps `build: read(sharedPreferencesProvider)`; runtime reads `budgetSettingsProvider, expenseLocalDataSourceProvider` | refresh `none` | family `no`
- `budgetSettingsProvider` | `NotifierProvider` | `lib/core/notifications/budget_settings.dart` | deps `build: read(sharedPreferencesProvider)` | refresh `none` | family `no`

### Theme / Preferences / Core / Security / Other

- `sharedPreferencesProvider` | `Provider` | `lib/core/providers/shared_preferences_provider.dart` | deps `override required` | refresh `-` | family `no`
- `isarProvider` | `Provider` | `lib/core/providers/database_providers.dart` | deps `override required` | refresh `-` | family `no`
- `expenseLocalDataSourceProvider` | `Provider` | `lib/core/providers/database_providers.dart` | deps `watch(isarProvider)` | refresh `-` | family `no`
- `connectivityServiceProvider` | `Provider` | `lib/core/network/connectivity_provider.dart` | deps `-` | refresh `-` | family `no`
- `connectivityProvider` | `NotifierProvider` | `lib/core/network/connectivity_provider.dart` | deps `build: read(connectivityServiceProvider)`; `ref.onDispose(...)` subscription cleanup | refresh `service callback` | family `no`
- `biometricServiceProvider` | `Provider` | `lib/core/security/biometric_provider.dart` | deps `-` | refresh `-` | family `no`
- `biometricProvider` | `NotifierProvider` | `lib/core/security/biometric_provider.dart` | deps `build: read(sharedPreferencesProvider, biometricServiceProvider)` | refresh `none` | family `no`
- `themeBootstrapProvider` | `Provider` | `lib/core/theme/theme_provider.dart` | deps `-` | refresh `override/bootstrap only` | family `no`
- `themeProvider` | `NotifierProvider` | `lib/core/theme/theme_provider.dart` | deps `build: watch(themeBootstrapProvider)` | refresh `themeBootstrapProvider` | family `no`
- `exportCsvServiceProvider` | `Provider` | `lib/core/export/export_provider.dart` | deps `-` | refresh `-` | family `no`
- `exportProvider` | `NotifierProvider` | `lib/core/export/export_provider.dart` | deps `build: none`; runtime reads `exportCsvServiceProvider, expenseLocalDataSourceProvider` | refresh `manual state changes` | family `no`
