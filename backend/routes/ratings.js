const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/auth');
const { db } = require('../firebaseAdmin');
const logger = require('../utils/logger');
const { localizedError } = require('../utils/localizedResponse');

// جلب متوسط تقييم بائع معيّن
router.get('/sellers/:id/rating', async (req, res) => {
  try {
    const snapshot = await db.collection('seller_ratings')
      .where('sellerId', '==', req.params.id).get();

    if (snapshot.empty) {
      return res.json({ average: null, count: 0 });
    }

    let sum = 0;
    snapshot.docs.forEach((doc) => {
      sum += doc.data().rating || 0;
    });
    const average = sum / snapshot.docs.length;

    res.json({
      average: Math.round(average * 10) / 10,
      count: snapshot.docs.length,
    });
  } catch (error) {
    logger.error('Failed to load seller rating', error, { requestId: req.requestId });
    res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
  }
});

// إضافة أو تحديث تقييم بائع
router.post('/sellers/:id/rating', verifyToken, async (req, res) => {
  try {
    const sellerId = req.params.id;
    const { rating, comment } = req.body;

    if (sellerId === req.uid) {
      return res.status(400).json(localizedError(req, 'SELF_RATING'));
    }
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json(localizedError(req, 'INVALID_RATING'));
    }

    const docId = `${sellerId}_${req.uid}`;
    await db.collection('seller_ratings').doc(docId).set({
      sellerId,
      raterId: req.uid,
      rating,
      comment: comment || '',
      createdAt: new Date().toISOString(),
    });

    res.json({ success: true });
  } catch (error) {
    logger.error('Failed to save seller rating', error, { requestId: req.requestId });
    res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
  }
});

// جلب تقييمي الشخصي لبائع معيّن
router.get('/sellers/:id/rating/mine', verifyToken, async (req, res) => {
  try {
    const docId = `${req.params.id}_${req.uid}`;
    const doc = await db.collection('seller_ratings').doc(docId).get();
    if (!doc.exists) {
      return res.json({ rating: null, comment: null });
    }
    const data = doc.data();
    res.json({ rating: data.rating, comment: data.comment });
  } catch (error) {
    logger.error('Failed to load personal seller rating', error, { requestId: req.requestId });
    res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
  }
});

module.exports = router;
