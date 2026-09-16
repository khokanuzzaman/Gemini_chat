# PocketPilot AI — OpenAI Proxy (Firebase Cloud Functions)

A thin, authenticated proxy in front of OpenAI. The app never holds the OpenAI
key; instead it calls this proxy, which:

- verifies a **Firebase ID token** (`Authorization: Bearer <idToken>`) → `uid`
- verifies a **Firebase App Check token** (`X-Firebase-AppCheck`) → attested build
- enforces the **same per-user daily/monthly quota the app already tracks**
  (mirrors `lib/core/usage/usage_limits.dart` + `usage_tracker_service.dart`)
- enforces a **global daily OpenAI spend cap** + kill switch (returns 503)
- forwards request/response bodies **unchanged** to OpenAI (OpenAI-mirrored paths)

> Scope: this folder is self-contained and does **not** touch the Flutter app.
> App-side wiring (sending the tokens/headers) is **Task 1b-app** — see
> [Integration contract](#integration-contract-task-1b-app).

## Folder structure

```
backend/
  firebase.json              # functions + emulator config
  .firebaserc.example        # copy to .firebaserc, set your project id
  .gitignore
  functions/
    package.json             # Node 20, express + firebase-admin + firebase-functions
    index.js                 # entry: defines the `api` HTTPS function (region asia-south1)
    .env.example             # copy to .env — tunables (NOT the secret)
    .gitignore
    src/
      config.js              # quota mirror, limits, pricing, feature routing, env
      auth.js                # ID-token + App Check middleware
      usage.js               # period keys + checkAndConsume (mirrors the Dart paths)
      spend.js               # global daily spend cap + kill switch
      proxy.js               # express app, routes, OpenAI streaming passthrough
```

## Endpoints

Both mirror OpenAI's paths and pass the body through untouched:

| Method & path                     | Meters as                                   | Upstream |
|-----------------------------------|---------------------------------------------|----------|
| `POST /v1/chat/completions`       | `X-AI-Feature`: `ai_chat` \| `receipt_scan` \| `ai_budget` (metered), or `prediction` (unmetered) | OpenAI chat completions |
| `POST /v1/audio/transcriptions`   | `voice_input` (always)                       | OpenAI Whisper |

Responses on failure:

- `401` — missing/invalid ID token or App Check token
- `400` — unknown/absent `X-AI-Feature` on the chat route
- `429` — over per-user quota (JSON body: `feature`, `used`, `limit`, `isMonthly`, `resetHint`)
- `503` — global spend cap reached or kill switch on
- `502` — OpenAI unreachable

## Quota mirror (must stay in sync with the app)

- Firestore doc: `users/{uid}/usage/{periodKey}`
- `periodKey` = `yyyy-MM` for `ai_budget` (monthly), else `yyyy-MM-dd` (daily)
- Field name = the feature key (`ai_chat`, …); value = integer counter
- Limits: `ai_chat` 20/day, `receipt_scan` 5/day, `voice_input` 10/day, `ai_budget` 3/month
- Consume rule: blocked when `used >= limit`, else counter `:= used + 1`
- **Timezone:** the app formats the period key with the device's local time. This
  proxy uses `USAGE_TIMEZONE` (default `Asia/Dhaka`) so both land on the same
  bucket. If your users span timezones, revisit this.

## Global spend cap & kill switch

Create a Firestore doc `config/openai_proxy`:

```jsonc
{
  "killSwitch": false,   // set true to hard-stop all AI (proxy returns 503)
  "dailyCapUsd": 10      // optional; overrides DAILY_CAP_USD env
}
```

Running spend is accumulated in `ai_spend/{yyyy-MM-dd}` (`{ usd: number }`).
Chat cost is computed from the streamed `usage` object; Whisper is charged a flat
`WHISPER_FLAT_USD` estimate. Tune pricing in `.env`.

## Prerequisites

- Node.js 20, Firebase CLI (`npm i -g firebase-tools`)
- A Firebase project with **Firestore**, **Authentication**, and **App Check** enabled
- `cd backend && cp .firebaserc.example .firebaserc` and set your project id
- `cd functions && npm install`

## Secrets

The OpenAI key is a Functions **secret**, never committed and never in the app:

```bash
cd backend
firebase functions:secrets:set OPENAI_API_KEY   # paste the key when prompted
```

For the **emulator**, create `functions/.secret.local` (git-ignored):

```
OPENAI_API_KEY=sk-...            # or any placeholder if using MOCK_OPENAI=true
```

## Local emulator testing

```bash
cd backend/functions
cp .env.example .env
# For a no-cost run, set MOCK_OPENAI=true in .env (returns a canned response).
cd ..
firebase emulators:start --only functions,firestore,auth
```

Under the emulator, App Check is auto-relaxed (real App Check tokens can't be
minted locally); the ID token is still required and verified against the Auth
emulator.

1. Mint a test ID token from the Auth emulator:

```bash
ID_TOKEN=$(curl -s -X POST \
  "http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=any" \
  -H 'Content-Type: application/json' -d '{"returnSecureToken":true}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["idToken"])')
```

2. Call the chat endpoint (function base path is `/api`):

```bash
BASE="http://localhost:5001/<your-project-id>/asia-south1/api"

curl -N -X POST "$BASE/v1/chat/completions" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "X-AI-Feature: ai_chat" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","stream":true,"stream_options":{"include_usage":true},"messages":[{"role":"user","content":"নাস্তা ৩০ টাকা"}]}'
```

3. Verify quota: repeat the call 20× and confirm the 21st returns `429`. Inspect
   the counter in the Emulator UI (Firestore → `users/<uid>/usage/<yyyy-MM-dd>`,
   field `ai_chat`).

4. Verify the kill switch: in the Emulator UI create `config/openai_proxy` with
   `killSwitch: true` → the next call returns `503`.

5. Missing token → `401`; unknown `X-AI-Feature` → `400`.

## Deploy

```bash
cd backend
firebase functions:secrets:set OPENAI_API_KEY   # once (and on rotation)
firebase deploy --only functions
```

Deployed base URL:

```
https://asia-south1-<your-project-id>.cloudfunctions.net/api
```

so the app's `API_BASE_URL` becomes that value (the gateway appends
`/v1/chat/completions` etc.). Optionally front it with Firebase Hosting rewrites
for a custom domain.

After deploy, create the `config/openai_proxy` doc and set a sensible
`dailyCapUsd`. Enable **App Check enforcement** for your app platforms in the
Firebase console.

## Integration contract (Task 1b-app)

The Flutter gateway (`lib/core/network/ai_gateway.dart`) must, per request:

- set `Authorization: Bearer <Firebase ID token>` (from `FirebaseAuth`)
- set `X-Firebase-AppCheck: <App Check token>` — this **replaces** the current
  `X-App-Attestation` placeholder header from Task 1
- set `X-AI-Feature` to the metered key for chat/receipt/budget, or `prediction`
  for the (unmetered) prediction call
- build with `--dart-define=API_BASE_URL=https://asia-south1-<project>.cloudfunctions.net/api`

**Double-counting note:** today the app both gates and writes these counters
client-side (`UsageTrackerService.increment` → Firestore). Once the server also
consumes on each call, Task 1b-app must make the client stop writing Firestore
for AI features (keep local increment for offline UX display, but treat the
server as the single Firestore writer) — otherwise each AI action counts twice.
