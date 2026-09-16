'use strict';

const express = require('express');
const admin = require('firebase-admin');

const {
  config,
  CHAT_METERED_FEATURES,
  UNMETERED_FEATURES,
  resetHint,
} = require('./config');
const { authenticate } = require('./auth');
const { checkAndConsume } = require('./usage');
const { checkSpendAllowed, addSpend, chatCostUsd } = require('./spend');

// Rate-limit / retry headers we pass back so the app's RateLimitSnapshot keeps working.
const PASSTHROUGH_RESPONSE_HEADERS = [
  'x-ratelimit-limit-requests',
  'x-ratelimit-remaining-requests',
  'x-ratelimit-limit-tokens',
  'x-ratelimit-remaining-tokens',
  'x-ratelimit-reset-requests',
  'x-ratelimit-reset-tokens',
  'retry-after',
];

// Parse the final `usage` object out of a captured chat SSE stream (present when
// the app sends stream_options.include_usage). Returns null if absent.
function parseChatUsage(sse) {
  let usage = null;
  for (const line of sse.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed.startsWith('data:')) continue;
    const payload = trimmed.slice(5).trim();
    if (payload === '[DONE]' || !payload.startsWith('{')) continue;
    try {
      const json = JSON.parse(payload);
      if (json && json.usage) usage = json.usage;
    } catch (_) {
      /* partial chunk — ignore */
    }
  }
  return usage;
}

// Streams OpenAI's response through to the client. For chat, captures the SSE so
// the caller can compute cost. `onComplete(capturedText)` runs after the stream.
async function forwardToOpenAi(req, res, { path, apiKey, capture, onComplete }) {
  if (config.mockOpenAi) {
    return mockResponse(res, { path, capture, onComplete });
  }

  let upstream;
  try {
    upstream = await fetch(`${config.openAiBaseUrl}${path}`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': req.get('content-type') || 'application/json',
        Accept: req.get('accept') || 'text/event-stream',
      },
      body: req.rawBody, // raw passthrough — bodies stay identical to OpenAI's contract
    });
  } catch (err) {
    console.error('Upstream request failed:', err);
    return res.status(502).json({ error: 'upstream_unreachable', message: 'Could not reach the AI provider.' });
  }

  res.status(upstream.status);
  const contentType = upstream.headers.get('content-type');
  if (contentType) res.set('Content-Type', contentType);
  for (const name of PASSTHROUGH_RESPONSE_HEADERS) {
    const value = upstream.headers.get(name);
    if (value) res.set(name, value);
  }

  if (!upstream.body) {
    res.end();
    if (onComplete) await onComplete('');
    return undefined;
  }

  let captured = '';
  for await (const chunk of upstream.body) {
    const buffer = Buffer.from(chunk);
    res.write(buffer);
    if (capture && captured.length < 256 * 1024) {
      captured += buffer.toString('utf8');
    }
  }
  res.end();
  if (onComplete) await onComplete(captured);
  return undefined;
}

// Canned response for the emulator (MOCK_OPENAI=true) so quota/cap/auth can be
// tested without spending real money.
async function mockResponse(res, { path, capture, onComplete }) {
  if (path === '/v1/audio/transcriptions') {
    res.status(200).set('Content-Type', 'text/plain; charset=utf-8');
    res.end('নাস্তা ৩০ টাকা');
    if (onComplete) await onComplete('');
    return undefined;
  }
  res.status(200).set('Content-Type', 'text/event-stream');
  const chunks = [
    'data: {"choices":[{"delta":{"content":"[MOCK] "}}]}\n\n',
    'data: {"choices":[{"delta":{"content":"পরীক্ষা"}}]}\n\n',
    'data: {"choices":[{"delta":{}}],"usage":{"prompt_tokens":50,"completion_tokens":10,"total_tokens":60}}\n\n',
    'data: [DONE]\n\n',
  ];
  let captured = '';
  for (const chunk of chunks) {
    res.write(chunk);
    if (capture) captured += chunk;
  }
  res.end();
  if (onComplete) await onComplete(captured);
  return undefined;
}

function resolveChatFeature(req, res) {
  const feature = (req.get('x-ai-feature') || '').trim();
  if (CHAT_METERED_FEATURES.has(feature)) return { feature, metered: true };
  if (UNMETERED_FEATURES.has(feature)) return { feature, metered: false };
  res.status(400).json({
    error: 'unknown_feature',
    message:
      'X-AI-Feature must be one of ai_chat | receipt_scan | ai_budget (metered) or prediction (unmetered).',
  });
  return null;
}

function quotaExceededBody(gate) {
  return {
    error: 'quota_exceeded',
    feature: gate.feature,
    used: gate.used,
    limit: gate.limit,
    isMonthly: gate.isMonthly,
    resetHint: gate.resetHint,
    message: `Daily/monthly limit reached for ${gate.feature}.`,
  };
}

function spendBlockedBody(spend) {
  return {
    error: 'ai_unavailable',
    reason: spend.reason, // 'kill_switch' | 'daily_cap'
    message:
      spend.reason === 'kill_switch'
        ? 'AI is temporarily disabled.'
        : 'The daily AI budget has been reached. Please try again tomorrow.',
  };
}

// Shared handler: spend gate (503) -> quota consume (429) -> forward.
async function handleAiRequest(req, res, { db, apiKey, path, feature, metered, capture, onComplete }) {
  const spend = await checkSpendAllowed(db, config.usageTimezone);
  if (!spend.ok) {
    return res.status(503).json(spendBlockedBody(spend));
  }

  if (metered) {
    const gate = await checkAndConsume(db, req.uid, feature, config.usageTimezone);
    if (!gate.allowed) {
      return res.status(429).json(quotaExceededBody(gate));
    }
  }

  return forwardToOpenAi(req, res, { path, apiKey, capture, onComplete });
}

/**
 * Builds the Express app. `getApiKey()` returns the OpenAI key from Functions
 * secrets at request time (never bundled in the app).
 */
function createApp({ getApiKey }) {
  const app = express();
  app.disable('x-powered-by');

  const db = () => admin.firestore();

  app.get('/healthz', (_req, res) => res.json({ ok: true }));

  app.use(authenticate);

  // Chat / receipt / budget (and unmetered prediction) — OpenAI chat completions.
  app.post('/v1/chat/completions', async (req, res) => {
    const resolved = resolveChatFeature(req, res);
    if (!resolved) return undefined;
    return handleAiRequest(req, res, {
      db: db(),
      apiKey: getApiKey(),
      path: '/v1/chat/completions',
      feature: resolved.feature,
      metered: resolved.metered,
      capture: true,
      onComplete: async (sse) => {
        const usage = parseChatUsage(sse);
        await addSpend(db(), chatCostUsd(usage), config.usageTimezone);
      },
    });
  });

  // Voice transcription — always metered as voice_input (Whisper).
  app.post('/v1/audio/transcriptions', async (req, res) => {
    return handleAiRequest(req, res, {
      db: db(),
      apiKey: getApiKey(),
      path: '/v1/audio/transcriptions',
      feature: 'voice_input',
      metered: true,
      capture: false,
      onComplete: async () => {
        await addSpend(db(), config.whisperFlatUsd, config.usageTimezone);
      },
    });
  });

  app.use((_req, res) => res.status(404).json({ error: 'not_found' }));

  return app;
}

module.exports = { createApp, parseChatUsage };
