# PocketPilot AI — Full Code & Feature Review

**Reviewed on:** 2026-04-28
**Reviewer:** Claude Code (automated review)
**Scope:** Last 3 commits (`a1e6794`, `6f7dd58`, `6d64ff3`) + Budget ↔ Category data connection audit
**Files changed:** 196 files · ~31,700 insertions · ~14,400 deletions

---

## Table of Contents

1. [Release Summary](#1-release-summary)
2. [Bugs](#2-bugs)
3. [Improvements](#3-improvements)
4. [UI Issues](#4-ui-issues)
5. [Budget ↔ Category Connection Audit](#5-budget--category-connection-audit)
6. [AI Features Inventory](#6-ai-features-inventory)
7. [AI Data Flow Map](#7-ai-data-flow-map)
8. [Privacy & Cost Notes](#8-privacy--cost-notes)

---

## 1. Release Summary

These three commits cover four major areas:

| Commit | What changed |
|---|---|
| `6d64ff3` feat: rebrand app | SmartSpend → PocketPilot AI; `isar` → `isar_community` migration; icon assets; platform config |
| `6f7dd58` feat: update dashboard screen | Large UI refactor across expense, analytics, budget, settings, goals, income, split, and chat screens |
| `a1e6794` feat: debt feature and latest updates | New full debt/EMI feature; SMS auto-import for bKash/Nagad/Rocket/Bank; chat input extracted; AI Guide screen |

**Overall quality:** Architecture is clean and consistent. The debt feature follows domain-driven design well. The main risks are in data integrity (budget ↔ category coupling), two silent failure points, and a duplicate SMS parser implementation.

---

## 2. Bugs

### BUG-01 — `late bool deleted` — potential LateInitializationError
**Severity:** High
**File:** `lib/features/debt/data/datasources/debt_local_datasource.dart`

Both `deleteDebt()` and `deletePayment()` declare `late bool deleted` and assign it inside the Isar `writeTxn` callback. If Isar throws before the callback body executes, reading `deleted` after the `await` will throw a `LateInitializationError` at runtime.

```dart
// Current — risky
late bool deleted;
await _isar.writeTxn(() async {
  deleted = await _isar.debtModels.delete(id);
  ...
});
return deleted; // ← LateInitializationError if writeTxn threw early
```

**Fix:** Initialize to `false` upfront:
```dart
bool deleted = false;
await _isar.writeTxn(() async {
  deleted = await _isar.debtModels.delete(id);
  ...
});
return deleted;
```

---

### BUG-02 — Double `toList()` wastes allocation
**Severity:** Medium
**File:** `lib/features/debt/presentation/providers/debt_providers.dart` · line 109

```dart
final sorted = debts.toList(growable: false).toList(); // second .toList() is redundant
sorted.sort(...);
```

`toList(growable: false)` returns a fixed-length list. The chained `.toList()` allocates a second growable copy for no reason. Since `.sort()` works fine on fixed-length lists, the first call alone is enough.

**Fix:**
```dart
final sorted = debts.toList();
sorted.sort(...);
```

---

### BUG-03 — `_aiGuidePromptSeen` initialized to `true` — prompt never shows on first launch
**Severity:** Medium
**File:** `lib/features/chat/presentation/screens/chat_screen.dart` · line 93

```dart
bool _aiGuidePromptSeen = true; // ← always true before prefs load
```

The field is initialized to `true` and then set from `SharedPreferences` in `_loadAiGuidePromptState()`, which is async. On first launch, if the async call hasn't resolved yet (or prefs has no stored value), this stays `true` and the AI guide prompt never appears.

**Fix:** Initialize to `false` so the guide shows until prefs explicitly marks it as seen:
```dart
bool _aiGuidePromptSeen = false;
```

---

### BUG-04 — SMS parser silently swallows all exceptions
**Severity:** Medium
**File:** `lib/core/sms/sms_parser.dart` · `tryParse()` method

```dart
try {
  return _tryParseBkash(...) ?? _tryParseNagad(...) ?? ...;
} catch (_) {
  return null; // ← swallows RangeError, FormatException, everything
}
```

Any regex match group access error, null cast, or unexpected format is silently discarded. This makes debugging bad SMS formats impossible in production.

**Fix:** Log in debug mode at minimum:
```dart
} catch (e, st) {
  assert(() {
    debugPrint('[SmsParser] Parse failed for "${sms.address}": $e\n$st');
    return true;
  }());
  return null;
}
```

---

### BUG-05 — Category rename in budget silently fails with no user feedback
**Severity:** Medium
**File:** `lib/features/category/presentation/providers/category_provider.dart` · lines 278–294

When a category is renamed, the provider tries to remap the key in the active budget. If that remap throws (e.g., budget provider not yet initialized), the exception is caught and logged to console only. The user sees a successful rename but the budget silently retains the old category name — data becomes inconsistent.

```dart
try {
  await ref.read(budgetProvider.notifier).remapCategoryInBudget(oldName, newName);
} catch (error) {
  debugPrint('[CategoryProvider] Active budget remap failed: $error');
  // No rethrow, no SnackBar, no retry
}
```

**Fix:** At minimum surface a warning SnackBar so the user knows to check their budget.

---

### BUG-06 — Version downgraded from `1.0.0+1` to `0.1.0+1`
**Severity:** Medium
**File:** `pubspec.yaml`

The version number went backwards. For any existing install (TestFlight, Play internal track, or direct APK), the OS or store sees a lower version and may refuse to install or prevent upgrades.

**Fix:** Bump to `1.1.0+2` or higher. Never lower a published version number.

---

### BUG-07 — `updateCategoryBudget()` writes unvalidated category names
**Severity:** High
**File:** `lib/features/budget/presentation/providers/budget_provider.dart` · lines 229–261

When a user manually edits a budget amount in the dashboard, `updateCategoryBudget(category, amount)` writes the key directly to Isar with zero check that the category still exists in the registry. A deleted category can be re-introduced into the active budget from the UI.

```dart
Future<void> updateCategoryBudget(String category, double amount) async {
  // No check: does this category still exist?
  final updatedBudgets = Map<String, double>.from(
    currentBudget.categoryBudgets,
  )..[category] = sanitizedAmount; // ← can write orphaned key
```

**Fix:**
```dart
final knownNames = ref.read(categoryProvider).map((c) => c.name).toSet();
if (!knownNames.contains(category)) return;
```

---

## 3. Improvements

### IMP-01 — Two parallel SMS parsers will diverge
**Priority:** High
**Files:**
- `lib/core/sms/sms_parser.dart` (781 lines — monolithic `SmsParserEngine`)
- `lib/features/sms_import/data/parsers/` (strategy pattern: `BkashSmsParser`, `NagadSmsParser`, `RocketSmsParser`, `BankSmsParser`, `SmsParserUtils`)

Both systems parse bKash, Nagad, Rocket, and bank SMS messages. They use slightly different regex patterns and keyword lists. When a new bKash format is supported, someone must update both systems or they diverge. The `core/sms/` implementation appears to be an earlier prototype that was not removed when the cleaner `features/sms_import/` strategy-based version was added.

**Fix:** Delete `lib/core/sms/sms_parser.dart` and the surrounding `lib/core/sms/` files. Route all parsing through the strategy-based `BangladeshFinancialSmsParser` in `features/sms_import/`.

---

### IMP-02 — `chatSuggestionHistoryProvider` defined inside a screen file
**Priority:** Medium
**File:** `lib/features/chat/presentation/screens/chat_screen.dart` · line 62

File-level Riverpod providers belong in provider files, not screen files. This provider also calls `ref.watch(expenseLocalDataSourceProvider)` directly — bypassing the repository layer — which couples the screen to the data layer.

**Fix:** Move to `lib/features/chat/presentation/providers/chat_suggestion_provider.dart` and route through `expenseRepositoryProvider`.

---

### IMP-03 — Historical budget plans never cleaned up on category rename or delete
**Priority:** High
**File:** `lib/features/budget/presentation/providers/budget_provider.dart` · `remapCategoryInBudget()` and `removeCategoryFromBudget()`

When a category is renamed or deleted, only the **active** budget plan is updated. Any saved historical budget plan retains the stale string key. If the user later restores a historical plan, the old/deleted category reappears.

**Fix:** Add a `migrateCategory(oldName, newName)` method to `BudgetPlanLocalDataSource` that updates all stored plans in a single `writeTxn`:
```dart
Future<void> migrateCategory(String oldName, String newName) async {
  final all = await _isar.budgetPlanModels.where().findAll();
  final dirty = <BudgetPlanModel>[];
  for (final plan in all) {
    final budgets = plan.decodedCategoryBudgets;
    if (budgets.containsKey(oldName)) {
      budgets[newName] = budgets.remove(oldName)!;
      plan.categoryBudgetsJson = jsonEncode(budgets);
      dirty.add(plan);
    }
  }
  if (dirty.isEmpty) return;
  await _isar.writeTxn(() async => _isar.budgetPlanModels.putAll(dirty));
}
```

---

### IMP-04 — Budget and notification budget settings can desync
**Priority:** Medium
**Files:** `lib/features/budget/presentation/providers/budget_provider.dart` · `_updateNotificationBudgets()` and `lib/core/notifications/budget_settings.dart`

Budget data exists in two places: Isar (`BudgetPlanModel`) and `SharedPreferences` (`BudgetSettings` for notification thresholds). They're updated in sequence — if the Isar write succeeds but the SharedPrefs write fails, or the app is killed between the two writes, they silently diverge.

**Fix:** Derive notification budgets on-read from Isar instead of maintaining a separate copy. Remove `BudgetSettings.categoryBudgets` and read directly from the active budget plan when scheduling notifications.

---

### IMP-05 — `AI_FEATURES_REVIEW.md` committed to source control
**Priority:** Low
**File:** `AI_FEATURES_REVIEW.md` (this file)

Planning and review documents should not be in the repository unless they are living technical docs (ADRs, etc.). Add to `.gitignore` or move to a wiki.

---

### IMP-06 — `flutter_launcher_icons` removed with no replacement workflow
**Priority:** Low
**File:** `pubspec.yaml`

The `flutter_launcher_icons` package and its config were removed. Icons were manually committed as PNG files across all densities. This means icon regeneration from source (`assets/icon/app_icon.png`) is no longer automated — future icon changes require manually exporting every density.

**Fix:** Restore `flutter_launcher_icons` in `dev_dependencies` with the config block, or document the manual icon export process.

---

### IMP-07 — RAG context includes budget categories without validating they still exist
**Priority:** Medium
**File:** `lib/core/ai/rag_context_builder.dart` · lines 212–216

When RAG builds the "Active Budget Plan" context block, it iterates all keys in `budgetPlan.categoryBudgets` without checking whether those categories still exist in the current category registry. If a category was deleted after the budget was created, the AI receives stale context.

**Fix:**
```dart
final currentCategoryNames = currentCategories.map((c) => c.name).toSet();
for (final entry in budgetPlan.categoryBudgets.entries) {
  if (!currentCategoryNames.contains(entry.key)) continue; // skip orphaned
  buffer.writeln('  ${entry.key}: ${BanglaFormatters.currency(entry.value)}/month');
}
```

---

### IMP-08 — No tests for debt feature
**Priority:** Medium

The debt feature (464-line datasource, 919-line provider, 2 screens, 3 sheets) has no unit or integration tests. The SMS import feature has a good parser test, but the debt payment cascade, EMI calculation, and overdue status logic are untested.

**Recommended test targets:**
- `DebtLocalDataSource.deletePayment()` — reversal logic is complex
- `EmiCalculator` — financial calculations
- `sortDebtsForDisplay()` — sorting logic with 5 rank tiers
- `updateOverdueStatuses()` — date comparison logic

---

## 4. UI Issues

### UI-01 — Budget dashboard renders orphaned category rows
**Severity:** Medium
**File:** `lib/features/budget/presentation/widgets/budget_dashboard.dart`

The dashboard iterates `budget.categoryBudgets.entries` and renders a row for every key, including keys for categories that no longer exist in the category registry. An orphaned row shows a generic icon, possibly incorrect spend totals, and no indication to the user that the data is stale.

**Fix:** Filter entries against the current category list before rendering. Optionally show a subtle "Category removed" label for any orphaned row so the user can clean it up.

---

### UI-02 — No user-facing warning when category remap fails
**Severity:** Medium
**File:** `lib/features/category/presentation/providers/category_provider.dart` · `_remapBudgetCategory()`

If the budget remap silently fails after a category rename (see BUG-05), the user has no way to know. They see "Category renamed" as success but their budget is out of sync.

**Fix:** Show a `SnackBar` warning: *"Category renamed, but budget could not be updated automatically. Please review your budget."*

---

### UI-03 — No warning when restoring a historical budget with deleted categories
**Severity:** Medium
**File:** `lib/features/budget/presentation/screens/budget_planner_screen.dart`

When a user restores or activates a historical budget plan that contains category names no longer in the registry, there is no warning. The stale categories are silently added back to the active budget.

**Fix:** Before activating a historical plan, check for orphaned keys and show a confirmation dialog: *"This plan contains 2 categories that no longer exist (Custom, Misc). They will be removed when you activate it."*

---

### UI-04 — No orphaned category indicator anywhere in the app
**Severity:** Low

There is no screen, badge, or report that shows the user:
- Categories referenced in their active budget that no longer exist
- Categories referenced in expense history that are not in the current registry
- Budget plans with stale category keys

A user who has been using the app for months and deleted/renamed categories has no visibility into this.

**Fix:** Add an entry to the Settings screen — *"Budget health check"* — that lists any orphaned category references and offers one-tap cleanup.

---

### UI-05 — `CategoryIcon.getColor()` uses hardcoded map — unknown categories get a silent default
**Severity:** Low
**File:** `lib/core/utils/category_icon.dart` (referenced from `budget_dashboard.dart`)

For category names not in the hardcoded map (e.g., a user's custom category), `getColor()` returns a default color with no indication. In the budget dashboard, a custom category's progress bar silently uses the wrong color, which is confusing.

**Fix:** Pass the `CategoryEntity.colorValue` from the provider down to the dashboard widget instead of looking up by name string.

---

## 5. Budget ↔ Category Connection Audit

### How They Connect Today

Categories are referenced inside budget plans by **name string only**. The `BudgetPlanEntity.categoryBudgets` field is `Map<String, double>` — the string key is the category name. This is serialized as JSON in Isar. There is no foreign key, no ID link, and no database-level referential integrity.

```
CategoryEntity.id   →  NOT referenced in BudgetPlanModel
CategoryEntity.name →  BudgetPlanModel.categoryBudgetsJson keys
```

### What IS Connected

| Flow | How | Location |
|---|---|---|
| Budget generation reads live categories | `categoryProvider` names passed to AI | `budget_provider.dart` · `generateBudget()` |
| AI output filtered to known categories | `availableCategories.contains()` check | `budget_provider.dart` · `_parseResponse()` |
| All categories seeded into new budget | `putIfAbsent(..., () => 0.0)` | `budget_provider.dart` line 448 |
| Category rename updates active budget key | `_remapBudgetCategory()` → `remapCategoryInBudget()` | `category_provider.dart` line 278 |
| Category delete removes from active budget | `_removeBudgetCategory()` → `removeCategoryFromBudget()` | `category_provider.dart` line 296 |
| Category rename updates notification budget | `BudgetSettingsNotifier.remapCategory()` | `budget_settings.dart` line 114 |
| Category delete updates notification budget | `BudgetSettingsNotifier.removeCategory()` | `budget_settings.dart` line 128 |

### What Is NOT Connected (Gaps)

| Gap | Risk | Described in |
|---|---|---|
| `updateCategoryBudget()` has no category validation | High — can write orphaned key | BUG-07 |
| Historical budget plans not updated on rename/delete | High — stale keys persist in history | IMP-03 |
| Remap/delete failures not surfaced to user | Medium — silent data inconsistency | BUG-05, UI-02 |
| Budget dashboard renders orphaned rows | Medium — misleading UI | UI-01 |
| RAG context includes stale category names | Medium — confuses AI responses | IMP-07 |
| Isar + SharedPrefs budget copies can desync | Medium — notification budgets wrong | IMP-04 |
| No orphaned category detection in UI | Low — user blind to stale data | UI-04 |
| `CategoryIcon.getColor()` ignores entity color | Low — wrong color for custom categories | UI-05 |

### Connection Architecture Diagram

```
CategoryEntity (Isar)
  │
  ├── name (String) ──────────────────────────────────┐
  │                                                    │
  │   On rename → _remapBudgetCategory()               │ (string key only,
  │   On delete → _removeBudgetCategory()              │  no FK, no ID link)
  │                                                    ▼
  └─────────────────────────────────► BudgetPlanEntity.categoryBudgets
                                        Map<String, double>
                                              │
                              ┌───────────────┴──────────────────┐
                              ▼                                   ▼
                     Isar BudgetPlanModel                 SharedPreferences
                     categoryBudgetsJson (JSON)           BudgetSettings
                              │                                   │
                              └───────────── desync risk ─────────┘
```

### Recommended Fix Priority

1. **Immediate:** Add category validation in `updateCategoryBudget()` — one line (BUG-07)
2. **Short term:** Extend remap/delete to all historical budget plans, not just active (IMP-03)
3. **Short term:** Surface remap failures as SnackBar warnings (BUG-05 / UI-02)
4. **Medium term:** Add orphaned row guard in budget dashboard with "Category removed" label (UI-01)
5. **Medium term:** Filter RAG context against live categories (IMP-07)
6. **Long term:** Consolidate budget storage to a single Isar source of truth (IMP-04)
7. **Long term:** Add a "Budget health check" screen in Settings (UI-04)

---

## 6. AI Features Inventory

| Feature | Status | Engine | What it does | Main files |
|---|---|---|---|---|
| Bengali AI chat assistant | Implemented | OpenAI `gpt-4o-mini` | Streams Bengali finance assistant replies, detects structured finance actions | `lib/features/chat/data/datasources/openai_chat_datasource.dart` |
| Natural-language expense entry | Implemented | OpenAI + parser | Converts Bengali/English messages into confirmable expense drafts | `lib/core/ai/expense_parser.dart`, `lib/core/ai/expense_result.dart` |
| Natural-language income entry | Implemented | OpenAI + parser | Detects income entries, source type, recurring flag, and date | `lib/core/ai/income_data.dart` |
| Mixed expense + income extraction | Implemented | OpenAI + parser | Parses responses containing both expenses and incomes | `lib/core/ai/expense_parser.dart` |
| Voice input | Implemented | OpenAI Whisper `whisper-1` | Records audio, transcribes speech, feeds into chat flow | `lib/core/audio/voice_recorder_service.dart` |
| Receipt/image read | Implemented | Google ML Kit OCR + OpenAI | Local OCR → OpenAI parses merchant, amount, category | `lib/core/scanner/receipt_scanner_service.dart` |
| RAG personal finance Q&A | Implemented | Local context + OpenAI | Answers questions using local Isar finance data as context | `lib/core/ai/rag_context_builder.dart` |
| RAG visual cards | Implemented | Parser + UI | Renders structured finance cards from RAG answers | `lib/features/chat/presentation/widgets/rag/` |
| AI budget planner | Implemented | OpenAI `gpt-4o-mini` | Generates category-level budget from income and spending history | `lib/features/budget/data/datasources/budget_planner_datasource.dart` |
| Expense prediction | Implemented | OpenAI `gpt-4o-mini` | Predicts end-of-month spend, category forecasts, Bengali tips | `lib/features/prediction/data/datasources/prediction_datasource.dart` |
| Anomaly detection | Implemented | Local statistical rules | Detects category spikes, large transactions, frequency increases | `lib/features/anomaly/data/services/anomaly_detection_service.dart` |
| Recurring expense detection | Implemented | Local statistical rules | Detects weekly/monthly patterns by category and description | `lib/features/recurring/data/services/recurring_detection_service.dart` |
| Split bill suggestion | Implemented | AI parser + local calc | Detects split intent, calculates per-person amounts | `lib/features/split/presentation/widgets/split_suggestion_widget.dart` |
| SMS auto-import | New (a1e6794) | Local parsers | Parses bKash, Nagad, Rocket, bank SMS into transaction records | `lib/features/sms_import/data/parsers/` |
| Debt / EMI tracker | New (a1e6794) | Local + Isar | Tracks debts, installments, overdue status, payment history | `lib/features/debt/` |
| Token usage + rate limits | Implemented | OpenAI metadata | Tracks estimated tokens and rate-limit headers per service | `lib/core/ai/token_usage.dart` |

---

## 7. AI Data Flow Map

### Chat Text Flow
```
ChatScreen
  → ChatNotifier / chatProvider
  → SendMessageUseCase
  → ChatRepositoryImpl
  → OpenAiChatDataSource
  → OpenAI gpt-4o-mini (streaming)
  → ExpenseParser / RagResponseParser
  → MessageBubble + confirmation widgets / RAG cards
```

### Voice Flow
```
Mic button
  → VoiceRecorderService (record locally)
  → OpenAiVoiceDataSource
  → OpenAI Whisper whisper-1 (transcript)
  → normal chat text flow
```

### Receipt / Image Flow
```
Camera or Gallery
  → ReceiptScannerService
  → ReceiptImagePreprocessor
  → Google ML Kit OCR (on-device)
  → ReceiptFormatChecker
  → OpenAiReceiptDataSource
  → ReceiptConfirmationWidget
```

### RAG Flow
```
RAG toggle enabled
  → RagContextBuilder reads local Isar data
  → RagPromptBuilder injects context into system prompt
  → OpenAiChatDataSource streams answer
  → RagResponseParser selects card type
  → RAG card widget renders structured finance answer
```

### SMS Import Flow
```
SMS permission granted
  → AndroidSmsReaderService reads device inbox
  → BangladeshFinancialSmsParser dispatches to brand parsers
      → BkashSmsParser / NagadSmsParser / RocketSmsParser / BankSmsParser
  → ParsedSmsTransactionEntity created
  → SmsAutoImportEngine saves to Isar
```

---

## 8. Privacy & Cost Notes

- OpenAI receives chat messages and generated local context when AI chat or RAG is used.
- OpenAI receives audio files when voice transcription is used.
- OpenAI receives OCR-extracted receipt text (not the raw image) for receipt parsing.
- Google ML Kit OCR runs **locally on device** — no image leaves the device.
- SMS messages are read locally. Parsed transaction data is stored in Isar only. SMS text is NOT sent to any external API.
- Local Isar data is used to build RAG context, predictions, anomaly reports, recurring patterns, and budget recommendations.
- OpenAI API usage depends on `OPENAI_API_KEY` from `.env`.
- Token usage is tracked in-app but final billing must be verified from the OpenAI dashboard.

---

## Issue Index

| ID | Category | Severity | Title |
|---|---|---|---|
| BUG-01 | Bug | High | `late bool deleted` — LateInitializationError risk in debt datasource |
| BUG-02 | Bug | Medium | Double `toList()` — redundant allocation in debt providers |
| BUG-03 | Bug | Medium | `_aiGuidePromptSeen = true` — AI guide prompt never shows on first launch |
| BUG-04 | Bug | Medium | SMS parser swallows all exceptions silently |
| BUG-05 | Bug | Medium | Category rename failure not surfaced to user — silent budget desync |
| BUG-06 | Bug | Medium | Version downgraded `1.0.0+1` → `0.1.0+1` — blocks upgrades |
| BUG-07 | Bug | High | `updateCategoryBudget()` writes unvalidated / orphaned category names |
| IMP-01 | Improvement | High | Two parallel SMS parsers — will diverge; remove `lib/core/sms/` |
| IMP-02 | Improvement | Medium | `chatSuggestionHistoryProvider` defined in screen file, bypasses repository |
| IMP-03 | Improvement | High | Historical budget plans not updated when category renamed or deleted |
| IMP-04 | Improvement | Medium | Isar and SharedPrefs budget copies can desync |
| IMP-05 | Improvement | Low | `AI_FEATURES_REVIEW.md` should not be committed to source control |
| IMP-06 | Improvement | Low | `flutter_launcher_icons` removed — icon regeneration now manual |
| IMP-07 | Improvement | Medium | RAG context includes budget categories not validated against live registry |
| IMP-08 | Improvement | Medium | No unit tests for debt feature (datasource, EMI calc, sort logic) |
| UI-01 | UI Issue | Medium | Budget dashboard renders orphaned category rows without warning |
| UI-02 | UI Issue | Medium | No SnackBar when category remap fails after rename |
| UI-03 | UI Issue | Medium | No warning when restoring a historical budget with deleted categories |
| UI-04 | UI Issue | Low | No "Budget health check" — user cannot see orphaned category data |
| UI-05 | UI Issue | Low | `CategoryIcon.getColor()` uses hardcoded map — custom categories get wrong color |
