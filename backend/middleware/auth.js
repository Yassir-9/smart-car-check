function createIdentityVerifier(authClient) {
  return async function verifyToken(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'يلزم تسجيل الدخول' });
    }
    const idToken = authHeader.slice('Bearer '.length).trim();
    if (!idToken) return res.status(401).json({ error: 'يلزم تسجيل الدخول' });
    try {
      // Revocation checking also rejects tokens for a Firebase Auth user that
      // has been deleted, instead of accepting the token until its expiry.
      const decoded = await authClient.verifyIdToken(idToken, true);
      req.uid = decoded.uid;
      req.authTime = Number(decoded.auth_time || 0);
      return next();
    } catch (_) {
      return res.status(401).json({ error: 'جلسة غير صالحة، سجّل دخول من جديد' });
    }
  };
}

function createVerifyToken(authClient, accountDb = null) {
  const verifyIdentity = createIdentityVerifier(authClient);
  return async function verifyActiveAccount(req, res, next) {
    return verifyIdentity(req, res, async () => {
      if (!accountDb) return next();
      try {
        const user = await accountDb.collection('users').doc(req.uid).get();
        if (user.exists && user.data()?.deletionPending === true) {
          return res.status(403).json({
            code: 'ACCOUNT_DELETION_PENDING',
            error: 'ACCOUNT_DELETION_PENDING',
          });
        }
        return next();
      } catch (_) {
        return res.status(503).json({
          code: 'ACCOUNT_STATUS_UNAVAILABLE',
          error: 'ACCOUNT_STATUS_UNAVAILABLE',
        });
      }
    });
  };
}

async function verifyToken(req, res, next) {
  const { auth, db } = require('../firebaseAdmin');
  return createVerifyToken(auth, db)(req, res, next);
}
module.exports = verifyToken;
module.exports.createVerifyToken = createVerifyToken;
module.exports.createIdentityVerifier = createIdentityVerifier;
