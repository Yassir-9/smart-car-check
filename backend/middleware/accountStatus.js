function createAccountStatusGuard(db) {
  return async function accountStatusGuard(req, res, next) {
    if (!req.uid) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    try {
      const snapshot = await db.collection('users').doc(req.uid).get();

      if (snapshot.exists && snapshot.data()?.deletionPending === true) {
        return res.status(403).json({
          error: 'ACCOUNT_DELETION_PENDING',
        });
      }

      return next();
    } catch (_) {
      return res.status(503).json({
        error: 'ACCOUNT_STATUS_UNAVAILABLE',
      });
    }
  };
}

module.exports = { createAccountStatusGuard };
