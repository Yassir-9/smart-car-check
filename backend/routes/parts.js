const { db } = require('../firebaseAdmin');
const verifyToken = require('../middleware/auth');
const {
  marketplaceReadLimiter,
  marketplaceWriteLimiter,
  contactUidDailyLimiter,
  contactIpDailyLimiter,
} = require('../middleware/rateLimit');
const { localizedError } = require('../utils/localizedResponse');
const logger = require('../utils/logger');
const { createPartsRouter } = require('./createPartsRouter');

module.exports = createPartsRouter({
  db,
  verifyToken,
  marketplaceReadLimiter,
  marketplaceWriteLimiter,
  contactUidDailyLimiter,
  contactIpDailyLimiter,
  localizedError,
  logger,
  exposePublicContact: false,
});
