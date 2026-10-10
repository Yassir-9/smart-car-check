const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/auth');
const { db } = require('../firebaseAdmin');
const { toBuyerOrder, toSellerOrder } = require('../services/marketplace/partPrivacy');
const { MOYASAR_BASE, authHeader, fetchVerifiedInvoice } = require('../utils/moyasar');
const logger = require('../utils/logger');
const { checkoutLimiter } = require('../middleware/rateLimit');
const { localizedError, localizedPaymentSuccess, requestLocale } = require('../utils/localizedResponse');

const BACKEND_URL = 'https://car-ai-backend-7gpb.onrender.com';

// إنشاء طلب شراء والانتقال لبوابة الدفع
router.post('/orders/checkout', verifyToken, checkoutLimiter, async (req, res) => {
  try {
    const locale = requestLocale(req);
    const { partIds } = req.body;
    if (!Array.isArray(partIds) || partIds.length === 0) {
      return res.status(400).json(localizedError(req, 'EMPTY_CART'));
    }

    const items = [];
    let totalAmount = 0;

    for (const partId of partIds) {
      const doc = await db.collection('parts').doc(partId).get();
      if (!doc.exists) continue;
      const part = doc.data();
      if (part.ownerId === req.uid) {
        return res.status(400).json(localizedError(req, 'OWN_PART_PURCHASE'));
      }
      const price = parseFloat(part.price);
      if (!price || isNaN(price)) continue;
      items.push({
        partId,
        partName: part.partName,
        price,
        sellerId: part.ownerId || null,
        sellerPhone: part.sellerPhone,
      });
      totalAmount += price;
    }

    if (items.length === 0) {
      return res.status(400).json(localizedError(req, 'NO_VALID_PARTS'));
    }

    const orderRef = await db.collection('orders').add({
      buyerId: req.uid,
      items,
      totalAmount,
      status: 'pending',
      createdAt: new Date().toISOString(),
    });

    const response = await fetch(`${MOYASAR_BASE}/invoices`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: authHeader(),
      },
      body: JSON.stringify({
        amount: Math.round(totalAmount * 100),
        currency: 'SAR',
        description: locale === 'en'
          ? `Spare parts order - ${items.length} item(s)`
          : `طلب شراء قطع غيار - ${items.length} قطعة`,
        callback_url: `${BACKEND_URL}/api/orders/webhook`,
        success_url: `${BACKEND_URL}/api/orders/success?locale=${locale}`,
        metadata: {
          orderId: orderRef.id,
        },
      }),
    });

    const data = await response.json();
    if (!response.ok) {
      logger.warn('Moyasar rejected order invoice creation', { statusCode: response.status });
      return res.status(500).json(localizedError(req, 'PAYMENT_CREATION_FAILED'));
    }

    await orderRef.update({ invoiceId: data.id });

    res.json({ checkoutUrl: data.url, orderId: orderRef.id });
  } catch (error) {
    logger.error('Order checkout creation failed', error, { requestId: req.requestId });
    res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
  }
});

// ويب هوك تأكيد الدفع
router.post('/orders/webhook', async (req, res) => {
  try {
    const notifiedInvoiceId = req.body?.id;
    const invoice = await fetchVerifiedInvoice(notifiedInvoiceId);
    if (!invoice || invoice.status !== 'paid' || invoice.currency !== 'SAR') {
      logger.warn('Rejected unverified order payment notification', { invoiceId: notifiedInvoiceId });
      return res.status(202).json({ received: true, verified: false });
    }

    const orderId = invoice.metadata?.orderId;
    if (!orderId) return res.status(202).json({ received: true, verified: false });
    const orderRef = db.collection('orders').doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) return res.status(202).json({ received: true, verified: false });
    const order = orderDoc.data();
    const expectedAmount = Math.round((order.totalAmount || 0) * 100);
    if (order.invoiceId !== invoice.id || invoice.amount !== expectedAmount) {
      logger.warn('Rejected order payment with mismatched invoice data', { invoiceId: invoice.id, orderId });
      return res.status(202).json({ received: true, verified: false });
    }

    await orderRef.update({
      status: 'paid',
      paidAt: new Date().toISOString(),
      paymentVerifiedAt: new Date().toISOString(),
    });

    res.json({ received: true, verified: true });
  } catch (error) {
    logger.error('Order payment verification failed', error);
    res.status(500).json({ error: 'internal error' });
  }
});

router.get('/orders/success', (req, res) => {
  const message = localizedPaymentSuccess(req, 'order');
  res.send(`
    <html dir="${message.direction}" lang="${message.locale}">
      <body style="font-family: sans-serif; text-align: center; padding: 60px 20px;">
        <h2>✅ ${message.title}</h2>
        <p>${message.body}</p>
      </body>
    </html>
  `);
});

// طلباتي كمشترٍ
router.get('/orders/mine', verifyToken, async (req, res) => {
  try {
    const snapshot = await db.collection('orders')
      .where('buyerId', '==', req.uid)
      .orderBy('createdAt', 'desc').get();
    res.json(snapshot.docs.map((doc) => toBuyerOrder(doc.id, doc.data())));
  } catch (error) {
    logger.error('Failed to load buyer orders', error, { requestId: req.requestId });
    res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
  }
});

// طلبات بيعي (كبائع)
router.get('/orders/selling', verifyToken, async (req, res) => {
  try {
    const snapshot = await db.collection('orders')
      .where('status', '==', 'paid')
      .orderBy('createdAt', 'desc').get();
    const mine = snapshot.docs
      .map((doc) => toSellerOrder(doc.id, doc.data(), req.uid))
      .filter((order) => order.items.length > 0);
    res.json(mine);
  } catch (error) {
    logger.error('Failed to load seller orders', error, { requestId: req.requestId });
    res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
  }
});

module.exports = router;
