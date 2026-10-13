const { auth, db } = require('../firebaseAdmin');
const { accountDeletionLimiter } = require('../middleware/rateLimit');
const { createAccountRouter } = require('./createAccountRouter');

module.exports = createAccountRouter({ authClient: auth, firestore: db, limiter: accountDeletionLimiter });
