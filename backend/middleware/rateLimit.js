const { rateLimit, ipKeyGenerator } = require('express-rate-limit');

function clientKey(req) {
  if (req.uid) return `uid:${req.uid}`;
  return `ip:${ipKeyGenerator(req.ip || req.socket?.remoteAddress || '')}`;
}

function contactUidKey(req) {
  return `contact-uid:${req.uid}`;
}

function contactIpKey(req) {
  return `contact-ip:${ipKeyGenerator(req.ip || req.socket?.remoteAddress || '')}`;
}

function createLimiter({ windowMs, limit, keyGenerator = clientKey }) {
  return rateLimit({
    windowMs,
    limit,
    keyGenerator,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    handler(req, res) {
      res.status(429).json({
        error: 'طلبات كثيرة، حاول مرة أخرى لاحقًا',
        code: 'RATE_LIMITED',
        requestId: req.requestId,
      });
    },
  });
}

const generalApiLimiter = createLimiter({ windowMs: 15 * 60 * 1000, limit: 300 });
const aiLimiter = createLimiter({ windowMs: 15 * 60 * 1000, limit: 20 });
const searchLimiter = createLimiter({ windowMs: 15 * 60 * 1000, limit: 60 });
const marketplaceReadLimiter = createLimiter({ windowMs: 15 * 60 * 1000, limit: 120 });
const marketplaceWriteLimiter = createLimiter({ windowMs: 60 * 60 * 1000, limit: 30 });
const checkoutLimiter = createLimiter({ windowMs: 15 * 60 * 1000, limit: 10 });
const adminLimiter = createLimiter({ windowMs: 15 * 60 * 1000, limit: 10 });
// Applied only after Firebase authentication. Both limits must pass so a single
// account cannot scrape broadly and many accounts cannot bypass one IP budget.
const contactUidDailyLimiter = createLimiter({
  windowMs: 24 * 60 * 60 * 1000,
  limit: 30,
  keyGenerator: contactUidKey,
});
const contactIpDailyLimiter = createLimiter({
  windowMs: 24 * 60 * 60 * 1000,
  limit: 100,
  keyGenerator: contactIpKey,
});

module.exports = {
  clientKey,
  createLimiter,
  generalApiLimiter,
  aiLimiter,
  searchLimiter,
  marketplaceReadLimiter,
  marketplaceWriteLimiter,
  checkoutLimiter,
  adminLimiter,
  contactUidKey,
  contactIpKey,
  contactUidDailyLimiter,
  contactIpDailyLimiter,
};
