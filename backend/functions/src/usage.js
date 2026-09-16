'use strict';

const { LIMITS, MONTHLY_FEATURES, resetHint } = require('./config');

// Formats a Date in the given IANA timezone as 'yyyy-MM-dd' (en-CA yields an
// ISO-like date), matching DateFormat('yyyy-MM-dd') on the device.
function ymd(date, timeZone) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(date);
  const get = (type) => parts.find((p) => p.type === type).value;
  return { year: get('year'), month: get('month'), day: get('day') };
}

// Mirrors usage_tracker_service.dart _periodKey(feature).
function periodKey(feature, date, timeZone) {
  const { year, month, day } = ymd(date, timeZone);
  return MONTHLY_FEATURES.has(feature) ? `${year}-${month}` : `${year}-${month}-${day}`;
}

// Mirrors usage_tracker_service.dart _firestorePath(feature):
//   /users/{uid}/usage/{periodKey}
function usageDocRef(db, uid, feature, date, timeZone) {
  return db.doc(`users/${uid}/usage/${periodKey(feature, date, timeZone)}`);
}

/**
 * Authoritative server-side gate. Mirrors UsageTrackerService.checkAndConsume:
 * blocked when used >= limit, otherwise counter := used + 1 on the SAME field.
 * Runs in a transaction so concurrent requests can't oversell the quota.
 *
 * @returns {Promise<{allowed:boolean, feature:string, used:number, limit:number,
 *                     isMonthly:boolean, resetHint:string}>}
 */
async function checkAndConsume(db, uid, feature, timeZone) {
  const limit = LIMITS[feature];
  const isMonthly = MONTHLY_FEATURES.has(feature);
  const ref = usageDocRef(db, uid, feature, new Date(), timeZone);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const raw = snap.exists ? snap.get(feature) : 0;
    const used = typeof raw === 'number' ? raw : 0;

    if (used >= limit) {
      return { allowed: false, feature, used, limit, isMonthly, resetHint: resetHint(feature) };
    }

    // Same counter/field the app writes (app uses FieldValue.increment(1); a
    // transactional set to used+1 is equivalent and race-safe).
    tx.set(ref, { [feature]: used + 1 }, { merge: true });
    return { allowed: true, feature, used: used + 1, limit, isMonthly, resetHint: resetHint(feature) };
  });
}

module.exports = { checkAndConsume, periodKey, usageDocRef, ymd };
