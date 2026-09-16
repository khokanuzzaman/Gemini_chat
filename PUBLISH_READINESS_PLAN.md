# PocketPilot AI — Publish-Readiness & Cleanup Plan

> Repo: `gemini_chat` · Brand: **PocketPilot AI** · Flutter + Riverpod + Isar · OpenAI-assisted
> Scale audited: **263 Dart files, ~56,000 LOC, 16 features**, clean architecture, already-live offline users.
> Prepared as an execution brief for **Claude Code**. Hand this file to Claude Code phase-by-phase.

---

## 0. How to read this document

This plan is ordered by **risk, not by effort**. The first three items are *hard blockers* — the app
should not go to a public store until they are resolved, regardless of how polished the UI is. Everything
after that is quality, organization, and store paperwork.

Each task is written so you can paste it almost verbatim into Claude Code as a scoped instruction.

> ⚠️ **Branch note:** This audit was done on the `main` snapshot inside the zip. You mentioned a newer
> branch (`feat/dashboard-ux-overhaul` and/or `feat/full-app-ux-improvement` on `origin`) with more work
> that isn't here. **Do Phase 0 first** and re-validate every finding against the real latest branch before
> acting — some items below may already be fixed there, and new ones may exist.

---

## 1. What the app actually is (snapshot)

A Bengali-first, local-first personal finance tracker with heavy AI assistance.

- **Storage:** Isar (local, offline), SharedPreferences for settings/caches. No cloud sync.
- **AI:** OpenAI GPT-4o mini (chat expense extraction, receipt understanding, RAG insights, prediction,
  budget planner) + Whisper (voice) + Google ML Kit OCR (offline).
- **Navigation:** 5-tab bottom bar — হোম / চ্যাট / খরচ / বিশ্লেষণ / Split — over an `IndexedStack`.
- **16 features**, most fully layered (data/domain/presentation). Layer completeness:

| Fully layered (data+domain+presentation) | Presentation-only / thin |
| --- | --- |
| anomaly, budget, category, chat, expense, goals, income, prediction, recurring, split, wallet | export, onboarding, security, settings, splash |

- **Existing self-audit:** `AUDIT_REPORT_1_DATA_FLOW.md` already documents 1 critical, 6 high, 5 medium,
  4 low data-consistency issues. That report is trustworthy and its fix-order should be respected.
- **Code hygiene:** 0 TODO/FIXME markers, only 3 stray `print`/`debugPrint`. Codebase is clean-ish already.

**Verdict:** The engineering is far along. What's missing is *productionization* (secrets, signing, cost
model) and *feature/IA coherence* (16 features crammed behind 5 tabs) — not a rewrite.

---

## 2. Hard blockers — must fix before any public release

### B1 — 🔴 OpenAI API key ships inside the app (SECURITY / COST)

**Finding.** The key is read from `.env` via `flutter_dotenv`, and `.env` is declared as a bundled Flutter
asset in `pubspec.yaml` (`flutter: assets: - .env`). Every AI datasource calls `https://api.openai.com/...`
**directly from the device** with `Authorization: Bearer $apiKey`.

Affected files:
`lib/core/constants/api_constants.dart`, `lib/features/chat/data/datasources/openai_*_datasource.dart`,
`lib/features/prediction/data/datasources/prediction_datasource.dart`,
`lib/features/budget/data/datasources/budget_planner_datasource.dart`.

**Why it's a blocker.** A published APK/AAB is trivially decompiled. The key sits in `assets/.env` in
plaintext. Consequences: (a) anyone extracts your key and runs up your OpenAI bill; (b) it violates OpenAI's
policy against exposing keys in client apps; (c) you cannot rotate/limit per-user usage.

**Fix — introduce a thin backend proxy.** The app should never hold the OpenAI key.

1. Stand up a minimal proxy (e.g. a serverless function — Cloudflare Workers / Vercel / Firebase Functions /
   Supabase Edge). It holds `OPENAI_API_KEY` server-side and exposes 4 endpoints matching current usage:
   `/chat`, `/receipt`, `/voice` (Whisper passthrough), `/budget` (+ prediction can reuse `/chat`).
2. Add auth + rate limiting + a per-device/per-user monthly quota at the proxy (this is also where your
   cost model lives — see B3).
3. In the app, replace the 5 datasources' base URL + auth header: call `https://api.yourdomain.com/ai/*`
   with an app token, **not** a bearer OpenAI key. Delete `.env` from `pubspec.yaml` assets. Delete
   `openAiApiKey` from `ApiConstants`.
4. **Rotate the current OpenAI key immediately** — assume the one in the zip's `.env` is compromised the
   moment it left your machine.

> Claude Code task: *"Refactor all OpenAI datasources to call a configurable backend base URL via
> `--dart-define=API_BASE_URL=...` instead of hitting api.openai.com directly. Remove the OpenAI key from
> the app entirely, remove `.env` from pubspec assets, and centralize the HTTP client + auth header in one
> place under `lib/core/network/`."*

### B2 — 🔴 Release build is signed with DEBUG keys

**Finding.** `android/app/build.gradle`: the `release` block still uses
`signingConfig = signingConfigs.getByName("debug")` with the stock TODO comment. No `key.properties`, no
upload keystore.

**Why it's a blocker.** Play Console will reject a debug-signed AAB. And once you publish, the upload key is
permanent for that listing — get it right the first time.

**Fix.**
1. Generate an upload keystore (`keytool -genkey -v -keystore upload-keystore.jks ...`), store it **outside**
   the repo, back it up (losing it = losing the ability to update the app).
2. Add `android/key.properties` (git-ignored) and wire a proper `signingConfigs.release` reading from it.
3. Enable Play App Signing when you create the listing.
4. Also enable R8/shrinking for release: `minifyEnabled true`, `shrinkResources true`, plus a ProGuard/R8
   keep file for Isar, ML Kit, and reflection-sensitive libs.

> Claude Code task: *"Set up release signing via key.properties (git-ignored), add a release signingConfig,
> enable minify + resource shrinking, and add ProGuard keep rules for Isar and google_mlkit. Do not commit
> the keystore or key.properties."*

### B3 — 🔴 No unit-economics / cost model (BUSINESS blocker)

**Finding.** Every AI action costs *you* money (OpenAI GPT-4o mini + Whisper). With real users and the key
moving server-side (B1), you pay per call. There is currently no subscription, quota, or BYO-key path in the
codebase.

**Why it's a blocker.** Without this, growth = growing losses. This decision also shapes the proxy design
(B1) and the feature IA (Section 4). Pick one before launch:

- **Freemium quota** — N free AI actions/month, then a paywall or cooldown. (Most common; needs the proxy to
  count usage per user.)
- **Subscription** — monthly/annual unlocks unlimited (or high-cap) AI. (Play Billing integration.)
- **BYO-key** — power users paste their own OpenAI key; you host nothing. (Cheapest for you, worst UX, and
  note *most* users won't do this. Could be a fallback tier.)
- **Ad-supported free tier** — for a Bangladesh audience where paid conversion is low, ads may be more
  realistic than subscriptions for the free tier. (Mirrors the AdMob approach you use elsewhere.)

This is the one item on this list I can't decide for you — it's a product/market call. See "Open decisions".

---

## 3. Data-integrity fixes (from your own audit)

Your `AUDIT_REPORT_1_DATA_FLOW.md` is solid. Before launch, at minimum clear the **critical + high** items,
because these cause *silent wrong numbers*, which is fatal for a finance app's trust.

- **C1** — Wallet balance sync failures swallowed after expense/income commit → wallet can silently drift.
  **Must fix.**
- **H1** — Anomaly data not guaranteed fresh on refresh.
- **H2** — Prediction not reactive to most expense mutations (stale dashboard/RAG numbers).
- **H4** — Category rename/delete doesn't propagate into budgets.
- **H5** — Expense *updates* skip budget-alert checks.
- **H6** — Post-commit side-effect failure makes a successful save look failed (user re-enters, double data).

Medium/low (M1–M5, L1–L4) can be a fast-follow (v1.1), but **H6 and C1 are launch-critical** because they
directly corrupt user data or trust.

> Claude Code task: *"Work through AUDIT_REPORT_1_DATA_FLOW.md in its recommended fix order (Section 8).
> Start with C1 and H6. For each, add a regression test under `test/` before marking done."*

---

## 4. Feature organization & cleanup — "16 features, 5 tabs"

This is the core of your "organize features effectively" ask. Right now 16 features hang off a 5-tab shell;
discoverability and coherence suffer. Recommended information architecture (adjust to taste):

**Proposed 5 primary tabs (keep it to 5 max):**

1. **হোম (Home/Dashboard)** — summary, active budget teaser, prediction teaser, alerts summary, quick-add.
2. **চ্যাট (AI Chat)** — the hero AI entry (text/voice/receipt all funnel here).
3. **খরচ (Expenses)** — list, search, filters, manual add/edit; income folded in as a segment.
4. **প্ল্যান (Plan)** — *new grouping tab* that houses Budget, Goals, Recurring, Prediction, Anomaly as
   sections/cards. These are all "smart planning" surfaces that don't each deserve a tab but are lost today.
5. **আরও (More)** — Split, Wallet, Categories, Export, Settings, Security. A clean hub instead of burying them.

**Cleanup actions:**

- **Naming coherence.** The repo is `gemini_chat`, brand is `PocketPilot AI`, `.env.example` header says
  `SmartSpend`. Pick one public name and purge the others from user-facing strings, store copy, and docs.
  (Repo rename is optional/cosmetic; the *user-facing* inconsistency must go.)
- **Thin features → fold in.** `export` and `security` are presentation-only; make sure they live logically
  under Settings/More rather than pretending to be standalone features.
- **Dead code / caches.** Your audit flags `category_budgets` as a written-but-never-read cache key (M3) and
  some providers bypassing repositories (L1). Sweep these.
- **Strip the 3 stray `print`/`debugPrint`** and route through a proper logger gated on `kDebugMode`.
- **Remove dev artifacts from the repo/app:** `flutter_01.log`, `voice_test.wav`, `voice_test.aiff`,
  `.DS_Store`, `.idea/` — none should ship or sit in version control.

> Claude Code task: *"Introduce a `Plan` tab and a `More` hub per the IA in Section 4. Move Budget/Goals/
> Recurring/Prediction/Anomaly under Plan and Split/Wallet/Categories/Export/Settings/Security under More.
> Keep the same providers; this is navigation/routing + entry-point wiring only, no business-logic changes.
> Then unify all user-facing app names to 'PocketPilot AI' and remove SmartSpend/gemini_chat references."*

---

## 5. Play Store readiness checklist

Beyond signing (B2), the Play Console review will look at:

- **Permissions justification.** You request several sensitive perms. Trim and justify:
  - `WRITE_EXTERNAL_STORAGE` — likely unnecessary on modern Android with `share_plus`/scoped storage.
    **Remove if not truly needed** (Play flags legacy storage perms).
  - `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` — Play requires a **declaration** for exact alarms. Either
    justify (reminder scheduling) or switch reminders to inexact alarms to avoid the extra review gate.
  - `CAMERA`, `RECORD_AUDIO`, `POST_NOTIFICATIONS`, biometrics — fine, but each needs a clear in-app
    rationale prompt before the OS dialog.
- **Data Safety form.** You now send expense text / voice / receipt images to a backend → OpenAI. You **must**
  declare this: what data leaves the device, that it's sent to a third-party AI processor, retention, and
  whether it's used for the app's core function (yes). Do **not** claim "no data collected" — that would be a
  policy violation given the AI calls.
- **Privacy policy.** Required (AI + camera + audio + notifications). Must state OpenAI processing, local-first
  storage, and what the backend logs. Host a public URL; link it in the listing and in-app Settings.
- **Financial-app care.** If you ever add real bank/payment linkage it triggers stricter policies; a manual
  expense tracker is fine, but keep marketing copy from implying it moves money.
- **Target API level** — ensure `targetSdk` meets Play's current minimum for new apps (verify at build time).
- **Store assets** — 512×512 icon, feature graphic, phone screenshots (no debug/test banners visible),
  short + full description. (You have adaptive launcher icons already; store icon is separate.)
- **Account deletion** — Play requires an in-app + web path to delete user data. Since data is local, an
  in-app "delete all data" plus a documented web request path covers it; wire it into Settings.

---

## 6. Phased roadmap

| Phase | Goal | Gate to next phase |
| --- | --- | --- |
| **0. Sync** | Fetch/merge the real latest branch; re-run this audit against it. | Working tree builds & `flutter analyze` clean on latest. |
| **1. De-risk** | B1 (backend proxy + key removal), B2 (signing), rotate OpenAI key, C1 + H6 data fixes. | No secrets in app; release-signed AAB builds; wallet never silently drifts. |
| **2. Cost model** | Implement B3 decision (quota/subscription/ads) at proxy + minimal in-app UI. | AI calls are metered/paid; you can't be bill-bombed. |
| **3. Organize** | Section 4 IA (Plan + More tabs), naming unification, dead-code/artifact sweep, remaining high audit items (H1–H5). | Every feature reachable in ≤2 taps; one consistent brand name. |
| **4. Store prep** | Section 5 checklist: permissions trim, Data Safety, privacy policy, account deletion, store assets, screenshots. | Internal-testing track upload passes review. |
| **5. Launch** | Bump `version: 1.0.0+1`, closed → open testing → production rollout (staged %). | Live. |

Your **already-live offline users** matter here: because storage is local Isar, an update must **migrate
cleanly** — never wipe their data. Add an Isar schema-migration safety test to Phase 1, and test upgrade-in-
place (install old build → install new build → verify data intact) before every release.

---

## 7. Handing this to Claude Code — working style

- Give Claude Code **one phase at a time**, and within a phase, one task at a time. This codebase is large;
  scoped instructions produce better diffs than "make it production ready".
- For each task, ask Claude Code to: (1) state the plan, (2) make the change, (3) run `flutter analyze` +
  relevant tests, (4) summarize the diff. Don't let it batch B1+B2+IA in one shot.
- Keep `AUDIT_REPORT_1_DATA_FLOW.md` and this file in the repo root so Claude Code always has context.
- After Phase 1, regenerate a fresh data-flow audit to confirm C1/H6 are actually closed.

---

## 8. Open decisions (need your input — these change the plan)

1. **Cost model (B3):** freemium quota, subscription, ads, or BYO-key? This shapes the proxy and the IA.
2. **Backend host:** do you already have any backend, or start fresh serverless? Affects B1 approach.
3. **Platforms:** Play Store only, or also iOS App Store? (iOS/macOS folders exist; App Store adds its own
   review + privacy-nutrition-label work.)
4. **Existing users' key:** are current offline users somehow using AI already (their own key?), or is AI
   only reachable once you ship the backend? Affects migration messaging.

Answer these and the roadmap can be made concrete (specific proxy, specific billing SDK, specific timeline).

---

## 9. Locked decisions (2026-07-10) & their consequences

**Decided:** (1) Monetization = **ads-supported free tier**; (2) backend = **not yet chosen**;
(3) platforms = **Google Play + iOS App Store**.

### 9.1 The ad-economics reality (read this carefully)

Ads-supported + a Bangladesh-heavy audience means **very low ad revenue per user** (low eCPM). But every
AI call still costs real USD (GPT-4o mini + Whisper). So an ads-only model **only survives if per-user AI
usage is hard-capped** — otherwise one heavy user costs more in OpenAI than they'll ever earn you in ads.

**Therefore, even in an ads model, a per-user quota must live at the proxy (B1).** Concrete design:

- **Free, unlimited (zero marginal cost):** manual expense/income entry, expense list/search, analytics,
  split bill, goals math, recurring detection, category budgets. These use **no AI** — keep them fully open;
  they're your retention engine.
- **AI actions = metered:** chat expense extraction, receipt AI, voice/Whisper, AI budget planner,
  prediction. Give a **daily free AI quota** (e.g. 5–10 AI actions/day).
- **Rewarded ads = the perfect mechanic here.** "Watch a short ad → earn +5 AI entries." This *directly
  aligns cost with revenue*: the user generates ad revenue exactly when they consume AI cost. This is a much
  better fit than banners alone for covering OpenAI spend.
- **Banner/interstitial** on non-AI screens for baseline revenue, used sparingly (finance apps live on trust;
  don't make it feel spammy).

> Net: the proxy isn't just a security fix — it's your **billing meter + abuse limiter + ad-reward
> validator**. Budget-cap OpenAI spend server-side per user per day so a bad actor can't bankrupt you.

### 9.2 Backend recommendation (since undecided)

For a cost-sensitive, ads-funded, solo build that also uses Google AdMob, the most coherent pick:

- **Primary rec — Firebase.** Cloud Functions (the OpenAI proxy) + **Firebase App Check** (this is the key
  piece: it cryptographically attests that requests come from *your real app*, blocking randoms from draining
  your OpenAI budget through the proxy) + anonymous Firebase Auth (per-device quota identity) + Remote Config
  (tune quotas without shipping an update). Bonus: same Google ecosystem as AdMob, easy Analytics.
- **Lean alternative — Cloudflare Workers.** Cheapest at scale, generous free tier, but you'd add your own
  attestation + quota store (KV/D1). Pick this only if you want to avoid Firebase.

Whichever you choose, the app-side change (B1) is identical: swap the 5 datasources to call your proxy via
`--dart-define=API_BASE_URL=...` with an attestation token, never an OpenAI key.

### 9.3 iOS App Store additions (because you chose both platforms)

Everything in Sections 2–5 still applies; iOS adds:

- **App Tracking Transparency (ATT):** AdMob personalized ads require the ATT prompt + `NSUserTrackingUsage
  Description` in `Info.plist`. Without it, Apple rejects, and you can only serve non-personalized ads.
- **Privacy "nutrition labels":** the App Store's equivalent of Play's Data Safety — declare AI data
  processing, camera, mic, and **ad/tracking data collection**. Must match your Play declaration.
- **SKAdNetwork** IDs for AdMob attribution in `Info.plist`.
- **iOS signing:** Apple Developer account ($99/yr), provisioning profiles, App Store Connect app record.
- **Permission usage strings** in `Info.plist`: camera, microphone, (Face ID) `NSFaceIDUsageDescription`,
  photo library. iOS rejects missing usage strings.
- **macOS folder exists but is not a store target** — ignore it for launch (or explicitly disable that build).

### 9.4 Android ad-specific additions

- Add the AdMob App ID to `AndroidManifest.xml` and the **`com.google.android.gms.permission.AD_ID`**
  permission (required for advertising ID on Android 13+).
- **Play Data Safety must now declare advertising data collection** (advertising ID, approximate usage) in
  addition to the AI-processing declaration.
- Keep the AdMob **App ID and unit IDs out of the client where feasible / use test IDs in debug** so you
  don't accidentally serve/click live ads during development (policy risk → account ban).

### 9.5 Revised launch roadmap (with decisions applied)

| Phase | Now includes |
| --- | --- |
| **0. Sync** | Pull the real latest branch; re-validate this audit. |
| **1. De-risk** | Backend proxy on **Firebase** (Functions + App Check + anon Auth) + remove OpenAI key from app; release signing (B2); rotate key; C1 + H6 data fixes; Isar upgrade-in-place migration test. |
| **2. Monetize** | Per-user daily AI quota at proxy; **rewarded-ad → earn AI actions**; banner/interstitial on non-AI screens; server-side daily OpenAI spend cap. |
| **3. Organize** | Plan + More tabs (Section 4); unify brand name; dead-code/artifact sweep; H1–H5. |
| **4. Store prep (×2)** | Play: Data Safety (AI + ads), AD_ID perm, permissions trim, privacy policy, account deletion. iOS: ATT, privacy labels, SKAdNetwork, Info.plist usage strings, App Store Connect record. |
| **5. Launch** | Bump `1.0.0+1`; internal → closed → open → staged production on both stores. |

### 9.6 Still worth confirming (not blocking)

- Do your **current offline users** already use AI (their own key), or is AI new-with-the-backend? This only
  changes your migration/announcement messaging, not the build.
