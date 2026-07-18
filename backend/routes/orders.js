const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/auth');
const { db } = require('../firebaseAdmin');

const MOYASAR_BASE = 'https://api.moyasar.com/v1';
const BACKEND_URL = 'https://car-ai-backend-7gpb.onrender.com';

function authHeader() {
  const key = process.env.MOYASAR_SECRET_KEY;
  const encoded = Buffer.from(`${key}:`).toString('base64');
  return `Basic ${encoded}`;
}

// إنشاء طلب شراء والانتقال لبوابة الدفع
router.post('/orders/checkout', verifyToken, async (req, res) => {
  try {
    const { partIds } = req.body;
    if (!Array.isArray(partIds) || partIds.length === 0) {
      return res.status(400).json({ error: 'السلة فاضية' });
    }

    const items = [];
    let totalAmount = 0;

    for (const partId of partIds) {
      const doc = await db.collection('parts').doc(partId).get();
      if (!doc.exists) continue;
      const part = doc.data();
      if (part.ownerId === req.uid) {
        return res.status(400).json({ error: 'لا يمكنك شراء قطعتك الخاصة' });
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
      return res.status(400).json({ error: 'لا توجد قطع صالحة للشراء بالسلة' });
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
        description: `طلب شراء قطع غيار - ${items.length} قطعة`,
        callback_url: `${BACKEND_URL}/api/orders/webhook`,
        success_url: `${BACKEND_URL}/api/orders/success`,
        metadata: {
          orderId: orderRef.id,
        },
      }),
    });

    const data = await response.json();
    if (!response.ok) {
      console.error('خطأ من Moyasar:', data);
      return res.status(500).json({ error: 'تعذر إنشاء فاتورة الدفع' });
    }

    await orderRef.update({ invoiceId: data.id });

    res.json({ checkoutUrl: data.url, orderId: orderRef.id });
  } catch (error) {
    console.error('خطأ بإنشاء الطلب:', error);
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
  }
});

// ويب هوك تأكيد الدفع
router.post('/orders/webhook', async (req, res) => {
  try {
    const invoice = req.body;
    if (invoice.status !== 'paid') {
      return res.json({ received: true });
    }

    const orderId = invoice.metadata?.orderId;
    if (!orderId) {
      return res.json({ received: true });
    }

    await db.collection('orders').doc(orderId).update({
      status: 'paid',
      paidAt: new Date().toISOString(),
    });

    res.json({ received: true });
  } catch (error) {
    console.error('خطأ بمعالجة ويب هوك الطلبات:', error);
    res.status(500).json({ error: 'internal error' });
  }
});

router.get('/orders/success', (req, res) => {
  res.send(`
    <html dir="rtl" lang="ar">
      <body style="font-family: sans-serif; text-align: center; padding: 60px 20px;">
        <h2>✅ تم الدفع بنجاح!</h2>
        <p>يمكنك الآن الرجوع للتطبيق ومتابعة طلبك.</p>
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
    res.json(snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
  } catch (error) {
    console.error('خطأ بجلب طلباتي:', error);
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
  }
});

// طلبات بيعي (كبائع)
router.get('/orders/selling', verifyToken, async (req, res) => {
  try {
    const snapshot = await db.collection('orders')
      .where('status', '==', 'paid')
      .orderBy('createdAt', 'desc').get();
    const mine = snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }))
      .filter((order) => order.items.some((item) => item.sellerId === req.uid));
    res.json(mine);
  } catch (error) {
    console.error('خطأ بجلب طلبات البيع:', error);
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
  }
});

module.exports = router;
