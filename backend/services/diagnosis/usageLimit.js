function isDevelopmentUsageLimitBypassEnabled(env = process.env) {
  const nodeEnvironment = String(env.NODE_ENV || '').trim().toLowerCase();
  const bypassRequested =
    String(env.DEV_BYPASS_USAGE_LIMIT || '').trim().toLowerCase() === 'true';
  return nodeEnvironment !== 'production' && bypassRequested;
}

function isQaUsageLimitBypassEnabled(uid, env = process.env) {
  if (!uid) return false;
  const isProduction = String(env.NODE_ENV || '').trim().toLowerCase() === 'production';
  if (String(env.QA_USAGE_LIMIT_ENABLED || '').trim().toLowerCase() !== 'true') return false;
  if (isProduction && String(env.QA_USAGE_LIMIT_ALLOW_PRODUCTION || '').trim().toLowerCase() !== 'true') return false;
  const allowedUids = String(env.QA_USAGE_LIMIT_UIDS || '')
    .split(',').map((value) => value.trim()).filter(Boolean);
  if (!allowedUids.includes(String(uid))) return false;
  const expiresAt = String(env.QA_USAGE_LIMIT_EXPIRES_AT || '').trim();
  if (expiresAt) {
    const expiry = Date.parse(expiresAt);
    if (!Number.isFinite(expiry) || Date.now() >= expiry) return false;
  }
  return true;
}

module.exports = { isDevelopmentUsageLimitBypassEnabled, isQaUsageLimitBypassEnabled };
