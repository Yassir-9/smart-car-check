const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/auth');
const { db } = require('../firebaseAdmin');

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
    console.error('خطأ بجلب التقييم:', error);
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
  }
});

// إضافة أو تحديث تقييم بائع
router.post('/sellers/:id/rating', verifyToken, async (req, res) => {
  try {
    const sellerId = req.params.id;
    const { rating, comment } = req.body;

    if (sellerId === req.uid) {
      return res.status(400).json({ error: 'لا يمكنك تقييم نفسك' });
    }
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ error: 'التقييم يجب أن يكون بين 1 و5' });
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
    console.error('خطأ بتسجيل التقييم:', error);
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
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
    console.error('خطأ بجلب تقييمك:', error);
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
  }
});

module.exports = router;
