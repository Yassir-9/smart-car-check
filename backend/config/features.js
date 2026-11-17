// Backend feature switches. Everything defaults to OFF; enable explicitly with
// an environment variable ("true"). Read at call time so tests can toggle them.
function flag(name, env = process.env) {
  return String(env[name] || '').trim().toLowerCase() === 'true';
}

const isSubscriptionsEnabled = (env) => flag('SUBSCRIPTIONS_ENABLED', env);
// Public marketplace listing (GET /parts, no login). The live app does not call it
// (the marketplace UI is hidden by FeatureFlags.marketplaceEnabled=false).
const isMarketplaceEnabled = (env) => flag('MARKETPLACE_ENABLED', env);
const isMarketplaceWritesEnabled = (env) => flag('MARKETPLACE_WRITES_ENABLED', env);
// /ask-expert is not used by the current app (only a dead legacy screen calls it).
const isAskExpertEnabled = (env) => flag('ASK_EXPERT_ENABLED', env);
// "Find the part" redirector (/go/*). Off until switched on from Render.
const isPartsGuideEnabled = (env) => flag('PARTS_GUIDE_ENABLED', env);
// AI + web search for stores/prices/links (/parts/external-search, /obd/part-search): can invent results.
const isExternalPartSearchEnabled = (env) => flag('EXTERNAL_PART_SEARCH_ENABLED', env);

// Express middleware: reject the request with 403 + FEATURE_DISABLED when the
// feature is off. `isEnabled` is injectable for tests.
function requireFeature(isEnabled, localizedError) {
  return (req, res, next) => {
    if (isEnabled()) return next();
    return res.status(403).json(localizedError(req, 'FEATURE_DISABLED'));
  };
}

module.exports = {
  isSubscriptionsEnabled,
  isMarketplaceEnabled,
  isMarketplaceWritesEnabled,
  isAskExpertEnabled,
  isPartsGuideEnabled,
  isExternalPartSearchEnabled,
  requireFeature,
};
