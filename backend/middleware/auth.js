function createVerifyToken(authClient) {
  return async function verifyToken(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'يلزم تسجيل الدخول' });
    }
    const idToken = authHeader.slice('Bearer '.length).trim();
    if (!idToken) return res.status(401).json({ error: 'يلزم تسجيل الدخول' });
    try {
      const decoded = await authClient.verifyIdToken(idToken);
      req.uid = decoded.uid;
      return next();
    } catch (_) {
      return res.status(401).json({ error: 'جلسة غير صالحة، سجّل دخول من جديد' });
    }
  };
}

async function verifyToken(req, res, next) {
  const { auth } = require('../firebaseAdmin');
  return createVerifyToken(auth)(req, res, next);
}
module.exports = verifyToken;
module.exports.createVerifyToken = createVerifyToken;
