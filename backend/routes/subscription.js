const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/auth');
const { db } = require('../firebaseAdmin');

const MOYASAR_BASE = 'https://api.moyasar.com/v1';
const BACKEND_URL = 'https://car-ai-backend-7gpb.onrender.com';

const PLANS = {
  monthly: { amount: 1999, description: 'اشتراك شهري - تشخيص السيارة الذكي' },
  yearly: { amount: 9900, description: 'اشتراك سنوي - تشخيص السيارة الذكي' },
};

function authHeader() {
  const key = process.env.MOYASAR_SECRET_KEY;
  const encoded = Buffer.from(`${key}:`).toString('base64');
  return `Basic ${encoded}`;
}

function currentMonthKey() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
}

router.post('/subscribe', verifyToken, async (req, res) => {
  try {
    const { plan } = req.body;
    const planInfo = PLANS[plan];
    if (!planInfo) {
      return res.status(400).json({ error: 'باقة غير صحيحة' });
    }

    const response = await fetch(`${MOYASAR_BASE}/invoices`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: authHeader(),
      },
      body: JSON.stringify({
        amount: planInfo.amount,
        currency: 'SAR',
        description: planInfo.description,
        callback_url: `${BACKEND_URL}/api/subscription/webhook`,
        success_url: `${BACKEND_URL}/api/subscription/success`,
        metadata: {
          uid: req.uid,
          plan,
        },
      }),
    });

    const data = await response.json();
    if (!response.ok) {
      console.error('خطأ من Moyasar:', data);
      return res.status(500).json({ error: 'تعذر إنشاء فاتورة الدفع' });
    }

    await db.collection('users').doc(req.uid)
      .collection('subscription').doc('pending')
      .set({
        invoiceId: data.id,
        plan,
        createdAt: new Date().toISOString(),
      });

    res.json({ checkoutUrl: data.url, invoiceId: data.id });
  } catch (error) {
    console.error('خطأ بإنشاء الاشتراك:', error);
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
  }
});

router.post('/subscription/webhook', async (req, res) => {
  try {
    const invoice = req.body;
    if (invoice.status !== 'paid') {
      return res.json({ received: true });
    }

    const uid = invoice.metadata?.uid;
    const plan = invoice.metadata?.plan;
    if (!uid || !plan) {
      return res.json({ received: true });
    }

    const now = new Date();
    const periodDays = plan === 'yearly' ? 365 : 30;
    const currentPeriodEnd = new Date(now.getTime() + periodDays * 24 * 60 * 60 * 1000);

    await db.collection('users').doc(uid)
      .collection('subscription').doc('current')
      .set({
        status: 'active',
        plan,
        invoiceId: invoice.id,
        currentPeriodEnd: currentPeriodEnd.toISOString(),
        updatedAt: now.toISOString(),
      });

    res.json({ received: true });
  } catch (error) {
    console.error('خطأ بمعالجة الويب هوك:', error);
    res.status(500).json({ error: 'internal error' });
  }
});

router.get('/subscription/success', (req, res) => {
  res.send(`
    <html dir="rtl" lang="ar">
      <body style="font-family: sans-serif; text-align: center; padding: 60px 20px;">
        <h2>✅ تم الدفع بنجاح!</h2>
        <p>يمكنك الآن الرجوع للتطبيق والاستمتاع بالاشتراك.</p>
      </body>
    </html>
  `);
});

router.get('/subscription/status', verifyToken, async (req, res) => {
  try {
    const subDoc = await db.collection('users').doc(req.uid)
      .collection('subscription').doc('current').get();

    const sub = subDoc.exists ? subDoc.data() : null;
    const isActive = sub && sub.status === 'active' &&
      new Date(sub.currentPeriodEnd) > new Date();

    const monthKey = currentMonthKey();
    const usageDoc = await db.collection('users').doc(req.uid)
      .collection('usage').doc(monthKey).get();
    const usageCount = usageDoc.exists ? (usageDoc.data().diagnosisCount || 0) : 0;

    res.json({
      isActive: !!isActive,
      plan: isActive ? sub.plan : null,
      currentPeriodEnd: isActive ? sub.currentPeriodEnd : null,
      freeUsageCount: usageCount,
      freeUsageLimit: 5,
    });
  } catch (error) {
    console.error('خطأ بجلب حالة الاشتراك:', error);
    res.status(500).json({ error: 'حدث خطأ' });
  }
});

module.exports = router;
