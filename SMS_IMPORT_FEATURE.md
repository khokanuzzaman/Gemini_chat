# SMS Auto-Import Feature — Technical Reference

This document describes the complete architecture, data flow, and implementation details of the SMS Auto-Import feature in PocketPilot AI. It covers every component from Android native integration through to the Riverpod state layer and UI.

---

## Table of Contents

1. [Feature Overview](#1-feature-overview)
2. [Architecture Diagram](#2-architecture-diagram)
3. [Directory Structure](#3-directory-structure)
4. [Android Integration Layer](#4-android-integration-layer)
5. [Permission Handling](#5-permission-handling)
6. [SMS Reading & Paging](#6-sms-reading--paging)
7. [SMS Filtering](#7-sms-filtering)
8. [Parsing Pipeline](#8-parsing-pipeline)
9. [Core Domain Models](#9-core-domain-models)
10. [Deduplication](#10-deduplication)
11. [Wallet & Category Matching](#11-wallet--category-matching)
12. [Import Orchestrator](#12-import-orchestrator)
13. [SMS Ledger](#13-sms-ledger)
14. [Riverpod Provider Graph](#14-riverpod-provider-graph)
15. [UI State Machine](#15-ui-state-machine)
16. [Import Screen Walkthrough](#16-import-screen-walkthrough)
17. [History Screen](#17-history-screen)
18. [Isar Database Models](#18-isar-database-models)
19. [Known Limitations & Edge Cases](#19-known-limitations--edge-cases)
20. [Extension Points](#20-extension-points)

---

## 1. Feature Overview

SMS Auto-Import reads the Android SMS inbox, identifies messages from financial senders (bKash, Nagad, Rocket, banks), parses them into structured transactions, and lets the user review, edit, and import them as expenses or income — all on-device without any server calls.

**Key characteristics:**
- Android-only (iOS does not allow SMS inbox access)
- Fully offline — no AI/network call is made during import
- Deduplication prevents re-importing the same SMS across multiple scans
- Runs only when the user taps "Scan" — no background service
- A separate **ledger** (complete SMS history view) runs as a distinct sync pipeline

---

## 2. Architecture Diagram

```
Android Inbox (MethodChannel)
         │
         ▼
 AndroidSmsReaderService          ← raw SmsMessageEntity list
         │
         ▼
   SmsReaderService               ← converts entities → SmsMessage, handles paging
         │
         ▼
      SmsFilter                   ← keeps only financial SMS
         │
         ▼
  SmsParserEngine (bridge)
    └─► BangladeshFinancialSmsParser
          ├─► BkashSmsParser
          ├─► NagadSmsParser
          ├─► RocketSmsParser
          └─► BankSmsParser
         │
         ▼
   ParsedTransaction list
         │
         ▼
 SmsDuplicateDetector.filterNew() ← removes already-imported
         │
         ▼
  SmsImportOrchestrator           ← builds SmsImportCandidate list
   (+ SmsWalletMatcher
    + SmsCategoryMapper)
         │
         ▼
  SmsImportController             ← Riverpod NotifierProvider
         │
         ▼
    SmsImportScreen               ← review + select + edit + import
         │
         ▼
  SmsImportPersistence
   ├─► ExpenseMutationController.saveDetectedExpense()
   ├─► IncomeMutationController.saveDetectedIncome()
   ├─► SmsDuplicateDetector.markImported()
   └─► SmsLedgerService.upsertCandidate()
```

---

## 3. Directory Structure

```
lib/
├── core/
│   └── sms/
│       ├── sms_message.dart                  # lightweight domain model
│       ├── sms_permission_handler.dart        # Android permission wrapper
│       ├── sms_reader_service.dart            # paging reader (core layer)
│       ├── sms_filter.dart                    # financial-SMS filter
│       ├── sms_parser.dart                    # SmsParserEngine (bridge → feature layer)
│       ├── parsed_transaction.dart            # ParsedTransaction + enums
│       ├── sms_import_result.dart             # SmsImportResult + SmsImportCandidate
│       ├── sms_duplicate_detector.dart        # signature-based dedup
│       ├── sms_signature_codec.dart           # hash generator
│       ├── sms_import_orchestrator.dart       # full scan pipeline
│       ├── sms_category_mapper.dart           # keyword → category/incomeSource
│       ├── sms_wallet_matcher.dart            # priority-based wallet matcher
│       ├── sms_ledger_service.dart            # ledger sync + overview
│       └── sms_ledger_models.dart             # ledger view models
│
└── features/
    └── sms_import/
        ├── data/
        │   ├── parsers/
        │   │   ├── financial_sms_message_parser.dart   # abstract interface
        │   │   ├── bangladesh_financial_sms_parser.dart # dispatcher
        │   │   ├── bkash_sms_parser.dart
        │   │   ├── nagad_sms_parser.dart
        │   │   ├── rocket_sms_parser.dart
        │   │   ├── bank_sms_parser.dart
        │   │   └── sms_parser_utils.dart               # regex extraction helpers
        │   └── services/
        │       ├── android_sms_reader_service.dart     # MethodChannel wrapper
        │       └── sms_auto_import_engine.dart         # facade
        ├── domain/
        │   └── entities/
        │       ├── sms_message_entity.dart             # raw SMS entity
        │       ├── parsed_sms_transaction_entity.dart  # rich parsed entity
        │       └── sms_permission_state.dart           # permission enum
        └── presentation/
            ├── models/
            │   ├── sms_import_models.dart              # screen state + draft models
            │   └── sms_history_models.dart
            ├── providers/
            │   ├── sms_import_provider.dart            # all Riverpod providers
            │   └── sms_history_provider.dart
            ├── screens/
            │   ├── sms_import_screen.dart
            │   └── sms_history_screen.dart
            └── widgets/
                ├── sms_import_edit_sheet.dart
                └── sms_import_entry_widgets.dart
```

---

## 4. Android Integration Layer

**File:** `lib/features/sms_import/data/services/android_sms_reader_service.dart`

Communicates with native Android code via MethodChannel.

```
Channel name:  pocketpilot_ai/sms_reader
Method:        getInboxMessages
```

**Request map fields:**

| Field           | Type  | Description                            |
|-----------------|-------|----------------------------------------|
| `limit`         | int   | clamped to [1, 500]                    |
| `sinceMillis`   | int?  | epoch ms — fetch messages after this   |
| `beforeMillis`  | int?  | epoch ms — fetch messages before this  |
| `beforeMessageId` | int? | cursor for cursor-based paging        |

**Response:** `List<dynamic>` — each element is a map with `id`, `address`, `body`, `date`, `threadId`.

**Errors thrown:**
- `PermissionDeniedException` — when native returns `permission_denied` error code
- `GeneralException` — all other `PlatformException` cases

**Platform guard:** `isSupported` checks `Platform.isAndroid` before any call. On iOS the method returns empty results at the `SmsReaderService` level before reaching this class.

---

## 5. Permission Handling

**File:** `lib/core/sms/sms_permission_handler.dart`

Uses the `permission_handler` package. All methods return false/restricted on non-Android.

```dart
isAvailable()       → Platform.isAndroid
hasPermission()     → Permission.sms.status.isGranted
checkStatus()       → PermissionStatus (granted/denied/permanentlyDenied/restricted)
requestPermission() → requests, then opens app settings if permanently denied
```

**Permission state enum** (`lib/features/sms_import/domain/entities/sms_permission_state.dart`):

| State               | Meaning                                                  |
|---------------------|----------------------------------------------------------|
| `granted`           | SMS permission is active                                 |
| `denied`            | Not yet requested or user dismissed                      |
| `permanentlyDenied` | User blocked in OS — must open Settings                  |
| `unsupported`       | Not Android                                              |

The UI shows a different empty-state view for each permission state.

**App lifecycle hook:** `SmsImportScreen` implements `WidgetsBindingObserver`. On `AppLifecycleState.resumed`, it calls `controller.refreshStatus()` — this picks up permission changes when the user returns from Settings.

---

## 6. SMS Reading & Paging

**File:** `lib/core/sms/sms_reader_service.dart`

Thin wrapper over `AndroidSmsReaderService` that:
1. Checks platform and permission before every call
2. Converts `SmsMessageEntity` → `SmsMessage` (lightweight domain model)
3. Provides cursor-based paging via `readAllSmsByPaging()`

**SmsMessage fields:**

```dart
int id
String address   // sender ID, e.g. "bkash", "16247"
String body
DateTime date    // received at
int threadId
```

**Paging strategy:** `readSmsPage()` accepts `since`, `before`, `beforeMessageId`. The ledger sync uses cursor-based backward paging (starts from newest, walks backward using `before` + `beforeMessageId` from the last item in each page). `readSmsSince()` collects all pages in memory.

---

## 7. SMS Filtering

**File:** `lib/core/sms/sms_filter.dart`

`filterFinancialSms()` runs each message through `_isFinancialMessage()` which applies all four rules in order:

**Rule 1 — Length gate:** body must be ≥ 20 characters.

**Rule 2 — Known sender:**

Exact match set:
```
bkash, 16247, 01313016247,
nagad, 16167,
rocket, 16216,
bracbank, citybank, eblbank, dutchbangla, dbbl,
islamibank, ucb, mtbl, pubalibank, onebank,
primebank, southeast, standardchar, hsbcbd
```
Substring match: body of sender contains "bkash", "nagad", or "rocket".

**Rule 3 — Reject keywords:** drops OTP/PIN/promotional messages:
```
otp, pin, password, promotional, offer, discount,
cashback offer, balance inquiry, পাসওয়ার্ড
```

**Rule 4 — Must contain amount indicator:**
```
tk, bdt, ৳, taka, টাকা
```

**Rule 5 — Must contain transaction keyword:**
```
sent, send money, sendmoney, received, payment,
cashout, cash out, cashin, cash in, transfer,
withdraw, deposit, purchase, refund, credited, debited,
add money, salary, disbursement,
টাকা, পেয়েছেন, পরিশোধ, উত্তোলন, জমা
```

Sender is normalised before matching: Bangla digits converted to ASCII, lowercased, non-alphanumeric stripped.

---

## 8. Parsing Pipeline

### 8.1 Parser Interface

**File:** `lib/features/sms_import/data/parsers/financial_sms_message_parser.dart`

```dart
abstract class FinancialSmsMessageParser {
  bool canParse(SmsMessageEntity message);
  ParsedSmsTransactionEntity? parse(SmsMessageEntity message);
}
```

### 8.2 Dispatcher

**File:** `lib/features/sms_import/data/parsers/bangladesh_financial_sms_parser.dart`

Tries each parser in order: `BkashSmsParser → NagadSmsParser → RocketSmsParser → BankSmsParser`. Returns the first non-null result. Parser list is dependency-injectable for testing.

### 8.3 Bridge (core layer)

**File:** `lib/core/sms/sms_parser.dart`

`SmsParserEngine` holds a `BangladeshFinancialSmsParser` instance and bridges `SmsMessage` → `ParsedTransaction`. This keeps the core layer independent of the feature layer's entity types.

`SmsParser extends SmsParserEngine` adds `SmsFilter` and exposes a combined `parseSms(messages)` that filters then parses.

### 8.4 Utility Helpers

**File:** `lib/features/sms_import/data/parsers/sms_parser_utils.dart`

All regex extraction is centralised here:

| Method | Extracts |
|--------|----------|
| `normalize(body)` | lowercase, Bangla digits → ASCII, collapse whitespace |
| `extractFirstAmount(body)` | first `tk`/`bdt`/`৳` + number, returns double |
| `extractFee(body)` | fee/charge/কমিশন amounts |
| `extractBalance(body)` | balance/available balance after tx |
| `extractReference(body)` | TrxID/Ref/Transaction ID |
| `extractAccountMask(body)` | last 4 digits of account/card |
| `extractPartyAfterTo(body)` | recipient name/number after "to" |
| `extractPartyAfterFrom(body)` | sender name/number after "from" |
| `extractMerchant(body)` | merchant name for card purchases |
| `extractDateTime(body)` | datetime from SMS body (overrides received-at) |
| `parseAmount(string)` | strips commas, parses double |

Currency regex: `r'(?:tk|bdt)\s*([0-9,]+(?:\.\d{1,2})?)'`

### 8.5 Per-Brand Parsers

Each parser handles the quirks of its brand's SMS format:

**BkashSmsParser** — recognises: sendMoney, receivedMoney, cashOut, cashIn, payment, addMoney. Sender: `bkash` / `16247` / `01313016247`. Source: `ParsedTransactionSource.bkash`.

**NagadSmsParser** — recognises: sendMoney, receivedMoney, cashOut, cashIn, payment. Sender: `nagad` / `16167`. Source: `ParsedTransactionSource.nagad`.

**RocketSmsParser** — recognises: sendMoney, receivedMoney, cashOut, cashIn, transfer. Sender: `rocket` / `16216`. Source: `ParsedTransactionSource.rocket`.

**BankSmsParser** — recognises: bankDebit, bankCredit, atmWithdrawal, cardPurchase, billPay, transfer. Matches any sender in the known bank sender set. Source: `ParsedTransactionSource.bank`.

---

## 9. Core Domain Models

### 9.1 ParsedTransaction (`lib/core/sms/parsed_transaction.dart`)

The canonical in-memory transaction object used throughout the core layer.

```dart
int smsId
String sender
ParsedTransactionSource source       // bkash/nagad/rocket/bank/unknown
ParsedTransactionDirection direction // debit/credit/unknown
ParsedTransactionKind kind           // 13 values (see below)
double amount
String rawMessage
DateTime receivedAt
DateTime occurredAt
double? fee
double? balanceAfter
String? reference
String? counterparty
String? merchantName
String? accountMask
String? rawCategory
double confidence                    // 0.0–1.0, default 1.0
```

**TransactionType** (computed from direction + kind):
- `expense` — debit AND not transfer-like
- `income` — credit AND not transfer-like
- `transfer` — addMoney / cashIn / transfer kinds
- `unknown` — everything else

**isTransferLike:** `kind` is `addMoney`, `cashIn`, or `transfer`.

**ParsedTransactionKind values:**

| Kind | Direction | Notes |
|------|-----------|-------|
| sendMoney | debit | MFS send |
| receivedMoney | credit | MFS receive |
| cashOut | debit | agent cash-out |
| cashIn | transfer | add balance via agent |
| payment | debit | merchant payment |
| addMoney | transfer | bank→MFS top-up |
| bankDebit | debit | bank account debit |
| bankCredit | credit | bank account credit |
| transfer | transfer | account-to-account |
| atmWithdrawal | debit | ATM cash |
| cardPurchase | debit | debit/credit card purchase |
| billPay | debit | utility/bill payment |
| unknown | — | parse failed or ambiguous |

### 9.2 SmsImportCandidate (`lib/core/sms/sms_import_result.dart`)

```dart
SmsMessage sms
ParsedTransaction transaction
WalletEntity? suggestedWallet
String? suggestedCategory       // expense category name
String? suggestedIncomeSource   // income source name
```

`isExpense` / `isIncome` delegated to `transaction.type`.

### 9.3 SmsImportResult

```dart
DateTime since
List<SmsMessage> scannedMessages
List<SmsMessage> financialMessages
List<ParsedTransaction> parsedTransactions
List<SmsImportCandidate> candidates
int duplicateCount
```

Computed counts: `scannedCount`, `financialCount`, `parsedCount`, `newCount`.

---

## 10. Deduplication

**File:** `lib/core/sms/sms_duplicate_detector.dart`

Prevents the same SMS from being imported more than once. Uses `SmsSignatureCodec` to generate a stable hash per SMS.

### Signature generation (`sms_signature_codec.dart`)

```
hash(address + "|" + epochMs + "|" + hash(body))
→ toRadixString(16)
```

Uses a Dart-native polynomial hash (`hash * 31 + codeUnit & 0x7fffffff`). No external crypto dependency. Deterministic but not cryptographically secure — collision is theoretically possible for very similar messages on the same millisecond from the same sender.

### Stored in Isar: `ImportedSmsModel`

Fields: `signature`, `sender`, `smsDate`, `importedAt`, `expenseId?`, `incomeId?`.

### Key methods

| Method | Description |
|--------|-------------|
| `isDuplicate(sms)` | returns true if signature already in DB |
| `filterNew(transactions, messages)` | removes already-imported entries from a list |
| `markImported(sms)` | writes one record to DB |
| `markBatchImported(messages)` | bulk insert, skips duplicates within the batch |
| `getImportedCount()` | total count of imported SMS |
| `getLastImportDate()` | most recent `smsDate` from imported records |

`filterNew()` loads all signatures in one DB query and filters in-memory — O(n) with one round-trip.

---

## 11. Wallet & Category Matching

### SmsWalletMatcher (`lib/core/sms/sms_wallet_matcher.dart`)

Priority order:
1. **Source type match** — if transaction is from bKash/Nagad/Rocket, finds wallet whose `walletType` matches that source
2. **Account number match** — last 4 digits of `transaction.accountNumber` vs wallet identifier digits
3. **Bank institution name** — matches bank name keyword in wallet name (e.g. "Dutch Bangla", "DBBL")
4. **Single bank wallet** — if only one bank wallet exists, uses it
5. **Default wallet** — the passed `defaultWallet` parameter
6. **First alphabetically sorted wallet** — last resort

### SmsCategoryMapper (`lib/core/sms/sms_category_mapper.dart`)

Two methods: `mapToExpenseCategory(transaction)` and `mapToIncomeSource(transaction)`.

**Expense mapping** uses keyword matching on `rawCategory`, `merchantName`, `counterparty`, and `rawMessage`:

| Category | Keywords |
|----------|----------|
| Food | restaurant, food, dining, khawa, khabar, cafe, bistro, eatery, grocery, bazar, bakery |
| Transport | transport, uber, pathao, rickshaw, cng, bus, taxi, ride, fare |
| Shopping | shop, store, mart, mall, retail, purchase |
| Healthcare | hospital, clinic, pharmacy, medicine, doctor, health, medical |
| Bill | bill, utility, electricity, gas, water, internet, phone |
| Entertainment | entertainment, cinema, movie, game, sport, streaming |
| Education | education, school, college, university, tuition, course, book |

Also checks `CategoryRegistry` custom categories by direct name match.

**Income source mapping:**
- `salary` — keywords: salary, pay, wage, income, মাসিক, বেতন
- `freelance` — keywords: freelance, upwork, fiverr, client, project
- default → `Other`

---

## 12. Import Orchestrator

**File:** `lib/core/sms/sms_import_orchestrator.dart`

Single method: `scanForNewTransactions(wallets, {defaultWallet})`.

**Flow:**
1. `getLastImportDate()` — if null, defaults to 30 days ago
2. `reader.readSmsSince(since)` — full paged read
3. `filter.filterFinancialSms(scannedMessages)` — financial only
4. `parser.parseAll(financialMessages)` — ParsedTransaction list
5. `duplicateDetector.filterNew(parsed, financial)` — remove already-imported
6. For each new transaction, build `SmsImportCandidate` with:
   - `walletMatcher.matchWallet()`
   - `categoryMapper.mapToExpenseCategory()` (if expense)
   - `categoryMapper.mapToIncomeSource()` (if income)
7. Return `SmsImportResult`

---

## 13. SMS Ledger

**File:** `lib/core/sms/sms_ledger_service.dart`

The ledger is a **separate, comprehensive record** of all financial SMS detected on the device — distinct from the import flow. It enables the "SMS History" screen and provides analytics without the user having to import each transaction.

### Sync vs Import

| Aspect | Import | Ledger Sync |
|--------|--------|-------------|
| Triggered by | User taps "Scan" | Separate sync call |
| Scope | Only new SMS since last import | All SMS (initial backfill or incremental) |
| Output | Expense/Income records | SmsLedgerEntryModel records |
| Dedup storage | `ImportedSmsModel` | `SmsLedgerEntryModel` (by signature) |
| User action | Review + select + save | Automatic background |

### syncLedger()

Paginated sync using cursor-based paging (`before` + `beforeMessageId`). On first run (`initialBackfillComplete = false`), reads all available SMS. On subsequent runs, reads since `lastSyncedSmsDate`.

Progress is reported via `onProgress(SmsLedgerSyncProgress)` callback.

State is persisted in `SmsLedgerSyncStateModel` (Isar, id=1):
- `initialBackfillComplete: bool`
- `lastSuccessfulSyncAt: DateTime?`
- `lastSyncedSmsDate: DateTime?`
- `lastSyncedSmsId: int?`

### buildOverview(month)

Returns `SmsLedgerOverview` for a given month:
- Monthly outflow / inflow / transfer totals
- All-time activity total
- `kindTotals`: per-`ParsedTransactionKind` breakdown
- `sourceTotals`: per-`ParsedTransactionSource` breakdown
- `trendPoints`: 6-month trend (`SmsLedgerMonthlyTrendPoint` with outflow/inflow/transfer/count per month)

### upsertCandidate()

Called by `SmsImportPersistence` after each successful import — updates `isImported = true` and `importedAt` on the matching ledger entry.

### setIgnored(entryId, ignored)

Marks a ledger entry as hidden from the overview without deleting it.

---

## 14. Riverpod Provider Graph

**File:** `lib/features/sms_import/presentation/providers/sms_import_provider.dart`

```
smsPermissionHandlerProvider  (Provider<SmsPermissionHandler>)
smsReaderServiceProvider       (Provider<SmsReaderService>)
smsFilterProvider              (Provider<SmsFilter>)
smsParserEngineProvider        (Provider<SmsParserEngine>)
smsCategoryMapperProvider      (Provider<SmsCategoryMapper>)
smsWalletMatcherProvider       (Provider<SmsWalletMatcher>)
smsDuplicateDetectorProvider   (Provider<SmsDuplicateDetector>)
    └── depends on: isarProvider

smsImportOrchestratorProvider  (Provider<SmsImportOrchestrator>)
    └── depends on: reader, filter, parser, categoryMapper, walletMatcher, duplicateDetector

smsLedgerServiceProvider       (Provider<SmsLedgerService>)
    └── depends on: isar, reader, filter, parser, categoryMapper, walletMatcher

smsImportStatusRefreshTokenProvider  (StateProvider<int>)

smsImportStatusProvider  (FutureProvider<SmsImportStatus>)
    └── watches: refreshToken, permissionHandler, duplicateDetector, ledgerService

smsImportPersistenceProvider   (Provider<SmsImportPersistence>)

smsImportControllerProvider    (NotifierProvider<SmsImportController, SmsImportScreenState>)
```

---

## 15. UI State Machine

`SmsImportScreenState` holds the full UI state. Key fields:

| Field | Type | Purpose |
|-------|------|---------|
| `permissionState` | `SmsPermissionState` | permission gating |
| `isStatusLoading` | bool | loading indicator while checking status |
| `scanAttempted` | bool | whether at least one scan has been run |
| `isScanning` | bool | scan in progress |
| `isImporting` | bool | import batch in progress |
| `candidates` | `List<SmsImportCandidate>` | unimported, parseable transactions |
| `drafts` | `Map<int, SmsImportDraft>` | editable per-candidate data |
| `selectedIds` | `Set<int>` | candidate IDs checked for import |
| `rowErrors` | `Map<int, String>` | per-row import error messages |
| `activeTab` | `SmsImportTabFilter` | all/expense/income filter |
| `latestScanResult` | `SmsImportResult?` | scan summary stats |
| `lastScanReadyCount` | int | total ready count from most recent scan |
| `errorMessage` | String? | global banner error |

`filteredCandidates` computed getter: filters `candidates` by `activeTab`.

### SmsImportDraft

The editable representation of one candidate that the user can modify before import:

```dart
int candidateId        // = sms.id
TransactionType type   // expense / income (immutable)
double amount          // editable
String description     // editable
DateTime date          // editable
int? walletId          // editable
String? category       // expense only, editable
String? incomeSource   // income only, editable
```

`toExpenseData()` maps to `ExpenseData` (defaults category to "Other", description to "SMS খরচ").
`toIncomeEntity()` maps to `IncomeEntity` (defaults source to "Other", description to "SMS আয়").

---

## 16. Import Screen Walkthrough

### Controller methods

**`refreshStatus()`** — reads current permission + imported count + last date. Called on build, on resume, and after every import.

**`requestPermission()`** — calls `permissionHandler.requestPermission()`, then refreshes.

**`scanForNewTransactions()`**:
1. Guard: already scanning or importing → return
2. Re-check permission (user may have revoked since last check)
3. Set `isScanning = true`
4. `orchestrator.scanForNewTransactions(wallets, defaultWallet: activeWallet)`
5. Filter result to expense + income only (drops transfer-type candidates)
6. Build `drafts` map from candidates
7. Pre-select all candidates
8. Set `isScanning = false`, update state with candidates/drafts/selectedIds

**`importSelected()`**:
1. Guard: `isImporting == true` or no selected → return empty outcome
2. Set `isImporting = true`
3. For each selected candidate:
   a. `smsImportPersistence.importCandidate(candidate, draft)`:
      - Validates: `draft.amount > 0`
      - Saves via `expenseMutationController.saveDetectedExpense()` or `incomeMutationController.saveDetectedIncome()`
      - Marks imported in `SmsDuplicateDetector`
      - Upserts in `SmsLedgerService`
   b. On success → add to `importedIds`
   c. On error → record in `rowErrors`, increment `failedCount`
4. Remove successfully imported candidates from state
5. Show batch outcome summary sheet

### Tab filtering

`SmsImportTabFilter.all / expense / income` — filters `filteredCandidates` getter. Selection state is maintained across tabs (selecting all in "expense" tab doesn't clear income selections).

### Edit sheet

Tapping a candidate row opens `SmsImportEditSheet` (bottom sheet). Editable fields: amount, description, date, wallet, category (expense) or income source (income). On save, calls `controller.updateDraft(updated)`.

---

## 17. History Screen

**File:** `lib/features/sms_import/presentation/screens/sms_history_screen.dart`

Shows the full SMS ledger. Uses `smsLedgerServiceProvider` to load `SmsLedgerOverview` for a selected month. Features:
- Month selector
- Outflow / inflow / transfer totals
- Per-kind breakdown
- Per-source breakdown
- 6-month trend chart
- Entry list with imported/hidden status
- Swipe or long-press to hide/show entries

---

## 18. Isar Database Models

### ImportedSmsModel

Tracks which SMS have been imported to prevent duplicates.

```dart
@collection
class ImportedSmsModel {
  Id id = Isar.autoIncrement;
  late String signature;      // hex hash
  late String sender;
  late DateTime smsDate;
  late DateTime importedAt;
  int? expenseId;
  int? incomeId;
}
```

Index: `signature` (unique lookup in `isDuplicate`).

### SmsLedgerEntryModel

Denormalised record combining parsed transaction data + import status.

```dart
@collection
class SmsLedgerEntryModel {
  Id id = Isar.autoIncrement;
  late String signature;
  late int smsId;
  late String sender;
  late String rawMessage;
  late ParsedTransactionSource source;
  late ParsedTransactionDirection direction;
  late ParsedTransactionKind kind;
  late TransactionType type;
  late double amount;
  double? fee;
  double? balanceAfter;
  String? reference;
  String? counterparty;
  String? merchantName;
  String? accountMask;
  String? rawCategory;
  late double confidence;
  late DateTime occurredAt;
  late DateTime receivedAt;
  bool isImported = false;
  DateTime? importedAt;
  bool isIgnored = false;
  DateTime? ignoredAt;
  late DateTime createdAt;
  late DateTime updatedAt;
}
```

Computed: `isExpenseLike`, `isIncomeLike`, `toParsedTransaction()`, `toSmsMessage()`.

### SmsLedgerSyncStateModel

Singleton record (id=1) tracking ledger sync progress.

```dart
@collection
class SmsLedgerSyncStateModel {
  Id id = 1;
  bool initialBackfillComplete = false;
  DateTime? lastSuccessfulSyncAt;
  DateTime? lastSyncedSmsDate;
  int? lastSyncedSmsId;
  late DateTime createdAt;
  late DateTime updatedAt;
}
```

---

## 19. Known Limitations & Edge Cases

### Signature collision
`SmsSignatureCodec` uses a 31-bit polynomial hash. Two different SMS bodies from the same sender on the exact same millisecond could theoretically produce the same signature and the second would be treated as a duplicate. In practice this is extremely unlikely.

### Sender whitelist is static
New banks or MFS senders not in `SmsFilter._knownSenderIds` will be silently skipped. Adding support requires updating both `smsFilter.dart` and adding a parser or extending `BankSmsParser`.

### Amount extraction — first match only
`SmsParserUtils.extractFirstAmount()` returns the **first** numeric amount found. SMS that mention fee before principal (e.g. "Fee: Tk 5. Amount: Tk 500") may extract the wrong amount. Each brand parser is responsible for handling this correctly.

### No background scan
There is no `WorkManager` / background service. The scan only runs when the user opens the SMS Import screen and taps the scan button.

### Last import date cursor
`SmsImportOrchestrator` uses `SmsDuplicateDetector.getLastImportDate()` (most recent `smsDate` from `ImportedSmsModel`) as the scan start point. If the user has never imported, it defaults to 30 days ago. Ledger sync uses its own cursor (`lastSyncedSmsDate`) independently.

### Category/wallet suggestions not persisted
Suggested category and wallet come from `SmsCategoryMapper` and `SmsWalletMatcher` at scan time. If the user adds a new wallet after scanning, the suggestions won't update until the next scan.

### Non-expense/income candidates dropped before display
`scanForNewTransactions()` in the controller filters out `transfer` and `unknown` type candidates. They are still in `SmsImportResult.candidates` but not shown to the user.

---

## 20. Extension Points

### Adding a new parser
1. Create `MyBankSmsParser extends FinancialSmsMessageParser`
2. Implement `canParse()` (check sender address) and `parse()` (return `ParsedSmsTransactionEntity`)
3. Add to `BangladeshFinancialSmsParser`'s parser list

### Adding a new financial sender
1. Add sender ID to `SmsFilter._knownSenderIds`
2. Ensure a parser handles it (or extend `BankSmsParser`)

### Extending category mapping
`SmsCategoryMapper.mapToExpenseCategory()` — add keywords to the existing map or add a new entry. Also consider updating `CategoryRegistry` to register the new category automatically.

### Making wallet matching smarter
`SmsWalletMatcher.matchWallet()` — add a new priority level before the "first alphabetically" fallback. Consider adding user-configurable sender→wallet mappings stored in SharedPreferences.

### Adding background sync
1. Integrate `workmanager` package
2. Create a background task that calls `smsLedgerService.syncLedger()`
3. Trigger on new SMS via `BroadcastReceiver` (requires Android manifest change)

### Confidence score
Each `ParsedTransaction.confidence` is a `double` (0–1, default 1.0). Parsers can lower it for ambiguous messages. The UI already shows a `_ConfidenceBadge` for confidence < 0.98 — implement lower confidence scoring in parsers for better user guidance.
