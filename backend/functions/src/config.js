'use strict';

// ---------------------------------------------------------------------------
// Quota contract — mirrors the Flutter app EXACTLY. Do not diverge.
// Source of truth: lib/core/usage/usage_limits.dart
//                  lib/core/usage/usage_tracker_service.dart
//
// Firestore doc:   users/{uid}/usage/{periodKey}
//   periodKey    = 'yyyy-MM'    when the feature is monthly (ai_budget)
//                = 'yyyy-MM-dd' otherwise (daily)
//   field name   = the feature key itself (e.g. "ai_chat"), value = integer
//   consume rule = blocked when used >= limit, else counter := used + 1
//
// The app formats the period key with the DEVICE's local time. This proxy uses
// USAGE_TIMEZONE (default Asia/Dhaka) so server and client land on the same
// daily/monthly bucket. Keep them in sync.
// ---------------------------------------------------------------------------

// Mirrors UsageLimits.limitFor(...) in usage_limits.dart.
const LIMITS = Object.freeze({
  ai_chat: 20, // UsageLimits.aiChatPerDay
  receipt_scan: 5, // UsageLimits.receiptScanPerDay
  voice_input: 10, // UsageLimits.voiceInputPerDay
  ai_budget: 3, // UsageLimits.aiBudgetPerMonth (monthly)
});

// Mirrors UsageLimits.isMonthly(...) — only ai_budget is monthly.
const MONTHLY_FEATURES = Object.freeze(new Set(['ai_budget']));

// Features the app meters via X-AI-Feature on /v1/chat/completions.
// (voice_input is metered on the transcriptions route, not via this header.)
const CHAT_METERED_FEATURES = Object.freeze(
  new Set(['ai_chat', 'receipt_scan', 'ai_budget']),
);

// Explicitly unmetered passthrough features. Prediction has no limit in the app
// (no key in usage_limits.dart), so it stays unmetered here too — we do NOT
// invent a limit. The app must send `X-AI-Feature: prediction` for these calls.
const UNMETERED_FEATURES = Object.freeze(new Set(['prediction']));

// Mirrors UsageLimits.resetAtBengali for the 429 body copy.
function resetHint(feature) {
  return MONTHLY_FEATURES.has(feature)
    ? 'আগামী মাসের ১ তারিখে'
    : 'আজ রাত ১২টায়';
}

function num(envValue, fallback) {
  const parsed = Number(envValue);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function bool(envValue, fallback) {
  if (envValue === undefined || envValue === '') return fallback;
  return envValue === 'true' || envValue === '1';
}

const IS_EMULATOR = process.env.FUNCTIONS_EMULATOR === 'true';

const config = {
  isEmulator: IS_EMULATOR,

  openAiBaseUrl: (process.env.OPENAI_BASE_URL || 'https://api.openai.com').replace(/\/+$/, ''),
  usageTimezone: process.env.USAGE_TIMEZONE || 'Asia/Dhaka',

  // App Check is enforced in production; relaxed under the emulator (which
  // cannot mint real App Check tokens) unless explicitly overridden.
  enforceAppCheck: bool(process.env.ENFORCE_APP_CHECK, !IS_EMULATOR),

  // Global daily OpenAI spend cap (USD). A Firestore config doc can override it
  // and provides the kill switch — see spend.js.
  defaultDailyCapUsd: num(process.env.DAILY_CAP_USD, 10),

  // gpt-4o-mini pricing (USD per 1M tokens) — tune via env as prices change.
  priceInPerMillion: num(process.env.PRICE_IN_PER_M, 0.15),
  priceOutPerMillion: num(process.env.PRICE_OUT_PER_M, 0.6),

  // Whisper is billed per audio-minute; we can't cheaply measure duration in the
  // proxy, so we charge a flat per-call estimate against the spend cap.
  whisperFlatUsd: num(process.env.WHISPER_FLAT_USD, 0.01),

  // Emulator convenience: return a canned response instead of calling OpenAI so
  // auth/quota/cap can be exercised without spending money. Off in production.
  mockOpenAi: bool(process.env.MOCK_OPENAI, false),
};

module.exports = {
  config,
  LIMITS,
  MONTHLY_FEATURES,
  CHAT_METERED_FEATURES,
  UNMETERED_FEATURES,
  resetHint,
};
