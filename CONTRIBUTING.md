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

## Net-worth snapshots (G1) — rules
- `NetWorthSnapshotModel` records মোট সম্পদ once per local day, forward-only (no
  backfill — opening balances and debt principal bypass expense records, so a
  reconstruction would be silently wrong). Capture is open-based: first frame +
  every resume (`NetWorthSnapshotService.captureIfNeeded`); days the app wasn't
  opened are gaps, never invented.
- One row per `dayKey` (`yyyymmdd`); later same-day resumes refresh it only if the
  total or a wallet balance changed. The first open after a month-end keeps its real
  date. Retention: daily 90 days -> weekly to 12 months -> the first AND last
  snapshot of every month forever.
- **Net worth has ONE definition: `netWorthOf()`** (`wallet/domain/entities/
  net_worth.dart`), shared by `totalBalanceProvider` and the snapshots. Don't
  re-implement the sum.
- **Every new Isar collection must be added to all of:** `Isar.open` in `main.dart`,
  `IsarExportService` (export + import), `clearAllUserCollections()`
  (`core/database/clear_all_data.dart`, "সব ডেটা মুছুন"), and the schema lists in the
  backup tests.
- Backup format stays `version: 1`; `netWorthSnapshots` is an additive key. Restoring
  an older backup without it keeps local snapshots (that history can't be rebuilt).

## Backup safety (G2) — rules
- **Auto-backup is `AutoBackupCoordinator`** (`core/backup/`), run on first frame and
  on every resume. Rules, in order: setting on -> allowed (Premium, or grandfathered)
  -> last SUCCESS >= 24h ago (a manual backup counts) -> no manual op / attempt in
  flight -> no failure in the last hour -> **online (live `ConnectivityService`
  check; offline is a skip, never a failure)** -> signed in -> run.
- **It never touches the manual 1/day quota** (`usageTrackerServiceProvider` is not
  a dependency; a test asserts zero calls). Keep it that way — the old code burned the
  user's manual backup on every silent run, even failed ones.
- Failures are logged with a cause code only (`network|auth|drive|unknown`, no
  messages/amounts/PII) and stored (`auto_backup_last_failed_at/_error_code`);
  Settings shows "শেষ ব্যাকআপ ব্যর্থ" with আবার চেষ্টা until a later success.
- **Premium gating:** free users can't switch it ON. Free users who already had it on
  when this shipped were grandfathered once (`auto_backup_grandfathered`); switching
  it off (or delete-all) ends that. A lapsed Premium shows "বন্ধ আছে — Premium মেয়াদ
  শেষ" instead of silently stopping.
- **Home reminder (free for everyone):** `BackupReminderCard`, rules in
  `backup_reminder_policy.dart` (>=10 records or any debt/goal; last backup >=30 days;
  never backed up: 30 days from `app_first_seen_at`, 7 days if >=30 records; "পরে"
  snoozes 7 days). Analytics: `backup_reminder` {shown|tapped|dismissed}.
- `app_first_seen_at` is the only install-age marker (written on the first G2+ run);
  the wallet seed `createdAt` is a constant, not an install date.
- Gotcha fixed in G2: `BackupNotifier.build()` must not call `refreshCloudInfo()`
  inline — it reads `state` while build is still running and overwrote the real state
  with `BackupState.initial()`.

## Receipt OCR is removed in Phase 1 — restoring it in Phase 2
Google ML Kit text recognition (and `image_picker`, the CAMERA permission and the iOS
camera/photo strings that only it needed) were removed: they cost ~15 MB per ABI
and made `pod install` fail (MLKitVision/nanopb vs Firebase). Nothing else in the app
used the camera or `image_picker` (grep-verified: profile photos, attachments etc. do
not exist; `Share.shareXFiles`' `XFile` comes from share_plus).

Phase 1 ships `NoopOcrService` + `NoopReceiptImageSource` behind the real
`ReceiptScannerService` pipeline (`lib/core/scanner/`, `lib/core/ocr/`), which stays
compiled and unit-tested. Reference implementations from commit `66cd9b7` (the last
commit with ML Kit) are in `docs/phase2/*.dart.txt` — **re-verify them against the
then-current plugin APIs**. To restore:
1. **Dependencies** (`pubspec.yaml`): `google_mlkit_text_recognition` and `image_picker`.
2. **Files**: copy `docs/phase2/ml_kit_ocr_service.dart.txt` ->
   `lib/core/ocr/ml_kit_ocr_service.dart` (class `MlKitOcrService implements OcrService`)
   and `image_picker_receipt_source.dart.txt` ->
   `lib/core/scanner/image_picker_receipt_source.dart`.
3. **Providers** (`chat_provider.dart`): `ocrServiceProvider` returns
   `MlKitOcrService()` (keep the `onDispose`), `receiptImageSourceProvider` returns
   `ImagePickerReceiptSource()`.
4. **Android permissions** (`AndroidManifest.xml`):
   `<uses-permission android:name="android.permission.CAMERA" />` and
   `<uses-feature android:name="android.hardware.camera" android:required="false" />`.
5. **Gradle** (`android/app/build.gradle.kts`, `dependencies`): only if the Bengali/other
   script models are wanted beyond Latin — the four
   `com.google.mlkit:text-recognition-{chinese,devanagari,japanese,korean}:16.0.1` lines
   (they were what made the APK ~15 MB bigger). Bengali itself is NOT covered by ML Kit's
   Latin model: evaluate recognition quality on real Bangladeshi receipts first.
6. **Proguard** (`android/app/proguard-rules.pro`):
   `-keep class com.google_mlkit_commons.** { *; }`,
   `-keep class com.google_mlkit_text_recognition.** { *; }`, `-dontwarn com.google.mlkit.**`.
7. **iOS** (`ios/Runner/Info.plist`): `NSCameraUsageDescription` ("Receipt scan করতে camera
   দরকার") and `NSPhotoLibraryUsageDescription` ("Gallery থেকে receipt select করতে").
   **`pod install` will fail again** (MLKitVision/nanopb vs Firebase) and ML Kit needs a
   much higher iOS deployment target than the current `platform :ios, '13.0'` — resolve
   before enabling OCR on iOS.
8. Re-run both test modes, build a release APK + AAB, and re-measure per-ABI size.

## Advertising ID is removed in Phase 1 — re-adding it with AdMob (Phase 2)
Phase 1 shows no ads, so the app does not use the Advertising ID. Firebase Analytics adds
`com.google.android.gms.permission.AD_ID` and `ACCESS_ADSERVICES_AD_ID` /
`ACCESS_ADSERVICES_ATTRIBUTION` transitively; `AndroidManifest.xml` strips them with
`tools:node="remove"` and sets `google_analytics_adid_collection_enabled`,
`..._default_allow_ad_personalization_signals`, `..._default_allow_ad_storage` and
`..._default_allow_ad_user_data` to `false`. Analytics events are unaffected
(`analytics_storage` is untouched). When AdMob (or any ad SDK) is added in Phase 2:
1. Delete the three `tools:node="remove"` permission lines and flip the four
   `google_analytics_*` meta-data values (ad storage / user data / personalization are
   consent-gated — wire them to the consent flow, don't just set them `true`).
2. **Update the Play Console "Advertising ID" declaration** (Policy > App content) to
   "yes, the app uses it", with the purpose (advertising).
3. **Update Data Safety**: declare device/other IDs collected for advertising, and whether
   they are shared; add the ad SDK's disclosures. The Phase 1 listing must say the app
   does NOT use the Advertising ID — keep it consistent with the merged manifest
   (`apkanalyzer manifest permissions app-release.apk | grep -i AD`) before each release.
4. Re-check the merged release manifest and the privacy policy text.

## Upcoming obligations (G4) — rules
`upcomingObligationsProvider` (`features/obligations/`) is the ONE "what's due" list
(read-only; no new data): active monthly/weekly recurring entries + debts I owe
(`iOwe`, open, with a due date), next 30 days plus anything overdue.
- **Never display `RecurringExpenseEntity.nextExpected`.** It is stamped once when an entry
  is created and never advanced, so it goes stale (the field is still stored, but not
  trusted). Use `nextDueDate(entry, today:)` (`recurring/domain/recurring_schedule.dart`) —
  the single shared answer used by the Recurring screen, Home, this list and the AI
  context. It derives the date from `dayOfMonth`/`dayOfWeek` relative to today (day 31
  clamps per month, from the original day: Jan 31 -> Feb 28 -> Mar 31).
- **De-dup signature:** an EMI payment expense marked recurring leaves a recurring entry
  with category `EMI` and the debt's person name as description (what
  `_debtExpenseDescription` writes). That entry is dropped in favour of the debt
  instalment. Never de-dup on amount/date — it would hide a rent that shares a day.
- Daily recurring entries are habits, not obligations, and are excluded. The provider
  recomputes on data changes / Home refresh, not at midnight.

## Home (R1) — rules
Order: header · মোট সম্পদ hero (+ wallet chips) · এই মাসের খরচ · ONE attention slot
(restore banner > backup reminder) · SMS card · ইনসাইট · সাম্প্রতিক লেনদেন · FAB. Widgets
live in `widgets/home/`; with ZERO expenses AND ZERO income Home shows `HomeWelcome` instead.
- **Colours: tokens only** in `widgets/home/` (`home_tokens_only_test` — stricter than the
  global ratchet: not even static `AppColors.*`). On a `brassSoft` background use
  `context.brassGlyph` (dark glyph in light mode, brass in dark mode); never brass text/
  icons on light surfaces. Brass buttons are a FILL with `onBrass` text.
- **Numbers come from existing providers; derived values are pure, tested functions** —
  `spendingDelta()` (% vs last month, hidden when last month is 0, capped at 999) and
  `mergeRecentActivity()` (expense + income, top 5). Don't compute in widgets.
- `spendingDelta` compares a PARTIAL month with a full one (spec'd), so it reads "less"
  early in the month. Pro-rating would be a new calculation — decide before changing it.
- Insights rows only appear when they have something to say: budget · upcoming (G4,
  `upcomingObligationsProvider`) · prediction · anomaly. New rows go in
  `home_insights_card.dart`.
- Don't put "→" (U+2192) or other symbols in text: the bundled fonts have no glyph for
  them (use an `Icon`).
- **Tests:** `home_states_test` (content per state), `home_overflow_test` (7 states × light/
  dark × 320/360dp × ×1.0/×1.3, real fonts). To eyeball a change without a phone:
  `R1_PREVIEW=1 flutter test test/features/expense/home_states_test.dart` writes
  `build/r1_preview/*.png` (git-ignored; no emoji glyphs on the host, so wallet emojis show
  as boxes there but not on a device).

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
- **iOS: `pod install` now resolves, but nobody has built or run the app in Xcode yet.**
  The old CocoaPods conflict was entirely ML Kit (see "Receipt OCR is removed"); the
  Podfile now pins `platform :ios, '13.0'`. A real iOS build/run (signing, Firebase
  iOS config, device test) is still the dedicated iOS-setup task for store prep.
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

- **"সব ডেটা মুছুন" does not clear categories.** `clearAllUserCollections()` leaves
  `CategoryModel` rows (custom categories survive delete-all). Pre-existing and left
  as-is deliberately; decide whether delete-all should also reset categories to the
  defaults before launch (privacy copy says "সব ডেটা").

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
