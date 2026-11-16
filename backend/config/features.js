// Backend feature switches. Everything defaults to OFF; enable explicitly with
// an environment variable ("true"). Read at call time so tests can toggle them.
function flag(name, env = process.env) {
  return String(env[name] || '').trim().toLowerCase() === 'true';
}

const isSubscriptionsEnabled = (env) => flag('SUBSCRIPTIONS_ENABLED', env);
const isMarketplaceWritesEnabled = (env) => flag('MARKETPLACE_WRITES_ENABLED', env);
// /ask-expert is not used by the current app (only a dead legacy screen calls it).
const isAskExpertEnabled = (env) => flag('ASK_EXPERT_ENABLED', env);

// Express middleware: reject the request with 403 + FEATURE_DISABLED when the
// feature is off. `isEnabled` is injectable for tests.
function requireFeature(isEnabled, localizedError) {
  return (req, res, next) => {
    if (isEnabled()) return next();
    return res.status(403).json(localizedError(req, 'FEATURE_DISABLED'));
  };
}

module.exports = { isSubscriptionsEnabled, isMarketplaceWritesEnabled, isAskExpertEnabled, requireFeature };
