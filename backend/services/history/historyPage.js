// Paged read of users/{uid}/history (newest first). The response stays a plain
// array so already-published app versions keep working; they simply receive the
// latest page instead of the whole history.
const DEFAULT_HISTORY_LIMIT = 50;
const MAX_HISTORY_LIMIT = 100;

function parseHistoryQuery(query = {}) {
  const raw = Number.parseInt(String(query.limit ?? ''), 10);
  const limit = Number.isInteger(raw) && raw > 0
    ? Math.min(raw, MAX_HISTORY_LIMIT)
    : DEFAULT_HISTORY_LIMIT;
  const before = typeof query.before === 'string' && !Number.isNaN(Date.parse(query.before))
    ? query.before
    : null;
  return { limit, before };
}

async function readHistoryPage(db, uid, { limit, before }) {
  let ref = db.collection('users').doc(uid).collection('history').orderBy('timestamp', 'desc');
  if (before) ref = ref.startAfter(before);
  const snapshot = await ref.limit(limit).get();
  return snapshot.docs.map((doc) => doc.data());
}

module.exports = { DEFAULT_HISTORY_LIMIT, MAX_HISTORY_LIMIT, parseHistoryQuery, readHistoryPage };
