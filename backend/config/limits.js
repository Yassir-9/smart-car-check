// Single source of truth for the free monthly diagnosis limit.
// Override with FREE_MONTHLY_LIMIT (positive integer); invalid values fall back.
const DEFAULT_FREE_MONTHLY_LIMIT = 7;

function getFreeMonthlyLimit(env = process.env) {
  const raw = String(env.FREE_MONTHLY_LIMIT ?? '').trim();
  const parsed = /^\d+$/.test(raw) ? Number.parseInt(raw, 10) : 0;
  return parsed > 0 ? parsed : DEFAULT_FREE_MONTHLY_LIMIT;
}

// Start of the next calendar month (when the monthly usage counter starts over).
function nextMonthStartIso(now = new Date()) {
  return new Date(now.getFullYear(), now.getMonth() + 1, 1).toISOString();
}

module.exports = { DEFAULT_FREE_MONTHLY_LIMIT, getFreeMonthlyLimit, nextMonthStartIso };
