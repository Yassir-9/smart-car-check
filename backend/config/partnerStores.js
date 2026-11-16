// Allow-list of stores the "find the part" button may send people to.
//
// The app NEVER sends a URL. It sends a store key plus a few plain text fields and
// the server builds the destination from the templates below, so there is no open
// redirect. Adding a store means adding an entry here (code review), nothing else.
//
// Affiliate IDs come from environment variables (set them in Render, no deploy):
//   AFFILIATE_SPEERO, AFFILIATE_ODIGGO, AFFILIATE_NOON, AFFILIATE_AMAZON
// Each value is the exact query-string fragment the partner programme gives you,
// e.g. "ref=abc123" or "tag=smartcar-21". Empty/invalid = plain link, no affiliate.
// The "marketing link" disclosure is shown in the app regardless.
//
// PARTNER_STORES_ENABLED (comma separated keys) overrides which stores are on.

const STORES = Object.freeze({
  speero: {
    name: 'SPEERO / سبيرو',
    host: 'speero.net',
    // Verified in a browser on 2026-11-17: searching on speero.net opens
    // https://speero.net/search?q=<text>
    searchUrl: (q) => `https://speero.net/search?q=${encodeURIComponent(q)}`,
    // Speero's search matches the part name only: adding make/model/year made the
    // results irrelevant (e.g. a tow hook for "Toyota Land Cruiser 2019 spark plugs").
    queryFields: ['part'],
    affiliateEnv: 'AFFILIATE_SPEERO',
    enabledByDefault: true,
  },
  web: {
    name: 'Google (مواقع المتاجر الشريكة)',
    // General web search restricted to the enabled partner sites (site: filter).
    searchUrl: (q, ctx) => {
      const sites = ctx.siteHosts.map((h) => `site:${h}`).join(' OR ');
      const text = sites ? `${q} (${sites})` : q;
      return `https://www.google.com/search?q=${encodeURIComponent(text)}`;
    },
    affiliateEnv: null,
    enabledByDefault: true,
  },
  // Ready but OFF. Only the domain is known: no search pattern has been verified, so
  // enabling one of these opens the store home page without any query.
  odiggo: { name: 'Odiggo', host: 'odiggo.com', searchUrl: null, affiliateEnv: 'AFFILIATE_ODIGGO', enabledByDefault: false },
  noon: { name: 'Noon', host: 'www.noon.com', searchUrl: null, affiliateEnv: 'AFFILIATE_NOON', enabledByDefault: false },
  amazon: { name: 'Amazon.sa', host: 'www.amazon.sa', searchUrl: null, affiliateEnv: 'AFFILIATE_AMAZON', enabledByDefault: false },
});

function enabledStoreKeys(env = process.env) {
  const configured = String(env.PARTNER_STORES_ENABLED || '')
    .split(',').map((s) => s.trim().toLowerCase()).filter(Boolean);
  if (configured.length) return configured.filter((key) => Object.hasOwn(STORES, key));
  return Object.keys(STORES).filter((key) => STORES[key].enabledByDefault);
}

module.exports = { STORES, enabledStoreKeys };
