// Atomic per-month usage counters in users/{uid}/usage/{YYYY-MM}.
//
// The limit check and the increment happen in ONE Firestore transaction
// (reserveUsage), so parallel requests can never push a counter above its limit.
// A request that later fails gives its slot back with releaseUsage, so failed
// attempts are not counted (same behaviour as before: only successes count).
const DIAGNOSIS_FIELD = 'diagnosisCount';
const REPAIR_REVIEW_FIELD = 'repairReviewCount';

function monthKey(now = new Date()) {
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
}

function usageRef(db, uid, key) {
  return db.collection('users').doc(uid).collection('usage').doc(key);
}

// Returns { allowed, count, field, ref }. When allowed, the counter has already
// been incremented and the caller owns a reservation it must release on failure.
async function reserveUsage(db, uid, field, limit, now = new Date()) {
  const ref = usageRef(db, uid, monthKey(now));
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const current = snap.exists ? Number(snap.data()[field]) || 0 : 0;
    if (current >= limit) return { allowed: false, count: current, field, ref };
    tx.set(ref, { [field]: current + 1 }, { merge: true });
    return { allowed: true, count: current + 1, field, ref };
  });
}

// Gives a reserved slot back (never goes below zero). Never throws: a failed
// refund is logged by the caller and only costs the user one count.
async function releaseUsage(db, reservation) {
  if (!reservation || !reservation.allowed || !reservation.ref) return false;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(reservation.ref);
    const current = snap.exists ? Number(snap.data()[reservation.field]) || 0 : 0;
    if (current > 0) tx.set(reservation.ref, { [reservation.field]: current - 1 }, { merge: true });
  });
  return true;
}

module.exports = { DIAGNOSIS_FIELD, REPAIR_REVIEW_FIELD, monthKey, reserveUsage, releaseUsage };
