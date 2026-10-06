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

## Design tokens (indigo + brass) — rules for UI code
The palette lives in `lib/core/theme/app_tokens.dart` (`context.tokens`), built
into `ThemeData` by `app_theme.dart`. It is a re-skin of the old Google-blue
palette; spec in `docs/design/DESIGN_SPEC.md`.
- **Screens consume tokens, never colour literals.** `test/core/theme/
  no_hardcoded_colors_test.dart` is a ratchet: a new `Color(0x…)` or palette
  `Colors.*` outside `lib/core/theme/` fails; cleaning a file requires lowering its
  allowance. (`Colors.white/black/transparent` are fine.)
- **Text vs fill.** Text colours must be >= 4.5:1: use `successText`, `dangerText`,
  `warningText`, `expenseText`, `muted`, `ink`, `primary` — all theme-aware. The
  static `AppColors.success/error/warning/primaryMid` are for FILLS and ICONS only
  (>= 3:1 in both modes); a static const can never pass 4.5:1 on both a light and a
  dark surface. `test/core/theme/app_tokens_contrast_test.dart` enforces the table.
- **Filled controls** use `primaryFill` / `successFill` / `dangerFill` with the
  white `onFill` label (>= 4.5:1 in both modes). In dark mode `primary` (text/icon)
  and `primaryFill` (fills) are different values on purpose.
- **Brass is a jewel** — money / security / premium accents, EMI-and-debt markers
  and the SMS auto-import card only. In LIGHT mode it is a fill (with `onBrass`)
  or a `brassSoft` background, never text or an icon on white (2.14:1).
- **Text-field borders** use `inputOutline` (>= 3:1); `line`/`outline` are decorative.
- **Colours from data** (category, wallet, debt-status accents) go through
  `readableOn()` / `labelOnFill()` in `lib/core/theme/contrast.dart` (`AppChip` does
  this for you). Stored category colours are user data — never re-tint them.
- **Hero** (`heroGradient`, `onHero`, `onHeroMuted`) is deep indigo with white text
  in BOTH modes.

## Typography (R0b) — rules for UI code
Fonts are bundled (offline-first), all variable, all SIL OFL: **Inter** (body),
**Sora** (headings / big figures), **Noto Sans Bengali** (fallback for both).
Inter and Sora have no Bengali glyphs, so Bengali text, Bengali digits and ৳ all
render in Noto Sans Bengali — it is the app's real face; judge amount styles by it.
- **Use `AppTextStyles`** (or `Theme.of(context).textTheme`); never set `fontFamily`
  by hand. Each style already carries the family + Bengali fallback.
- **Weight = `fontWeight` only.** The variable `wght` axis follows it (proved by
  `test/core/theme/app_fonts_test.dart`). Never pin a `FontVariation('wght')` in a
  shared style: a variation overrides `fontWeight`, so every call-site
  `copyWith(fontWeight: …)` would silently stop working. Big money figures stay at
  600–700 (800 clots the counters of ৬/৯/৪).
- **No negative `letterSpacing`** on anything that can hold Bengali (it jams
  conjuncts and matras). Running text is `height: 1.5`; single-line figures >= 1.2.
- **`flutter_test` does not load pubspec fonts** (everything renders in the Ahem box
  font, so widths are meaningless). Layout/overflow tests must call
  `loadAppFonts()` from `test/helpers/app_fonts.dart`.
- Fixed-height cards must survive Bengali line heights and 1.3x system text:
  `test/core/theme/font_overflow_test.dart` renders the tight screens (Home hero,
  wallet strip, amount field, list rows, stat cards, bottom nav) at 320/360dp,
  ×1.0/×1.3, light + dark. Add new tight widgets there.
- Licenses: `lib/core/theme/font_licenses.dart` registers the OFL texts in
  `assets/fonts/licenses/` with `LicenseRegistry`. **The app has no licenses page
  yet** (no `showLicensePage`/`AboutListTile`); add an entry point under
  Settings → About.

## Release signing (slice h)
- `android/app/build.gradle.kts` signs `release` with the upload key described in
  `android/key.properties` (git-ignored, as are `*.jks` / `*.keystore`):
  ```properties
  storeFile=/Users/<you>/keys/pocketpilot/upload-keystore.jks
  storePassword=…
  keyAlias=upload
  keyPassword=…
  ```
- Keep the keystore **outside the repo** and back it up in two places (password
  manager + an offline copy). Enroll in Play App Signing so Google holds the app
  signing key and a lost upload key can be reset by support.
- Without `key.properties`, APK builds fall back to the debug key (local smoke
  builds only) and `bundleRelease` **refuses to run**, so a debug-signed AAB can't
  be produced by accident. Build-verification override:
  `ORG_GRADLE_PROJECT_allowDebugSignedBundle=true flutter build appbundle --release`.
- Ship `flutter build appbundle --release` (Play serves per-ABI splits, ~50 MB),
  not the ~120 MB fat APK.
- After the first Play upload, add the upload key's AND the Play app-signing
  certificate's SHA-1 to Firebase (Google Sign-In breaks in release otherwise).
- R8 is on (`isMinifyEnabled` + `isShrinkResources`); keep rules are in
  `android/app/proguard-rules.pro`. Do not blanket-keep Firebase/gms/ML Kit —
  they ship consumer rules and a blanket keep makes the APK bigger. After any
  dependency change, build a release APK and check
  `build/app/outputs/mapping/release/missing_rules.txt` is absent/empty, then smoke
  test on a device.

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
