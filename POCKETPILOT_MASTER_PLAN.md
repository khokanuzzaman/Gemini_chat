# PocketPilot AI — Master Product Plan (v1, decisions locked)

> The single source of truth for where the app goes. Consolidates and supersedes the scattered
> monetization/cleanup/AI notes. Hand to Claude Code phase by phase.
> Correctness foundation (ledger, DESYNC-1/2) is already done — this plan is about **focus, delight,
> and a monetization model that keeps a low-cost app solvent without ever paywalling the core.**

---

## 1. North star

**"Track your money in Bangla, almost without trying — and trust every number."**

For a Bengali user who lives in bKash/Nagad/bank SMS. The app's job: make entry effortless (auto-import +
NL chat), keep the numbers trustworthy (done), and give insight that feels personal. Everything is judged
against **effortless + trustworthy + loved** — not feature count.

Two rules that govern every decision below:
1. **Never paywall the core.** Tracking money (SMS import, manual entry, wallets, debt, goals, budget,
   analytics) is **free forever**. That's the moat and the trust. Monetize *convenience and scale*, never
   the thing that makes the app worth opening.
2. **AI is an upsell, not a gate.** Because AI cost per user is near-zero (OCR + voice are on-device/free;
   only text→JSON structuring costs cents), we can afford a generous free tier and monetize only the top.

---

## 2. Feature-gating matrix (LOCKED) — what's free, what's rewarded, what's premium

Four tiers. This answers "kon kon feature locked thakbe."

### 🟢 FREE forever — unlimited, no ads gate (the core + moat)
- **SMS auto-import** (bKash / Nagad / Rocket / bank) — the moat; must be free and unlimited
- **Manual expense/income entry**
- **Wallets** (multi-wallet, balances)
- **Categories**
- **Debt / EMI tracking**
- **Goals / savings**
- **Budgets** (create + track)
- **Analytics & dashboard** (all charts, full history)
- **Local insights** — prediction (local math), anomaly (local), recurring
- **Security** (PIN / biometric) — never paywalled
- **CSV export** (basic data portability — trust)
- **Manual cloud backup** (1/day, as today)

### 🟡 FREE with daily quota — rewarded-ad extends (cheap AI)
- **Chat AI entry** (NL Bangla → expense) — ~20/day free (already), watch a rewarded ad to earn +N more
- **Receipt scan** — OCR is free/on-device (ML Kit); a few AI-structured scans/day free, rewarded to extend
- **Voice entry (standard)** — free via on-device Android STT (`bn-BD`); rewarded/premium for accurate Whisper

### 🎬 REWARDED-UNLOCK — watch an ad to earn credits/actions
- Extra chat AI actions beyond the daily quota
- Accurate voice transcription (Whisper) sessions
- Extra receipt AI scans
- (Mechanic: "watch a short ad → +5 AI actions." Ad revenue is earned exactly when AI cost is spent — the
  economics align. This is the primary free-tier revenue, better than banners for a low-eCPM BD audience.)

### 💎 PREMIUM (subscription) — unlimited + exclusive
- **Unlimited chat AI** (no daily quota)
- **RAG "ask about my money"** — the AI money-advisor ("এই মাসে খাবারে কত গেল?") — high value, premium hook
- **Accurate voice (Whisper), unlimited**
- **Ad-free** everything
- **Auto / scheduled cloud backup**
- **Advanced reports** (PDF, deeper analytics) — optional premium extra

**Ad placement rule (trust matters in a money app):** rewarded-first. A light banner is acceptable on
non-sensitive screens; **no interstitials on money screens** (adding an expense, viewing balance). Never
feel spammy — a finance app lives on trust.

---

## 3. Cleanup — cut / merge / make-local / demote (LOCKED)

- **CUT — Split's permanent tab.** Group bill-splitting is a different job (Splitwise). Remove its tab;
  evaluate removing the feature entirely once usage analytics exist. It doesn't earn a primary slot.
- **MERGE — prediction + anomaly + budget-planner → one "Insights" surface** on Home. Three surfaces
  analyzing the same expenses become one coherent section (projection · unusual spends · budget status ·
  top categories).
- **MAKE LOCAL (drop AI) — prediction + budget planner.** They already compute the stats locally and only
  use AI to narrate. Replace with local projection + rule-based suggestions. Removes recurring AI cost.
- **DEMOTE — recurring → opt-in.** Stop auto-detecting and nagging; let the user mark an expense recurring.
  (Overlaps debt EMI; auto-detection adds noise.)
- **FOLD — ai_guide → onboarding/help.** Not a standalone feature.
- **DEAD CODE / hygiene** — 17 stray prints → gated logger; remove dev artifacts (logs, test wav/aiff,
  .DS_Store, .idea); unify brand name (gemini_chat / SmartSpend → PocketPilot AI everywhere user-facing).

---

## 4. Navigation & IA redesign (LOCKED)

Today: 19 features behind 5 tabs, with the moat (SMS, debt) buried and Split owning a tab. New 5-tab shell:

1. **হোম** — dashboard + the unified **Insights** section (projection, anomalies, budget status, obligations)
2. **চ্যাট** — AI entry (text / voice / receipt funnel here)
3. **খরচ** — expenses list + income (segment); manual add/edit
4. **প্ল্যান** — Budget · Goals · Debt · Recurring (the "planning" surfaces)
5. **আরও** — SMS import · Wallets · Categories · Export · Settings · Security

SMS import gets promoted (into আরও *and* pitched in onboarding). Split loses its tab.

---

## 5. UI/UX principles (LOCKED direction) — "better UI/UX"

The design tokens already exist (indigo + brass, light/dark). Direction:

1. **Effortless entry is the hero.** Home leads with a big, obvious "add" + shows SMS auto-import working
   ("we caught 3 transactions from your bKash SMS — confirm?"). The fastest path to logged-in-value wins.
2. **One-tap add everywhere** — a home-screen widget + quick-action shortcut (not present today), and a
   persistent add button. A daily app must let you log in <3 seconds.
3. **Trust through clarity** — every screen answers "where did my money go?" cleanly. Numbers reconcile
   (ledger done). Show wallet balance, this-month spend, and obligations up front.
4. **Bengali-first warmth, not corporate** — Bengali numerals option, friendly microcopy, festival
   awareness (Eid/Puja budgeting prompts). It should feel made *for* a Bangladeshi, not translated.
5. **Fast & offline** — local-first (already). No spinners on core flows; instant.
6. **Progressive disclosure** — Home is calm (key numbers + insights); depth lives one tap down. Don't
   overwhelm with 19 features on one screen.
7. **Delight moments** — goal-reached celebration, saving streaks, a warm weekly digest. Small, human.
8. **Honest empty states** — first run teaches (guided first entry / SMS permission), never a blank page.
9. **Accessibility** — readable type, tap targets, dark mode, works on low-end devices (most BD phones).

---

## 6. What makes users *love* it (the delight bets)

1. **"It tracks itself."** SMS auto-import = near-zero manual entry. This is the single biggest love driver —
   the difference between an app abandoned in week 2 and one opened daily. Sell it in onboarding.
2. **"It speaks my language."** Type or speak in Bangla, it just books the expense. No forms.
3. **"The numbers are right."** After the ledger work, spending, budget, and balance always agree. Trust.
4. **"It respects me."** Light ads, no dark patterns, core never paywalled, local-first privacy.
5. **"It knows my life."** Eid/festival budgeting, bKash/Nagad native, debt/EMI first-class (huge in BD).
6. **"It keeps me going."** Weekly "your money this week" digest, goal celebrations, gentle streaks.

Love = effortless + trustworthy + culturally native + respectful. Every Phase-2 AI feature must serve one
of these, or it doesn't ship.

---

## 7. Monetization mechanics (LOCKED)

- **Model:** free-forever core + **rewarded-ad unlock** (primary free-tier revenue) + **premium
  subscription** (RevenueCat, already built) + light banners. **No upfront paid app** (kills BD adoption).
- **Rewarded → AI:** the core mechanic (watch ad → earn AI actions); aligns ad revenue with AI cost.
- **BD pricing reality:** lead with **lifetime (one-time) and yearly**, not monthly — BD distrusts recurring
  card charges and card penetration is low. Use **local pricing** (e.g. ~৳99–149/mo, ৳999/yr, ৳1999
  lifetime — tune to market), payable ideally via methods BD users trust.
- **Optional power tier — BYO-key:** advanced users paste their own Gemini/OpenAI key for unlimited AI at
  zero cost to you. Low priority, but free to offer.
- **Cost control:** AI runs behind the VPS proxy with **server-side per-user quota + global daily spend
  cap**, plus a Google/Gemini **project spend cap**. Two independent guards → no runaway bill possible.

---

## 8. Phased execution (LOCKED sequence)

### Phase 1 — Lean, free, secure launch (NO AI yet)
Goal: ship the moat, build a user base, zero monetization pressure.
1. **DESYNC-3** (currency formatter honors the setting) — closes correctness.
2. **AI off/hidden** — chat/voice/receipt/RAG UI disabled or "coming soon" (chat tab: decide hide vs
   placeholder). App launches as a superb non-AI tracker: SMS import + Bangla manual + debt/goals/budget +
   analytics + local insights.
3. **Security — remove OpenAI key from the bundle** — delete the key line from `.env`, drop `.env` from
   pubspec assets (or key-less), **rotate the key**. (Datasources already route to the proxy URL, so with AI
   off they're dead — no proxy needed in Phase 1.)
4. **Release signing** (1c) — upload keystore, key.properties, R8 + ProGuard keeps.
5. **Focus & flow** — navigation overhaul (§4), onboarding-with-SMS-pitch, demote split/recurring, fold
   ai_guide, brand-name unification, prints→logger, remove dev artifacts.
6. **Usage analytics** — lightweight event logging (so Phase-2 decisions are data-driven).
7. **Store prep** — **READ_SMS Play declaration first (biggest external risk — validate early + fallback)**,
   Data Safety, privacy policy, account deletion, assets, iOS parity, staged rollout.

### Phase 2 — AI on + monetization
1. **VPS proxy** (Node/TS) — Gemini-ready, **provider-pluggable** (Gemini/Groq/OpenAI swappable server-side),
   Firebase ID-token + App Check auth, server-side quota mirroring `UsageLimits`, global spend cap.
2. **On-device-first AI** — ML Kit OCR (free) + Android STT `bn-BD` (free) feed the structuring call.
3. **Gemini Flash-Lite** for text→JSON structuring (paid tier in prod; free tier only for dev). Build a
   **Bengali eval set** and pick the cheapest model that clears the accuracy bar (Gemini vs Groq).
4. **Feature-gating (§2)** wired: free quotas + **rewarded-ad unlock** + premium unlocks.
5. **Ads** — `google_mobile_ads`, rewarded→quota hook into `UsageTrackerService`, light banners.
6. **AI features UI on** — chat, voice, receipt, RAG "ask."
7. Move **prediction + budget planner to local** (drop their AI calls).

### Phase 3 — Delight & scale
Home-screen widget + quick action, weekly digest, goal celebrations, unified Insights polish, festival
budgeting, advanced premium reports, iOS ATT/labels finalization.

---

## 9. Open items / risks

- 🔴 **READ_SMS restricted permission** — the moat depends on it; Google often rejects financial-SMS use.
  Validate the declaration + demo video **before** the launch gate; keep a fallback (manual paste /
  notification-listener). Highest external risk.
- 🟠 **Bengali AI accuracy** — must pass an eval before committing a model; cheapest-that-works, not cheapest.
- 🟠 **Split removal** — confirm with usage data before deleting the feature (cut the tab now regardless).
- 🟠 **Deferred debts** (CONTRIBUTING): missing-wallet UI prompt, deletePayment UI wiring, updateDebt wallet
  reconciliation, dedupe TOCTOU, debt-principal inflation — clear as they surface.

---

## 10. One-line summary

Ship a **free, effortless, trustworthy Bangla money-tracker** first (moat = SMS auto-import + Bangla entry,
correctness already fixed). Then layer **AI as an upsell** — cheap because OCR/voice are on-device — gated by
**rewarded-ad unlock + premium**, never touching the free core. Win users with *effortless + trustworthy +
culturally native + respectful*; monetize the top, keep the heart free.
