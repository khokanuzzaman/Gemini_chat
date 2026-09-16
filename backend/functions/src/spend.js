'use strict';

const admin = require('firebase-admin');
const { config } = require('./config');
const { ymd } = require('./usage');

// Global daily spend accounting + kill switch.
//
// config/openai_proxy      { killSwitch: bool, dailyCapUsd: number }
//   killSwitch  — flip to true to hard-stop all AI (acts as Remote-Config-style
//                 kill switch); the proxy returns 503 while set.
//   dailyCapUsd — overrides DAILY_CAP_USD env when present.
//
// ai_spend/{yyyy-MM-dd}    { usd: number }  — running spend for the day (server tz).

function dayKey(date, timeZone) {
  const { year, month, day } = ymd(date, timeZone);
  return `${year}-${month}-${day}`;
}

function configRef(db) {
  return db.doc('config/openai_proxy');
}

function spendRef(db, date, timeZone) {
  return db.doc(`ai_spend/${dayKey(date, timeZone)}`);
}

/**
 * Returns { ok: true } when spending is allowed, or
 * { ok: false, reason: 'kill_switch' | 'daily_cap', capUsd, spentUsd } when not.
 */
async function checkSpendAllowed(db, timeZone) {
  const [cfgSnap, spendSnap] = await Promise.all([
    configRef(db).get(),
    spendRef(db, new Date(), timeZone).get(),
  ]);

  const cfg = cfgSnap.exists ? cfgSnap.data() : {};
  if (cfg && cfg.killSwitch === true) {
    return { ok: false, reason: 'kill_switch' };
  }

  const capUsd =
    cfg && typeof cfg.dailyCapUsd === 'number' ? cfg.dailyCapUsd : config.defaultDailyCapUsd;
  const spentUsd =
    spendSnap.exists && typeof spendSnap.get('usd') === 'number' ? spendSnap.get('usd') : 0;

  if (spentUsd >= capUsd) {
    return { ok: false, reason: 'daily_cap', capUsd, spentUsd };
  }
  return { ok: true, capUsd, spentUsd };
}

/** Best-effort: add estimated USD to today's running total. Never throws. */
async function addSpend(db, usd, timeZone) {
  if (!usd || usd <= 0) return;
  try {
    await spendRef(db, new Date(), timeZone).set(
      { usd: admin.firestore.FieldValue.increment(usd) },
      { merge: true },
    );
  } catch (err) {
    console.error('addSpend failed', err);
  }
}

// gpt-4o-mini cost from an OpenAI usage object { prompt_tokens, completion_tokens }.
function chatCostUsd(usage) {
  if (!usage) return 0;
  const input = (Number(usage.prompt_tokens) || 0) / 1e6 * config.priceInPerMillion;
  const output = (Number(usage.completion_tokens) || 0) / 1e6 * config.priceOutPerMillion;
  return input + output;
}

module.exports = { checkSpendAllowed, addSpend, chatCostUsd, dayKey };
