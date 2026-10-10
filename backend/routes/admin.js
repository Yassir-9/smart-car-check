const express = require('express');
const router = express.Router();
const { auth, db } = require('../firebaseAdmin');
const logger = require('../utils/logger');
const { adminLimiter } = require('../middleware/rateLimit');
const { requireAdminSecret } = require('../middleware/adminAuth');

router.get('/admin/stats', adminLimiter, requireAdminSecret, async (req, res) => {
  try {
    let usersCount = null;
    try {
      const list = await auth.listUsers(1000);
      usersCount = list.users.length;
    } catch (e) {
      usersCount = null;
    }

    const partsSnap = await db.collection('parts').count().get();
    const partsCount = partsSnap.data().count;

    const diagnosesSnap = await db.collectionGroup('history').count().get();
    const diagnosesCount = diagnosesSnap.data().count;

    let accurateCount = 0;
    let inaccurateCount = 0;
    try {
      const accSnap = await db
        .collectionGroup('history')
        .where('feedback.accurate', '==', true)
        .count()
        .get();
      accurateCount = accSnap.data().count;

      const inaccSnap = await db
        .collectionGroup('history')
        .where('feedback.accurate', '==', false)
        .count()
        .get();
      inaccurateCount = inaccSnap.data().count;
    } catch (e) {
      logger.warn('Feedback statistics query failed; Firestore index may be missing', { error: e });
    }

    const ordersSnap = await db.collection('orders').get();
    const ordersCount = ordersSnap.size;
    let paidOrdersCount = 0;
    let totalRevenue = 0;
    ordersSnap.forEach((doc) => {
      const order = doc.data();
      if (order.status === 'paid') {
        paidOrdersCount += 1;
        totalRevenue += order.totalAmount || 0;
      }
    });

    const ratingsSnap = await db.collection('seller_ratings').count().get();
    const ratingsCount = ratingsSnap.data().count;

    res.json({
      usersCount,
      partsCount,
      diagnosesCount,
      feedback: {
        rated: accurateCount + inaccurateCount,
        accurate: accurateCount,
        inaccurate: inaccurateCount,
      },
      marketplace: {
        ordersCount,
        paidOrdersCount,
        totalRevenue,
        ratingsCount,
      },
    });
  } catch (error) {
    logger.error('Admin statistics request failed', error, { requestId: req.requestId });
    res.status(500).json({ error: 'حدث خطأ أثناء جلب الإحصائيات' });
  }
});

module.exports = router;
