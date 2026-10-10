const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
  throw new Error(
    'FIREBASE_SERVICE_ACCOUNT is required. Provide service-account JSON through the environment only.'
  );
}

let serviceAccount;
try {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
} catch (_) {
  throw new Error('FIREBASE_SERVICE_ACCOUNT must contain valid JSON.');
}

const app = initializeApp({
  credential: cert(serviceAccount),
});

const auth = getAuth(app);
const db = getFirestore(app);

module.exports = { auth, db };
