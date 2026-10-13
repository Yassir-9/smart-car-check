const test = require('node:test');
const assert = require('node:assert/strict');
const {
  createAccountDeletionService,
  USER_COLLECTIONS,
  isRecentAuthentication,
} = require('../services/accountDeletion');

function fakeDb({ failAt = null } = {}) {
  const events = [];
  const requestData = {};
  let securityTombstone = null;
  const documents = {
    parts: [
      { id: 'owned', data: { ownerId: 'user-123', sellerPhone: '0500000000' } },
      { id: 'other', data: { ownerId: 'other-user', sellerPhone: '0511111111' } },
    ],
    seller_ratings: [
      { id: 'rated-by-user', data: { raterId: 'user-123', sellerId: 'other-user' } },
      { id: 'rates-user', data: { raterId: 'other-user', sellerId: 'user-123' } },
      { id: 'unrelated', data: { raterId: 'other-user', sellerId: 'third-user' } },
    ],
    orders: [
      { id: 'buyer-order', data: { buyerId: 'user-123', status: 'paid', invoiceId: 'inv-1', totalAmount: 100, items: [{ sellerId: 'other-user', sellerPhone: '0511111111', partName: 'Part' }] } },
      { id: 'seller-order', data: { buyerId: 'other-user', status: 'paid', invoiceId: 'inv-2', totalAmount: 200, items: [{ sellerId: 'user-123', sellerPhone: '0500000000', partName: 'Part 2' }] } },
    ],
  };

  function document(collection, item) {
    return {
      id: item.id,
      data: () => item.data,
      ref: {
        async delete() {
          if (failAt === `${collection}:delete`) throw new Error('Firestore unavailable');
          events.push(`delete:${collection}/${item.id}`);
        },
        async update(value) {
          events.push(`update:${collection}/${item.id}`);
          item.data = { ...item.data, ...value };
        },
      },
    };
  }

  function query(collection, field, value) {
    return { async get() { return { docs: documents[collection].filter((item) => item.data[field] === value).map((item) => document(collection, item)) }; } };
  }

  const db = {
    collection(name) {
      if (name === 'parts' || name === 'seller_ratings') {
        return { where(field, operator, value) { assert.equal(operator, '=='); assert.equal(value, 'user-123'); return query(name, field, value); } };
      }
      if (name === 'orders') return { async get() { return { docs: documents.orders.map((item) => document('orders', item)) }; } };
      if (name === 'retained_financial_records') {
        return {
          doc(id) {
            return {
              async set() { events.push(`retain:financial/${id}`); },
            };
          },
        };
      }
      if (name === 'account_deletion_requests') {
        return { doc(uid) {
          assert.equal(uid, 'user-123');
          return {
            async get() { return { exists: !!requestData.requestId, data: () => requestData }; },
            async set(value) { Object.assign(requestData, value); events.push(`request:${value.step || value.status}`); },
            async delete() { events.push('delete:request'); },
          };
        } };
      }
      assert.equal(name, 'users');
      return { doc(uid) {
        assert.equal(uid, 'user-123');
        return {
          async get() { return { exists: true, data: () => ({ deletionPending: false }) }; },
          async set(value, options) {
            if (options?.merge !== true) securityTombstone = value;
            events.push(options?.merge === true
              ? `user:pending:${value.deletionPending}`
              : 'user:security-tombstone');
          },
          collection(collectionName) {
            return {
              path: `users/${uid}/${collectionName}`,
              async get() {
                if (collectionName !== 'subscription') return { docs: [] };
                return {
                  docs: [{
                    id: 'current',
                    data: () => ({
                      invoiceId: 'sub-inv',
                      plan: 'monthly',
                      status: 'active',
                    }),
                  }],
                };
              },
            };
          },
        };
      } };
    },
    async recursiveDelete(ref) {
      if (failAt === 'recursiveDelete') throw new Error('Firestore unavailable');
      events.push(`recursive:${ref.path}`);
    },
  };
  return { db, events, documents, getSecurityTombstone: () => securityTombstone };
}

test('deletes only the verified user data and anonymizes shared records', async () => {
  const { db, events, documents, getSecurityTombstone } = fakeDb();
  await createAccountDeletionService({ db, auth: {} }).deleteUserPrivateData('user-123', 'request-1');
  assert.ok(events.includes('delete:parts/owned'));
  assert.ok(!events.includes('delete:parts/other'));
  assert.ok(events.includes('delete:seller_ratings/rated-by-user'));
  assert.ok(events.includes('delete:seller_ratings/rates-user'));
  assert.ok(!events.includes('delete:seller_ratings/unrelated'));
  assert.equal(documents.orders[0].data.buyerId, null);
  assert.equal(documents.orders[1].data.items[0].sellerId, undefined);
  assert.equal(documents.orders[1].data.items[0].sellerPhone, undefined);
  assert.ok(USER_COLLECTIONS.every((name) => events.includes(`recursive:users/user-123/${name}`)));
  assert.ok(events.includes('recursive:users/user-123/subscription'));
  assert.ok(events.includes('user:security-tombstone'));
  const tombstone = getSecurityTombstone();
  assert.equal(tombstone.deletionPending, true);
  assert.ok(tombstone.expireAt instanceof Date);
  assert.equal(tombstone.expireAt.getTime() - Date.parse(tombstone.personalDataClearedAt), 86400000);
});

test('stops safely and can be retried after Firestore failure', async () => {
  const { db, events } = fakeDb({ failAt: 'recursiveDelete' });
  const auth = { async deleteUser() { events.push('auth:delete'); } };
  await assert.rejects(
    createAccountDeletionService({ db, auth }).requestDeletion({ uid: 'user-123', authTime: Math.floor(Date.now() / 1000) }),
    (error) => error.code === 'ACCOUNT_DELETION_RETRY_REQUIRED',
  );
  assert.ok(events.includes('request:retry_required'));
  assert.ok(!events.includes('auth:delete'));
});

test('requires recent authentication before marking deletion pending', async () => {
  const { db, events } = fakeDb();
  await assert.rejects(
    createAccountDeletionService({ db, auth: {} }).requestDeletion({ uid: 'user-123', authTime: 1 }),
    (error) => error.code === 'RECENT_AUTHENTICATION_REQUIRED' && error.statusCode === 401,
  );
  assert.deepEqual(events, []);
});

test('successful deletion removes Firebase Auth last', async () => {
  const { db, events } = fakeDb();
  const auth = { async deleteUser(uid) { assert.equal(uid, 'user-123'); events.push('auth:delete'); } };
  const result = await createAccountDeletionService({ db, auth }).requestDeletion({ uid: 'user-123', authTime: Math.floor(Date.now() / 1000) });
  assert.deepEqual(result, { status: 'completed' });
  assert.ok(events.indexOf('auth:delete') > events.indexOf('user:security-tombstone'));
  assert.ok(events.indexOf('delete:request') < events.indexOf('auth:delete'));
});

test('recent authentication window is five minutes', () => {
  const now = Date.parse('2026-10-13T12:00:00Z');
  assert.equal(isRecentAuthentication(Math.floor(now / 1000) - 299, now), true);
  assert.equal(isRecentAuthentication(Math.floor(now / 1000) - 301, now), false);
});

test('rejects an empty user ID', async () => {
  await assert.rejects(createAccountDeletionService({ db: {}, auth: {} }).deleteUserPrivateData(''), /verified user ID/);
});
