'use strict';

const admin = require('firebase-admin');
const { setGlobalOptions } = require('firebase-functions/v2');
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');

const { createApp } = require('./src/proxy');

admin.initializeApp();

// OpenAI key lives in Functions Secret Manager — never in the app bundle.
const OPENAI_API_KEY = defineSecret('OPENAI_API_KEY');

// asia-south1 (Mumbai) is the closest region for a Bangladesh audience.
setGlobalOptions({ region: 'asia-south1', maxInstances: 20 });

const app = createApp({ getApiKey: () => OPENAI_API_KEY.value() });

// Single HTTP function exposing the OpenAI-mirrored routes:
//   POST <baseUrl>/v1/chat/completions
//   POST <baseUrl>/v1/audio/transcriptions
// where baseUrl = https://asia-south1-<project>.cloudfunctions.net/api
exports.api = onRequest(
  {
    secrets: [OPENAI_API_KEY],
    timeoutSeconds: 120,
    memory: '512MiB', // headroom for buffering ~25MB Whisper uploads
    invoker: 'public', // auth is enforced in-app via ID token + App Check
  },
  app,
);
