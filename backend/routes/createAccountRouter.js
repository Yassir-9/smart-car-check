const express = require('express');
const { createIdentityVerifier } = require('../middleware/auth');
const { createAccountDeletionService } = require('../services/accountDeletion');
const logger = require('../utils/logger');

function createAccountRouter({
  authClient,
  firestore,
  deletionService,
  limiter = (_req, _res, next) => next(),
}) {
  const router = express.Router();
  const verifyIdentity = createIdentityVerifier(authClient);
  const service = deletionService ||
    createAccountDeletionService({ db: firestore, auth: authClient });

  router.post('/account/delete', verifyIdentity, limiter, async (req, res) => {
    try {
      const result = await service.requestDeletion({ uid: req.uid, authTime: req.authTime });
      return res.json(result);
    } catch (error) {
      logger.error('Account deletion request failed', error, { requestId: req.requestId });
      const statusCode = error.statusCode || 500;
      return res.status(statusCode).json({
        code: error.code || 'ACCOUNT_DELETION_FAILED',
        error: error.code || 'ACCOUNT_DELETION_FAILED',
      });
    }
  });

  return router;
}

module.exports = { createAccountRouter };
