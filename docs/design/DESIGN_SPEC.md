# PocketPilot AI — Design Spec (UI redesign v1)

> Source of truth for the UI redesign. Pair with the mockup images in this folder.
> This is a RE-SKIN. The current app uses Google blue `#1A73E8` with no custom fonts; this spec moves it
> to an indigo + brass system with bundled fonts. Live users will see a visible rebrand.
> Calm, trustworthy, effortless: it's a money app, not a flashy one.

## Files in this folder

| File | What |
| --- | --- |
| `DESIGN_SPEC.md` | This spec (tokens, rules, per-screen layout, data sources) |
| `mockup_overview.png` | Overview of all approved screens (LOW-RES reference only) |
| `home_populated.png` · `home_empty.png` · `home_dark.png` | **TODO: export hi-res from Claude Design** |
| `add_expense.png` · `expenses_list.png` · `plan_hub.png` · `more_hub.png` | **TODO: export hi-res from Claude Design** |

> ⚠️ `mockup_overview.png` is 458×859 — too small for pixel-level matching. Export each screen at full
> resolution from Claude Design using the filenames above before implementing that screen.

---

## 1. Design tokens

### Colors

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| canvas | `#F3F1FA` | `#14121F` | App background |
| surface | `#FFFFFF` | `#221E33` | Cards, sheets |
| surface-2 | `#FAF9FE` | `#1B1829` | Inputs, segmented track |
| ink | `#1B1733` | `#EFEDF7` | Primary text |
| muted | `#6E6A85` | `#9C97B4` | Secondary text |
| line | `#E7E3F3` | `#312C46` | Dividers, card borders |
| outline | `#D9D3EE` | `#3E3757` | Input borders |
| primary | `#5647C4` | `#9A8CF0` | Primary actions, nav, icons |
| primary-deep | `#3A2F86` | `#B7AEF6` | Hero gradient end, emphasis |
| primary-soft | `#EEEBFB` | `#2A2547` | Icon chips, selected bg |
| brass | `#E0A83B` | `#F0BE55` | Money/security/premium/SMS-moat accent ONLY |
| brass-soft | `#FBF0D8` | `#3A2F18` | Brass card background |
| on-brass | `#2A1E05` | `#2A1E05` | Text on brass |
| success | `#2E9E6B` | `#57C795` | Income, "spent less" |
| expense | ink/red-ish tone | — | Expense amounts (keep subtle, not alarm-red) |

**Brass rule (encode as a doc comment on the token):** brass is a jewel — used only for money/security/
premium accents, EMI/debt markers, and the SMS auto-import card. Everything else is indigo.
In LIGHT mode brass fails contrast on white (2.14:1), so it may only be a FILL (with on-brass text) or a
brass-soft background — never brass text or a brass icon on white.

### Accessibility (WCAG AA)
- Every text/background pair must reach 4.5:1 (3:1 for large text and icons).
- `success #2E9E6B` on white is 3.38:1 — fine as a fill or large text, NOT for small income amounts.
  Add a darker `success-text` token (≥4.5:1 on white) for small text.
- Tokens still to define (derive, then verify contrast): error/danger, warning, info, hint text,
  expense-amount colour.

### Typography
- Headings: **Sora** 600/700. Body: **Inter** 400/500/600 (Latin text only — neither has Bengali glyphs).
- Bengali: **Noto Sans Bengali** or **Hind Siliguri**, chosen by an on-device specimen test. Since the UI,
  digits and ৳ are Bengali, this typeface is the app's real visual identity.
- Bangla line-height ~1.5; letter-spacing 0 (negative tracking distorts conjuncts).
- **Fonts must be bundled as assets** (app is offline-first). Do not fetch at runtime.

### Shape, spacing, elevation
- Card radius ~18. Sheet top radius ~24. Pills/chips fully rounded.
- Spacing scale: 4 · 8 · 12 · 16 · 20 · 24 · 32.
- Card shadow: `0 18px 40px -22px rgba(40,30,90,.45)` (light); deeper/darker in dark mode.
- Screen horizontal padding 16.

---

## 2. Shell
Bottom nav, 4 tabs (AI off): **হোম · খরচ · প্ল্যান · আরও**. When `AI_ENABLED`, চ্যাট appears at index 1.
Primary FAB "+" on Home and খরচ (quick add expense).

---

## 3. Screens

### 3.1 হোম / Home — MOST IMPORTANT (three states: populated, empty, dark)
Top → bottom:
1. **Header:** "শুভ সকাল, {name}" + বিশ্লেষণ icon-button; anomaly bell badge only when count > 0.
2. **Hero — মোট সম্পদ:** large ৳ amount, subtitle "সব ওয়ালেট মিলিয়ে", soft indigo gradient
   (primary → primary-deep). Row of wallet chips (Cash/বিকাশ/নগদ/Bank) with mini balances.
   *Semantics: cumulative, never resets.*
3. **এই মাসের খরচ:** amount + delta chip "গত মাসের চেয়ে X% কম/বেশি" with arrow; green = spent less,
   muted = spent more. Optional mini bars/sparkline. *Semantics: resets monthly.*
4. **SMS card (the moat):** "আপনার SMS থেকে Nটি লেনদেন পাওয়া গেছে" + "দেখুন ও নিশ্চিত করুন". Brass-soft
   background. Shown ONLY when pending detected transactions exist. Dismissible.
5. **Insights strip (calm, unified):** budget status (spent vs limit, slim bar) · upcoming obligations
   (next EMI + recurring, e.g. "১৬ অক্টোবর: বাড়িভাড়া ৳১৫,০০০") · অস্বাভাবিক খরচ only if any.
6. **Recent transactions:** last 4–5 rows — category icon in primary-soft circle (brass for EMI/debt),
   title, small date, ৳ amount (success colour for income). "সব দেখুন" link.
7. **FAB** "+".

**Empty/first-run:** welcome hero with app mark, 3 guided actions (add first expense · connect SMS ·
set up wallet), primary CTA. Never a blank page.

### 3.2 Add expense — bottom sheet
খরচ | আয় segmented toggle at top (primary turns success-green on আয়) · big ৳ amount · category icon
chips (horizontal) · wallet selector · date (default today) · optional note · numeric keypad ·
one primary "সেভ করুন". Fits one screen, no scrolling to save.

### 3.3 খরচ / Expenses list
App-bar title is the খরচ | আয় segmented control; search + filter actions. Date-grouped list with day
headers (optional daily subtotal). Row style identical to Home recent. Empty state. FAB.

### 3.4 প্ল্যান / Plan hub
Four cards: বাজেট · লক্ষ্য · দেনা-পাওনা · নিয়মিত খরচ — icon, title, one-line live status
(e.g. "৩টি সক্রিয় লক্ষ্য"), chevron. Purposeful, not a settings list.

### 3.5 আরও / More hub
SMS আমদানি at top with brass accent (the moat), then grouped rows: বিশ্লেষণ · ওয়ালেট · ক্যাটাগরি ·
আয় · এক্সপোর্ট · স্প্লিট বিল · সেটিংস. Icon + label + chevron.

### 3.6 Logo
Pending (separate design task). Use a temporary placeholder mark; the real logo lands in its own slice.

---

## 4. Data sources — UI ONLY, no business-logic changes

Every number on screen comes from an EXISTING provider. If the design needs a number no provider
produces, flag it — do not invent a calculation in the UI.

| UI element | Source |
| --- | --- |
| মোট সম্পদ | `totalBalanceProvider` (Σ wallet.currentBalance) |
| Wallet chips | wallet list provider |
| এই মাসের খরচ + delta | dashboard usecase (`inSpendingTotals`; this vs last month) |
| SMS card count | SMS import pending/detected provider |
| Budget status | budget provider (`inCategoryBudget`) |
| Upcoming obligations | recurring entries + debt next-installment (thin read-only combiner if needed) |
| Anomaly | anomaly provider (`inAnomaly`) |
| Recent transactions | dashboard recent list (unfiltered — shows EMI lines) |

Money writes from the add-expense sheet must keep using the existing ledger save paths unchanged.

---

## 5. Implementation order
R0 tokens/fonts foundation → R1 Home (3 states) → R2 add-expense sheet → R3 খরচ list →
R4 প্ল্যান + আরও hubs → R5 logo. Verify each with analyze + full suite (both AI modes) + on-device
screenshot side-by-side with the matching image here.
