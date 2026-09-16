# Claude Code — Kickoff & Task Prompts (PocketPilot AI)

Point Claude Code at this file plus `PUBLISH_READINESS_PLAN.md` and `AUDIT_REPORT_1_DATA_FLOW.md`.
Run **one task at a time**. After every task, make Claude Code run `flutter analyze` + tests and summarize
the diff before you approve the next.

---

## Setup (do once)

Put these three files in the repo root so Claude Code always has context:
- `PUBLISH_READINESS_PLAN.md`  (the full plan)
- `AUDIT_REPORT_1_DATA_FLOW.md`  (already there)
- `CLAUDE_CODE_KICKOFF.md`  (this file)

Tell Claude Code at the start of the session:

```
Read PUBLISH_READINESS_PLAN.md and AUDIT_REPORT_1_DATA_FLOW.md in full before doing anything.
This is a large, live app (263 files, ~56K LOC) with real users on local Isar data.
Rules for this whole session:
- Do ONE task at a time, exactly as scoped. Do not batch tasks.
- Never widen scope or refactor unrelated code without asking.
- After each change: run `flutter analyze` and relevant tests, then summarize the diff and stop.
- Never wipe or migrate user data destructively — existing users must upgrade in place.
- Never commit secrets, keystores, or .env files.
Acknowledge these rules, then wait for my first task.
```

---

## PHASE 0 — Sync & re-validate (do first)

```
TASK: Sync to the real latest branch and re-validate the audit.
1. Show `git status`, `git branch -a`, and the last 15 commits.
2. Fetch origin. There are feature branches (feat/dashboard-ux-overhaul, feat/full-app-ux-improvement)
   with newer work than the snapshot the plan was written against. Tell me which branch is truly latest
   and propose a merge/rebase strategy — do not merge yet, just propose.
3. Once I pick the branch, check it out.
4. Re-validate these specific findings against the latest code and report a short DELTA (fixed / still open):
   - Is `.env` still listed under `flutter: assets:` in pubspec.yaml?
   - Do the AI datasources still call api.openai.com directly with a Bearer key?
     (lib/features/chat/data/datasources/*, prediction, budget)
   - Does android/app/build.gradle release block still use the debug signingConfig?
   - Are there still stray print/debugPrint calls?
   - Do audit items C1 and H6 still reproduce?
5. Output the delta as a checklist. Do not fix anything yet.
```

---

## PHASE 1 — De-risk (highest priority)

### Task 1a — App-side: stop shipping the OpenAI key

```
TASK: Remove the OpenAI key from the app and route all AI calls through a configurable backend base URL.
- Create a single HTTP client + AI gateway under lib/core/network/ (e.g. ai_gateway.dart).
- All five AI datasources (chat, receipt, voice, prediction, budget) must call this gateway, which targets
  a base URL from `--dart-define=API_BASE_URL=...` (default empty → clear error), NOT api.openai.com.
- The gateway sends an app attestation/auth token header (placeholder for now, wired to Firebase App Check
  in Task 1b), never an OpenAI key.
- Delete `openAiApiKey` from lib/core/constants/api_constants.dart and remove `.env` from pubspec assets.
- Remove dotenv usage that exists only for the key.
- Keep request/response shapes identical so the backend can mirror OpenAI's contract.
- Run flutter analyze + tests. Summarize the diff. Do not touch UI.
```

### Task 1b — Backend: the Firebase proxy (separate from the Flutter repo)

```
TASK: Scaffold a Firebase Cloud Functions proxy for OpenAI.
- Endpoints mirroring current usage: /ai/chat, /ai/receipt, /ai/voice (Whisper), /ai/budget (prediction reuses chat).
- Hold OPENAI_API_KEY in Functions config/secrets (never in the app).
- Enforce Firebase App Check on every endpoint (reject non-attested requests).
- Add per-user daily AI quota using anonymous Firebase Auth uid + a Firestore counter.
- Add a server-side global daily OpenAI spend cap as a kill-switch.
- Return a clear 429 when quota is exhausted (the app will show "watch an ad for more").
Give me the folder structure and deploy steps.
```

### Task 1c — Release signing

```
TASK: Set up Android release signing properly.
- Add android/key.properties (git-ignored) and a release signingConfig that reads from it.
- Replace the debug signingConfig in the release block.
- Enable minifyEnabled + shrinkResources for release, and add ProGuard/R8 keep rules for Isar and
  google_mlkit_text_recognition.
- Do NOT generate or commit the keystore — give me the exact keytool command to run myself and where to store it.
```

### Task 1d — Launch-critical data fixes + migration safety

```
TASK: Fix the launch-critical data-integrity issues from AUDIT_REPORT_1_DATA_FLOW.md.
- Start with C1 (wallet sync failures swallowed) and H6 (successful mutation looks failed).
- For each, add a regression test under test/ that fails before the fix and passes after.
- Also add an Isar "upgrade-in-place" test: seed data on the old schema, open with the new code, assert no
  data loss. This protects existing offline users on update.
```

---

## After Phase 1

Regenerate a fresh data-flow audit and confirm C1/H6 are closed. Then move to Phase 2 (quota + rewarded
ads), Phase 3 (Plan/More tab reorg + naming unification), Phase 4 (Play + iOS store prep), Phase 5 (launch),
each driven the same one-task-at-a-time way, following PUBLISH_READINESS_PLAN.md Sections 4, 5, and 9.5.
