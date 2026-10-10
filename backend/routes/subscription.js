const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/auth');
const { db } = require('../firebaseAdmin');
const { MOYASAR_BASE, authHeader, fetchVerifiedInvoice } = require('../utils/moyasar');
const logger = require('../utils/logger');
const { checkoutLimiter } = require('../middleware/rateLimit');
const { localizedError, localizedPaymentSuccess, requestLocale } = require('../utils/localizedResponse');

const BACKEND_URL = 'https://car-ai-backend-7gpb.onrender.com';

const PLANS = {
  monthly: { amount: 1499 },
  yearly: { amount: 11900 },
};

function currentMonthKey() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
}

router.post('/subscribe', verifyToken, checkoutLimiter, async (req, res) => {
  try {
    const locale = requestLocale(req);
    const { plan } = req.body;
    const planInfo = PLANS[plan];
    if (!planInfo) {
      return res.status(400).json(localizedError(req, 'INVALID_PLAN'));
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
        description: locale === 'en'
          ? `${plan === 'yearly' ? 'Annual' : 'Monthly'} subscription - Smart Car Check`
          : `اشتراك ${plan === 'yearly' ? 'سنوي' : 'شهري'} - تشخيص السيارة الذكي`,
        callback_url: `${BACKEND_URL}/api/subscription/webhook`,
        success_url: `${BACKEND_URL}/api/subscription/success?locale=${locale}`,
        metadata: {
          uid: req.uid,
          plan,
        },
      }),
    });

    const data = await response.json();
    if (!response.ok) {
      logger.warn('Moyasar rejected subscription invoice creation', { statusCode: response.status });
      return res.status(500).json(localizedError(req, 'PAYMENT_CREATION_FAILED'));
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
    logger.error('Subscription checkout creation failed', error, { requestId: req.requestId });
    res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
  }
});

router.post('/subscription/webhook', async (req, res) => {
  try {
    const notifiedInvoiceId = req.body?.id;
    const invoice = await fetchVerifiedInvoice(notifiedInvoiceId);
    if (!invoice || invoice.status !== 'paid' || invoice.currency !== 'SAR') {
      logger.warn('Rejected unverified subscription payment notification', { invoiceId: notifiedInvoiceId });
      return res.status(202).json({ received: true, verified: false });
    }

    const uid = invoice.metadata?.uid;
    const plan = invoice.metadata?.plan;
    const planInfo = PLANS[plan];
    if (!uid || !planInfo || invoice.amount !== planInfo.amount) {
      return res.status(202).json({ received: true, verified: false });
    }
    const pendingRef = db.collection('users').doc(uid)
      .collection('subscription').doc('pending');
    const pendingDoc = await pendingRef.get();
    const pending = pendingDoc.exists ? pendingDoc.data() : null;
    if (!pending || pending.invoiceId !== invoice.id || pending.plan !== plan) {
      logger.warn('Rejected subscription payment with mismatched invoice data', { invoiceId: invoice.id });
      return res.status(202).json({ received: true, verified: false });
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
        paymentVerifiedAt: now.toISOString(),
      });

    await pendingRef.delete();
    res.json({ received: true, verified: true });
  } catch (error) {
    logger.error('Subscription payment verification failed', error);
    res.status(500).json({ error: 'internal error' });
  }
});

router.get('/subscription/success', (req, res) => {
  const message = localizedPaymentSuccess(req, 'subscription');
  res.send(`
    <html dir="${message.direction}" lang="${message.locale}">
      <body style="font-family: sans-serif; text-align: center; padding: 60px 20px;">
        <h2>✅ ${message.title}</h2>
        <p>${message.body}</p>
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
    logger.error('Failed to load subscription status', error, { requestId: req.requestId });
    res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
  }
});

module.exports = router;
