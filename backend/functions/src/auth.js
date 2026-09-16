'use strict';

const admin = require('firebase-admin');
const { config } = require('./config');

// Extracts a Bearer token from the Authorization header.
function bearer(req) {
  const header = req.get('authorization') || '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match ? match[1].trim() : null;
}

/**
 * Express middleware chain that authenticates every request:
 *   1. Firebase ID token (Authorization: Bearer <idToken>) -> req.uid
 *   2. Firebase App Check token (X-Firebase-AppCheck)       -> attested build
 * Rejects with 401 if either is missing/invalid.
 */
async function authenticate(req, res, next) {
  // --- 1. Firebase ID token -> uid ---------------------------------------
  const idToken = bearer(req);
  if (!idToken) {
    return res.status(401).json({ error: 'unauthenticated', message: 'Missing Authorization bearer token.' });
  }
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    req.uid = decoded.uid;
  } catch (err) {
    console.warn('ID token verification failed:', err.message);
    return res.status(401).json({ error: 'unauthenticated', message: 'Invalid or expired ID token.' });
  }

  // --- 2. Firebase App Check token ---------------------------------------
  if (config.enforceAppCheck) {
    const appCheckToken = req.get('x-firebase-appcheck');
    if (!appCheckToken) {
      return res.status(401).json({ error: 'app_check_required', message: 'Missing X-Firebase-AppCheck token.' });
    }
    try {
      await admin.appCheck().verifyToken(appCheckToken);
    } catch (err) {
      console.warn('App Check verification failed:', err.message);
      return res.status(401).json({ error: 'app_check_invalid', message: 'Request is not attested.' });
    }
  }

  return next();
}

module.exports = { authenticate };
