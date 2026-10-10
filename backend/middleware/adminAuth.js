const { timingSafeEqual } = require('crypto');

function requireAdminSecret(req, res, next) {
  const supplied = req.get('x-admin-secret');
  const expected = process.env.ADMIN_SECRET;
  if (!expected) {
    return res.status(503).send('إعداد الإدارة غير متوفر');
  }
  const valid = supplied && supplied.length === expected.length &&
    timingSafeEqual(Buffer.from(supplied), Buffer.from(expected));
  if (!valid) {
    return res.status(401).send('غير مصرح لك بالدخول');
  }
  return next();
}

module.exports = { requireAdminSecret };
