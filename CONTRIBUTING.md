# Contributing to PocketPilot AI

## Workflow
1. Fork the repository.
2. Create a feature branch from `develop`.
3. Make focused changes with tests where applicable.
4. Run `flutter analyze` and `flutter test`.
5. Submit a pull request with a short description and screenshots for UI changes.

## Code generation (Isar)
Models under `lib/**/models/*.dart` use Isar codegen (`*.g.dart`). Regenerate with:

```bash
dart run build_runner build --delete-conflicting-outputs --force-jit
```

`--force-jit` is required on this toolchain (Dart 3.10.x + build_runner 2.14): the
default AOT build-script step fails because a native-build-hook dependency makes
`dart compile aot-snapshot` bail (`'dart compile' does not support build hooks`).
JIT mode avoids that path. Commit the regenerated `*.g.dart` alongside the model change.

## Store prep — must declare
- **Play Data Safety must declare usage analytics (added in slice g).** The app
  collects **anonymous app-activity / usage analytics** via Firebase Analytics
  (feature-open + entry-method events only — no financial amounts, SMS content or
  PII; not tied to identity). It is **on by default** with an in-app disclosure
  and a Settings opt-out. The Data Safety form must say: app-activity collected,
  **not** linked to identity, **not** shared, user can opt out. Do not ship the
  listing without this — default-on is only defensible with the honest disclosure.

## Known issues (deliberate deferrals)
- **`RecurringDetectionService` is demoted/reserved, not dead by accident.**
  Recurring is opt-in in Phase 1 (the user marks an expense recurring; see
  `RecurringNotifier.markExpenseAsRecurring`). The auto-detection service
  (`lib/features/recurring/data/services/recurring_detection_service.dart`) and
  the `ExpenseEntity.forRecurringDetection` filter are kept but **have no runtime
  callers** — reserved for a possible "suggest recurring patterns" opt-in helper
  later. Do not delete them assuming they are unused. Same policy as
  [ai_guide] and `ExpenseSource.goalDeposit`.
- **iOS build (CocoaPods) does not resolve — dedicated iOS-setup task.** `pod
  install` fails on two conflicts: `google_mlkit_text_recognition` (receipt OCR)
  vs `cloud_firestore`/Firebase over shared transitive pods (`nanopb`,
  `GoogleDataTransport`, `MLKitVision`), and the iOS Podfile specifies no
  `platform :ios` (defaults to 13.0, too low for current Firebase/MLKit). This is
  **pre-existing and does not block Phase 1** — the launch is Android-first, and
  MLKit powers the receipt-OCR feature which is **off in Phase 1**. Fix (bump the
  Podfile platform, align/drop the MLKit pods) belongs to the store-prep / iOS
  parity work (master §8 Phase-1 store-prep and Phase-3), not to a feature slice.
  Android builds and runs fine; verify UI on Android until iOS pods are fixed.
- **Currency symbol (DESYNC-3): ~18 raw-`৳` money-display sites still bypass the
  formatter.** `BanglaFormatters.currency` / `preciseCurrency` and every money
  entry field now honor the configured symbol (৳ / Tk / BDT). Deferred: raw
  `'৳${x.toStringAsFixed(0)}'` sites that render money with **Latin** digits —
  in AI/RAG context (`rag_context_builder`), anomaly messages
  (`anomaly_detection_service`), budget-planner narration
  (`budget_planner_datasource`), notifications (`notification_service`),
  prediction insight, and goal-detail. They are **tied to the Phase-1 AI-hide /
  insights rework (master §3, which makes prediction + budget-planner local)**:
  route them through `BanglaFormatters` when those surfaces are reworked, which
  also intentionally flips their digits Latin→Bangla. **Not** to change: SMS/
  receipt detection tokens, the app-icon glyph, and fixed BDT price strings —
  those are not display currency. Split's `৳` prefixes/parser are also left
  as-is because the Split tab is being cut (master §4).
- **`ExpenseSource.goalDeposit` is reserved / currently unused.** Goal deposits
  (task 5) are modelled as wallet→goal transfers recorded on `GoalSaving`
  (with `walletId`), NOT as `ExpenseRecordModel` rows — so no `goalDeposit`
  expense record is ever written, and the `goalDeposit` branches of the
  `countsIn*` filters are harmless no-ops. The enum value and its policy are
  kept as documented intent (and because pruning would touch the ordinal-lock
  test — `goalDeposit == 2`, `values.length == 3`). A later cleanup can remove
  it deliberately.
- **A debt/EMI payment to a deleted wallet now HARD-FAILS (behavior change).**
  Under the ledger the payment is one atomic transaction, so a missing target
  wallet makes the whole op fail — nothing persists (correct C1 direction; it
  used to silently succeed with a warning). Today the failure surfaces the raw
  `WalletLedgerException` message. The debt-payment UI should catch this and
  prompt the user to pick a valid wallet rather than showing a technical error —
  a follow-up for the UI task, for users who deleted a wallet a debt pointed at.
- **`deletePayment` is correct-but-unwired.** `DebtMutationController.deletePayment`
  reverses a payment atomically (deletes the payment + linked expense, refunds
  the wallet, rolls back the debt) and is fully tested, but no UI entry point
  calls it yet. Wiring a "delete payment" control is a later UI task.
- **Editing a debt principal does not reconcile the wallet.** `updateDebt` changes
  the debt's amount but never adjusts the wallet for the difference (it never
  did — only create/delete/payment move the wallet). Pre-existing and arguably
  correct (editing a record shouldn't retroactively move cash); left as-is.
- **Logging a pre-existing debt inflates the wallet.** Creating a debt applies the
  full principal to the wallet (`_originalWalletDelta` — an "I owe" debt credits
  the wallet by the borrowed amount). So recording a debt you already spent/hold
  overstates your wallet balance. This is preserved as-is (creation is a true
  behavior-preserving migration onto the ledger); fixing it (e.g. an
  "already received?" toggle) is a separate product decision.
- **Expense dedupe is a TOCTOU race.** `ExpenseMutationController._isDuplicateExpense`
  runs as a read *before* the write (outside the ledger transaction), so two
  rapid identical saves can both pass the check and then both write. The ledger
  migration (task 3) deliberately preserves this as-is — it is a behavior-
  preserving refactor, not a dedupe fix. Closing the race (e.g. a uniqueness
  guard inside the write transaction) is a separate follow-up.

## Commit Style
- `feat:` new feature
- `fix:` bug fix
- `refactor:` internal improvement
- `docs:` documentation update
- `test:` tests only
- `chore:` maintenance

## Pull Requests
- Keep PRs small and reviewable.
- Include before/after screenshots for UI work.
- Mention any migration, environment, or seed-data impact.
