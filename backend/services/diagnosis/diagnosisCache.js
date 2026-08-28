const { createHash } = require('crypto');
const logger = require('../../utils/logger');

const CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000;

function normalizeText(value) {
  return String(value || '').trim().toLowerCase().replace(/\s+/g, ' ');
}

function imageFingerprint(image) {
  return image?.data ? createHash('sha256').update(image.data).digest('hex') : null;
}

function createCacheKey({ uid, car, description, obdCodes, image }) {
  const payload = JSON.stringify({
    uid,
    car: { brand: normalizeText(car?.brand), model: normalizeText(car?.model), year: car?.year || null },
    symptoms: normalizeText(description),
    obdCodes: [...obdCodes].sort(),
    image: imageFingerprint(image),
  });
  return createHash('sha256').update(payload).digest('hex');
}

async function getCachedDiagnosis(db, uid, key, now = Date.now()) {
  try {
    const doc = await db.collection('users').doc(uid).collection('diagnosis_cache').doc(key).get();
    if (!doc.exists) return null;
    const data = doc.data();
    if (!data.createdAt || now - new Date(data.createdAt).getTime() > CACHE_TTL_MS) return null;
    return data.result || null;
  } catch (error) {
    logger.warn('Diagnosis cache read failed', { error });
    return null;
  }
}

async function setCachedDiagnosis(db, uid, key, result) {
  try {
    await db.collection('users').doc(uid).collection('diagnosis_cache').doc(key).set({
      result,
      createdAt: new Date().toISOString(),
    });
  } catch (error) {
    logger.warn('Diagnosis cache write failed', { error });
  }
}

module.exports = { createCacheKey, getCachedDiagnosis, setCachedDiagnosis, imageFingerprint, CACHE_TTL_MS };
