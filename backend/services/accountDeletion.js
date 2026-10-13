const { randomUUID } = require('crypto');

const USER_COLLECTIONS = Object.freeze([
  'cars',
  'history',
  'diagnosis_cache',
  'vehicle_issues',
  'repairs',
  'maintenance_records',
  'maintenance_reminders',
  'repair_reviews',
  'repair_verifications',
  'usage',
]);

const RECENT_AUTH_SECONDS = 5 * 60;
const FINANCIAL_RETENTION_DAYS = 365 * 7;

function assertUid(uid) {
  if (typeof uid !== 'string' || !uid.trim()) {
    throw new Error('A verified user ID is required');
  }
}

function deletionError(code, statusCode, message = code) {
  const error = new Error(message);
  error.code = code;
  error.statusCode = statusCode;
  return error;
}

function isRecentAuthentication(authTime, now = Date.now()) {
  return Number.isFinite(Number(authTime)) &&
    Number(authTime) > 0 &&
    Math.floor(now / 1000) - Number(authTime) <= RECENT_AUTH_SECONDS;
}

function sanitizedFinancialRecord(data = {}, type, deletionRequestId, now) {
  return {
    type,
    deletionRequestId,
    invoiceId: data.invoiceId || null,
    plan: data.plan || null,
    status: data.status || null,
    amount: data.totalAmount || null,
    currency: 'SAR',
    paidAt: data.paidAt || data.paymentVerifiedAt || null,
    retainedAt: now,
    retentionReason: 'financial_and_legal_obligations',
    retentionUntil: new Date(Date.parse(now) + FINANCIAL_RETENTION_DAYS * 86400000).toISOString(),
  };
}

function createAccountDeletionService({ db, auth, now = () => new Date() }) {
  async function setStep(requestRef, step, extra = {}) {
    await requestRef.set({ step, updatedAt: now().toISOString(), ...extra }, { merge: true });
  }

  async function deleteQuery(query) {
    const snapshot = await query.get();
    for (const doc of snapshot.docs) await doc.ref.delete();
    return snapshot.docs.length;
  }

  async function retainSubscription(uid, requestId) {
    const subscriptionRef = db.collection('users').doc(uid).collection('subscription');
    const snapshot = await subscriptionRef.get();
    const timestamp = now().toISOString();
    for (const doc of snapshot.docs) {
      const data = doc.data();
      if (data.invoiceId) {
        await db.collection('retained_financial_records')
          .doc(`${requestId}_subscription_${doc.id}`)
          .set(sanitizedFinancialRecord(
            data,
            'subscription',
            requestId,
            timestamp,
          ), { merge: true });
      }
    }
    await db.recursiveDelete(subscriptionRef);
  }

  async function anonymizeOrders(uid, requestId) {
    const snapshot = await db.collection('orders').get();
    const timestamp = now().toISOString();
    for (const doc of snapshot.docs) {
      const order = doc.data();
      const buyerDeleted = order.buyerId === uid;
      let sellerDeleted = false;
      const items = Array.isArray(order.items) ? order.items.map((item) => {
        if (item.sellerId !== uid) return item;
        sellerDeleted = true;
        const { sellerId, sellerPhone, ...retained } = item;
        return { ...retained, sellerDeleted: true };
      }) : [];
      if (!buyerDeleted && !sellerDeleted) continue;
      if (order.status === 'paid' || order.invoiceId) {
        await db.collection('retained_financial_records')
          .doc(`${requestId}_order_${doc.id}`)
          .set(sanitizedFinancialRecord(
            order,
            'marketplace_order',
            requestId,
            timestamp,
          ), { merge: true });
      }
      const update = { items, privacyUpdatedAt: timestamp };
      if (buyerDeleted) {
        update.buyerId = null;
        update.buyerDeleted = true;
      }
      await doc.ref.update(update);
    }
  }

  async function deleteUserPrivateData(uid, requestId = `deletion-${uid}`) {
    assertUid(uid);

    // Remove the user's public listings and their contact details.
    // Never touch listings belonging to another account.
    const listings = await db.collection('parts').where('ownerId', '==', uid).get();
    for (const listing of listings.docs) {
      await listing.ref.delete();
    }

    const userRef = db.collection('users').doc(uid);

    await deleteQuery(db.collection('seller_ratings').where('raterId', '==', uid));
    await deleteQuery(db.collection('seller_ratings').where('sellerId', '==', uid));
    await anonymizeOrders(uid, requestId);
    await retainSubscription(uid, requestId);

    for (const name of USER_COLLECTIONS) {
      const collectionRef = userRef.collection(name);
      await db.recursiveDelete(collectionRef);
    }

    // Keep only a short-lived, non-profile security tombstone. Firestore ID
    // tokens can remain valid briefly after Auth deletion; removing this
    // marker immediately would let a stale token recreate private data.
    const clearedAt = now().toISOString();
    await userRef.set({
      deletionPending: true,
      personalDataClearedAt: clearedAt,
      // Firestore TTL policies require a timestamp value, not an ISO string.
      // The production TTL policy is configured on users.expireAt.
      expireAt: new Date(Date.parse(clearedAt) + 24 * 60 * 60 * 1000),
    });
  }

  async function requestDeletion({ uid, authTime }) {
    assertUid(uid);
    if (!isRecentAuthentication(authTime, now().getTime())) {
      throw deletionError('RECENT_AUTHENTICATION_REQUIRED', 401);
    }
    const requestRef = db.collection('account_deletion_requests').doc(uid);
    const userRef = db.collection('users').doc(uid);
    const existing = await requestRef.get();
    const requestId = existing.exists && existing.data()?.requestId
      ? existing.data().requestId
      : `adr-${randomUUID()}`;

    await requestRef.set({
      requestId,
      uid,
      status: 'processing',
      requestedAt: existing.exists ? existing.data()?.requestedAt : now().toISOString(),
      updatedAt: now().toISOString(),
    }, { merge: true });
    await userRef.set({ deletionPending: true, deletionRequestedAt: now().toISOString() }, { merge: true });

    try {
      await setStep(requestRef, 'deleting_data');
      await deleteUserPrivateData(uid, requestId);
      await setStep(requestRef, 'deleting_auth');
      // Remove the resumability record before the irreversible Auth deletion.
      // If Auth deletion fails, the catch block recreates the retry record.
      await requestRef.delete();
      await auth.deleteUser(uid);
      return { status: 'completed' };
    } catch (error) {
      await requestRef.set({
        status: 'retry_required',
        lastErrorCode: error.code || 'ACCOUNT_DELETION_FAILED',
        updatedAt: now().toISOString(),
      }, { merge: true });
      throw deletionError('ACCOUNT_DELETION_RETRY_REQUIRED', 503);
    }
  }

  return { deleteUserPrivateData, requestDeletion };
}

module.exports = {
  createAccountDeletionService,
  USER_COLLECTIONS,
  RECENT_AUTH_SECONDS,
  FINANCIAL_RETENTION_DAYS,
  isRecentAuthentication,
};
