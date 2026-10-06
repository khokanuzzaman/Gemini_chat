# PocketPilot AI — Gap Features Plan (long-term value)

> Goal: the app should answer "where is my money going?" on day 1 (it does) AND "am I getting ahead?"
> after a year (it can't yet). This plan covers the features that close that gap.
> Verified against the trunk snapshot; Claude Code must re-verify each "today" claim on current `main`.

## Principles
- **Data that can't be recovered later comes first.** Anything that needs history must start recording
  now — every month of delay is a month of history lost forever.
- **No AI needed.** Everything here is local math over existing data; works in Phase 1 with AI off.
- **Built in the new design.** UI items land after R1–R4 so they use the new tokens/fonts, not the old look.
- **Every new collection must be included in backup, export, and "সব ডেটা মুছুন".** Otherwise a restore
  silently loses it or a delete silently leaves it.
- Same discipline as always: plan → oracle/tests → slice → commit → stop.

---

## Priority overview

| # | Feature | Why | Phase | Size |
|---|---|---|---|---|
| G1 | Net-worth snapshots (data only) | History is lost every day it's missing | **Now** | S |
| G2 | Backup safety (auto-backup that actually runs + reminder) | Local-first: lost phone = lost year | **Before launch** | S–M |
| G3 | Real weekly digest | Weekly habit; today's notification has no numbers | Phase 1 (after R1) | M |
| G4 | Upcoming obligations view | Monthly EMI + recurring + bills in one place | With R1 / after | S–M |
| G5 | বছরের হিসাব — yearly review | The "am I getting ahead?" screen | After R4 | M |
| G6 | Net-worth trend chart | Shows G1's history | After R4 (needs G1 data) | S |
| G7 | Year-over-year comparison | "This October vs last October" | After G5 | S |
| G8 | Event budget (Eid/Puja/wedding) | Biggest BD spending spikes | Phase 3 | M |
| G9 | Home-screen widget + quick add | Daily 3-second logging | Phase 3 | M |

---

## G1 — Net-worth snapshots (START NOW)

**Today:** মোট সম্পদ = live Σ wallet.currentBalance. Nothing is stored over time, so "how much did my net
worth grow this year?" is impossible, and every past day is already unrecoverable.

**Build:**
- New Isar collection `NetWorthSnapshotModel { date (day, unique index), total, perWallet (walletId→balance
  map, serialized), createdAt }`.
- Capture rule: on app open / resume, if no snapshot exists for today, write one. Also write the
  month-end snapshot if the app wasn't opened on the last day (use the first open after month-end — store
  the actual capture date, don't fake the month-end).
- No background worker needed for v1 (open-based is enough; gaps are acceptable and shown as gaps).
- Retention: keep daily for 90 days, then thin to one per week, and keep month-end forever (bounded size).
- Include in Isar backup/export and in delete-all.
- **Backfill:** do NOT reconstruct history from transactions. Wallet opening balances and debt principal
  bypass expense records, so a reconstruction would be wrong in ways users can't see. Forward-only; the
  chart starts on the first snapshot date and says so.

**No UI in this slice.** Just start recording. Tests: one snapshot per day (idempotent), correct totals
incl. archived-wallet rule matching totalBalanceProvider, retention thinning, backup round-trip includes it,
delete-all removes it, schema is additive (existing users upgrade in place).

---

## G2 — Backup safety (BEFORE LAUNCH)

**Today:** manual Google Drive backup (1/day). An `auto_backup_enabled` preference exists but no trigger
was found that actually runs it — verify; if it's dead, the setting is lying to users.

**Build:**
- If auto-backup is on: on app open, if signed in + online + last backup > 24h → run backup in the
  background of the session (non-blocking, failures logged, never block the UI).
- Free users: if no backup in 30 days and they have data, a gentle Home nudge "শেষ ব্যাকআপ ৩০ দিন আগে".
  Master plan lists auto-backup as Premium — keep that gating, but the reminder is free for everyone
  (data loss is a trust problem, not an upsell).
- Settings shows "শেষ ব্যাকআপ: <date>" truthfully.
- Onboarding (later polish): one line that data lives on the phone and backup protects it.

Tests: trigger conditions (each of signed-out / offline / <24h / disabled → no backup), reminder threshold,
restore includes G1 snapshots.

---

## G3 — Real weekly digest

**Today:** Sunday 9 AM notification with fixed text "এই সপ্তাহে কত খরচ হয়েছে দেখুন" — no numbers. A
scheduled notification's text is fixed when scheduled, so real numbers need a different approach.

**Build (two parts):**
1. **Weekly summary screen** (in the new design): this week's spend vs last week, top 3 categories,
   biggest single expense, budget status, upcoming obligations next week. The notification tap opens it
   (today it routes to the dashboard).
2. **Numbers in the notification (Android):** a periodic background task (e.g. workmanager, weekly) that
   computes the summary on-device and posts the notification with real text, e.g.
   "এই সপ্তাহে ৳৮,৪২০ খরচ — গত সপ্তাহের চেয়ে ১২% কম". iOS keeps the generic text (background limits).
   Privacy: amounts appear on the lock screen — respect a "লক স্ক্রিনে টাকার পরিমাণ লুকান" option.

Tests: summary math uses `inSpendingTotals`; week boundaries (Saturday/Sunday start — confirm the BD
convention used elsewhere in the app and stay consistent).

---

## G4 — Upcoming obligations

**Today:** recurring entries and debt next-installments live on separate cards; no single "what's due"
list. (Feature-map flag E2.)

**Build:** a thin read-only combiner provider (no new data) merging recurring entries (next date) + debt
EMIs/next installments for the next 30 days, sorted by date, with a total. Home R1 shows the next 1–2 in the
Insights strip; tapping opens the full list. Debt items deep-link to the debt; recurring items to the
recurring entry.

Tests: merge order, de-dup (an expense marked recurring that is also a debt EMI must not appear twice),
month rollover dates (e.g. day 31 in a 30-day month).

---

## G5 — বছরের হিসাব (yearly review)

**Today:** analytics is month-based; "this year" exists only as an export range.

**Build:** a year screen (year picker; default current year): total income, total spending
(`inSpendingTotals`), savings (cash-flow savings + goal deposits), month-by-month bars, top categories,
debt repaid in the year, goals reached, biggest month. Partial years labelled ("জানুয়ারি–অক্টোবর").
Entry: Analytics header + আরও. In December/January, a Home card "আপনার ২০২৬ সালের হিসাব দেখুন".

Tests: year totals equal the sum of the 12 monthly totals (oracle against the existing monthly usecase),
predicate correctness (EMI counted in spending, goal deposits not).

---

## G6 — Net-worth trend chart

Needs G1 data. Line chart of month-end (and recent daily) snapshots on Analytics, with "since <first
snapshot date>" label and visible gaps. Shown only when ≥ 2 snapshots exist; otherwise an honest
"হিসাব জমা হচ্ছে — কয়েক সপ্তাহ পর এখানে আপনার সম্পদের গ্রাফ দেখবেন".

---

## G7 — Year-over-year comparison

Same month last year vs this month (total + per category), on the monthly analytics view. Hidden until
the user has data for the same month last year — never show a "0 last year" comparison.

---

## G8 — Event budget (Eid / Puja / wedding)

Eid and festival months are the biggest spending spikes in BD, and the lunar calendar moves them every
year. v1 needs no history: user creates a named budget with a date range ("ঈদুল আযহা ২০২৭", ৳৪০,০০০);
expenses in that range and chosen categories count toward it. v2 (after a year of data): suggest an amount
from last year's same event. Do not hardcode festival dates.

---

## G9 — Home-screen widget + quick add

Android first (`home_widget`): today's spend + this month's spend + a "+" that opens the add-expense sheet
directly; plus an app-icon long-press shortcut "খরচ যোগ করুন". Amount visibility follows the same
lock-screen privacy option as G3.

---

## Sequencing with the current roadmap

1. **Now (parallel to the redesign):** G1 (data only) — tiny, and every day it waits is lost history.
2. **Before launch:** G2 backup safety.
3. **During/after R1:** G4 obligations (Home Insights needs it anyway).
4. **After R1–R4:** G3 weekly digest, G5 yearly review, G6 trend chart, G7 YoY.
5. **Phase 3:** G8 event budget, G9 widget.

Add usage-analytics events (existing whitelist pattern) for each new surface so we can see what's used.
