const express = require('express');
const { isPartsGuideEnabled } = require('../config/features');
const { partsGuideLimiter } = require('../middleware/rateLimit');
const { parseGuideQuery, buildDestination, listEnabledStores } = require('../services/partsGuide/storeRedirect');

// "Find the part" redirector. Public on purpose (the app opens it in the browser, so no
// Authorization header) and it never reads or logs a user identity: only the plain text
// fields part/make/model/year are used, and the destination host comes from an allow-list.
function createGoRouter({ limiter = partsGuideLimiter, env = process.env } = {}) {
  const router = express.Router();

  // Off by default (PARTS_GUIDE_ENABLED=true to enable). The app falls back to a general
  // search when this answers 404.
  router.use((req, res, next) => {
    if (!isPartsGuideEnabled(env)) return res.status(404).json({ code: 'NOT_FOUND' });
    return next();
  });
  router.use(limiter);

  router.get('/stores', (req, res) => {
    res.set('Cache-Control', 'no-store');
    res.json({ stores: listEnabledStores(env) });
  });

  router.get('/:store', (req, res) => {
    const parsed = parseGuideQuery(req.query);
    if (!parsed.ok) return res.status(400).json({ code: parsed.code });
    const destination = buildDestination(req.params.store, parsed.q, env);
    if (!destination.ok) return res.status(404).json({ code: destination.code });
    res.set({ 'Cache-Control': 'no-store', 'Referrer-Policy': 'no-referrer' });
    return res.redirect(302, destination.url);
  });

  return router;
}

module.exports = createGoRouter();
module.exports.createGoRouter = createGoRouter;
