const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { createAccountDeletionService } = require('../services/accountDeletion');

async function main() {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Firestore emulator is required');
  assert.ok(process.env.FIREBASE_AUTH_EMULATOR_HOST, 'Auth emulator is required');

  const projectId = process.env.GCLOUD_PROJECT || 'demo-smart-car-check';
  const app = initializeApp({ projectId }, `privacy-delete-${randomUUID()}`);
  const db = getFirestore(app);
  const auth = getAuth(app);
  const uid = `privacy-test-${randomUUID()}`;

  try {
    await auth.createUser({ uid, email: `${uid}@example.test`, emailVerified: true });
    await db.collection('users').doc(uid).set({ displayName: 'Disposable test account' });
    await db.collection('users').doc(uid).collection('cars').doc('car-1').set({ make: 'Test' });
    await db.collection('parts').doc('part-1').set({ ownerId: uid, sellerPhone: '0500000000' });

    const result = await createAccountDeletionService({ db, auth }).requestDeletion({
      uid,
      authTime: Math.floor(Date.now() / 1000),
    });
    assert.deepEqual(result, { status: 'completed' });
    await assert.rejects(auth.getUser(uid), (error) => error.code === 'auth/user-not-found');

    const user = await db.collection('users').doc(uid).get();
    assert.equal(user.data()?.deletionPending, true);
    assert.ok(user.data()?.expireAt?.toDate() instanceof Date);
    assert.equal((await db.collection('users').doc(uid).collection('cars').get()).empty, true);
    assert.equal((await db.collection('parts').where('ownerId', '==', uid).get()).empty, true);
    console.log('EMULATOR ACCOUNT DELETION PASS');
  } finally {
    await deleteApp(app);
  }
}

main().catch((error) => {
  console.error(error?.stack || error);
  process.exitCode = 1;
});
