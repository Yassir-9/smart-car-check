const express = require('express');
const router = express.Router();
const fs = require('fs');
const path = require('path');
const Anthropic = require('@anthropic-ai/sdk');
const obdCodes = require('../knowledge_base/obd_codes.json');
const verifyToken = require('../middleware/auth');
const { db } = require('../firebaseAdmin');

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

const FREE_MONTHLY_LIMIT = 5;

function currentMonthKey() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
}

async function checkAndTrackUsage(uid) {
  const subDoc = await db.collection('users').doc(uid)
    .collection('subscription').doc('current').get();
  const sub = subDoc.exists ? subDoc.data() : null;
  const isActive = sub && sub.status === 'active' &&
    new Date(sub.currentPeriodEnd) > new Date();

  if (isActive) {
    return { allowed: true, isActive: true };
  }

  const monthKey = currentMonthKey();
  const usageRef = db.collection('users').doc(uid).collection('usage').doc(monthKey);
  const usageDoc = await usageRef.get();
  const currentCount = usageDoc.exists ? (usageDoc.data().diagnosisCount || 0) : 0;

  if (currentCount >= FREE_MONTHLY_LIMIT) {
    return { allowed: false, isActive: false, usageCount: currentCount };
  }

  return { allowed: true, isActive: false, usageRef, usageCount: currentCount };
}

const HISTORY_FILE = path.join(__dirname, '../history.json');

function readHistory() {
  try {
    const data = fs.readFileSync(HISTORY_FILE, 'utf8');
    return JSON.parse(data);
  } catch (e) {
    return [];
  }
}

function saveToHistory(entry) {
  const history = readHistory();
  history.unshift(entry); // أحدث سجل بالأول
  fs.writeFileSync(HISTORY_FILE, JSON.stringify(history, null, 2));
}

async function readParts() {
  try {
    const snapshot = await db.collection('parts').orderBy('createdAt', 'desc').get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  } catch (e) {
    console.error('خطأ بقراءة القطع من Firestore:', e);
    return [];
  }
}

async function findMatchingParts(possibleIssue, carBrand) {
  if (!possibleIssue) return [];
  const stopWords = ['في', 'من', 'إلى', 'أو', 'مع', 'عن', 'هذا', 'هذه', 'قد'];
  const keywords = possibleIssue
    .split(/\s+/)
    .map((w) => w.replace(/[^\u0600-\u06FFa-zA-Z0-9]/g, ''))
    .filter((w) => w.length >= 3 && !stopWords.includes(w));

  const parts = await readParts();
  const scored = parts
    .map((p) => {
      let keywordScore = 0;
      keywords.forEach((k) => {
        if (p.partName && p.partName.includes(k)) keywordScore += 1;
      });
      let score = keywordScore;
      if (keywordScore > 0 && carBrand && p.carBrand === carBrand) score += 0.5;
      return { part: p, score, keywordScore };
    })
    .filter((x) => x.keywordScore > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, 5)
    .map((x) => x.part);

  return scored;
}

async function searchPartOnline(possibleIssue, car) {
  try {
    const query = `${car?.brand || ''} ${car?.model || ''} ${car?.year || ''} ${possibleIssue}`;
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 1200,
      tools: [{ type: 'web_search_20250305', name: 'web_search' }],
      system: `أنت مساعد يبحث عن قطع غيار سيارات في الإنترنت للسوق السعودي.
ابحث عن القطعة المطلوبة وأرجع النتيجة فقط ككائن JSON صحيح بدون أي نص قبله أو بعده وبدون علامات markdown، بالشكل التالي بالضبط:
{
  "found": true أو false,
  "suggestions": [
    {"name": "اسم القطعة", "estimated_price": "نطاق تقديري بالريال أو null", "store_name": "اسم المتجر أو الوكيل", "url": "الرابط المباشر الكامل للصفحة أو المنتج، أو null لو غير متوفر"}
  ],
  "summary": "جملة قصيرة توضح أفضل مكان للشراء"
}
لو ما لقيت نتائج واضحة أرجع found:false وsuggestions فاضية.`,
      messages: [{ role: 'user', content: `ابحث عن قطعة غيار: ${query}` }],
    });

    const rawText = response.content
      .filter((block) => block.type === 'text')
      .map((block) => block.text)
      .join('\n')
      .replace(/```json|```/g, '')
      .trim();

    return JSON.parse(rawText);
  } catch (e) {
    console.error('خطأ بالبحث الخارجي:', e);
    return { found: false, suggestions: [], summary: null };
  }
}

function findSimilarConfirmedCases(description, carBrand) {
  if (!description) return '';
  const stopWords = ['في', 'من', 'إلى', 'أو', 'مع', 'عن', 'هذا', 'هذه', 'قد'];
  const keywords = description
    .split(/\s+/)
    .map((w) => w.replace(/[^\u0600-\u06FFa-zA-Z0-9]/g, ''))
    .filter((w) => w.length >= 3 && !stopWords.includes(w));

  const history = readHistory();
  const confirmed = history.filter((h) => h.feedback && h.feedback.accurate === true);

  const scored = confirmed
    .map((h) => {
      let score = 0;
      keywords.forEach((k) => {
        if (h.description && h.description.includes(k)) score += 1;
        if (h.result?.possible_issue && h.result.possible_issue.includes(k)) score += 1;
      });
      return { entry: h, score };
    })
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, 3);

  if (scored.length === 0) return '';

  const lines = scored
    .map(
      (x) =>
        `- وصف مشابه: "${x.entry.description}" → تم تأكيد إن التشخيص الصحيح كان: ${x.entry.result?.possible_issue}`
    )
    .join('\n');

  return `\n\nملاحظة: عندنا حالات مشابهة سابقة أكّد مستخدمون دقة تشخيصها، استفد منها كمرجع إضافي (لا تنسخها حرفياً، فقط استرشد بها):\n${lines}`;
}

function buildObdContext(codes) {
  if (!codes || codes.length === 0) return '';
  const details = codes
    .map((code) => {
      const info = obdCodes[code];
      if (!info) return `الكود ${code}: غير موجود في قاعدة البيانات المحلية بعد.`;
      return `الكود ${code} (${info.title_ar}): الأسباب الشائعة هي ${info.common_causes.join('، ')}.`;
    })
    .join('\n');
  return `\n\nمعلومات أكواد الأعطال المقروءة من جهاز الفحص:\n${details}`;
}

router.post('/diagnose', verifyToken, async (req, res) => {
  try {
    const { description, car, obd_codes, image } = req.body;

    if (!description && !image) {
      return res.status(400).json({ error: 'الوصف أو الصورة مطلوبة' });
    }

    const usageCheck = await checkAndTrackUsage(req.uid);
    if (!usageCheck.allowed) {
      return res.status(402).json({
        error: 'استنفدت عدد التشخيصات المجانية لهذا الشهر',
        subscriptionRequired: true,
        freeUsageLimit: FREE_MONTHLY_LIMIT,
      });
    }

    const obdContext = buildObdContext(obd_codes);

    const systemPrompt = `أنت مساعد تشخيص سيارات خبير. مهمتك تحليل وصف المشكلة وأكواد الأعطال (إن وجدت) وإرجاع تشخيص أولي.
مهم جداً: أرجع فقط كائن JSON صحيح بدون أي نص قبله أو بعده وبدون علامات markdown، بالشكل التالي بالضبط:
{
  "possible_issue": "اسم المشكلة المحتملة بالعربي",
  "severity": "منخفضة" أو "متوسطة" أو "عالية",
  "explanation": "شرح مبسط للمستخدم غير المتخصص",
  "recommendations": ["توصية 1", "توصية 2"],
  "estimated_cost": "نطاق تقديري بالريال السعودي أو null"
}
إذا كانت الصورة تحتوي على شاشة جهاز فحص فيها أكواد أعطال (DTC codes)، اقرأ الأكواد الظاهرة بدقة واستخدمها بالتشخيص. إذا كانت صورة للوحة العدادات أو لمبة تحذير، صف ما تراه ووضّح دلالته.
هذا تشخيص أولي توجيهي فقط وليس بديلاً عن فحص فني متخصص، وضّح ذلك ضمن الشرح لو كانت الحالة تستدعي زيارة ورشة فوراً.`;

    const similarCasesContext = findSimilarConfirmedCases(description, car?.brand);

    const userText = `سيارة المستخدم: ${car?.brand || ''} ${car?.model || ''} ${car?.year || ''}
وصف المشكلة: ${description || 'لم يكتب المستخدم وصفاً نصياً، اعتمد على تحليل الصورة المرفقة بالكامل'}${obdContext}${similarCasesContext}`;

    const userContent = [];
    if (image?.data) {
      userContent.push({
        type: 'image',
        source: {
          type: 'base64',
          media_type: image.media_type || 'image/jpeg',
          data: image.data,
        },
      });
    }
    userContent.push({ type: 'text', text: userText });

    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 1000,
      system: systemPrompt,
      messages: [{ role: 'user', content: userContent }],
    });

    const rawText = response.content
      .filter((block) => block.type === 'text')
      .map((block) => block.text)
      .join('\n')
      .replace(/```json|```/g, '')
      .trim();

    const parsed = JSON.parse(rawText);
    parsed.matched_parts = await findMatchingParts(parsed.possible_issue, car?.brand);

    if (parsed.matched_parts.length === 0) {
      parsed.external_search = await searchPartOnline(parsed.possible_issue, car);
    }

    // حفظ تلقائي بالسجل
    const historyId = Date.now().toString();
    saveToHistory({
      id: historyId,
      timestamp: new Date().toISOString(),
      car: car || {},
      description: description || '(تشخيص بالصورة فقط)',
      result: parsed,
    });

    parsed.diagnosis_id = historyId;

    if (!usageCheck.isActive && usageCheck.usageRef) {
      await usageCheck.usageRef.set(
        { diagnosisCount: (usageCheck.usageCount || 0) + 1 },
        { merge: true }
      );
    }

    res.json(parsed);
  } catch (error) {
    console.error('خطأ في التشخيص:', error);
    res.status(500).json({ error: 'حدث خطأ أثناء التحليل، حاول مرة أخرى' });
  }
});

// جلب سجل الحوادث
router.get('/history', (req, res) => {
  const history = readHistory();
  res.json(history);
});

// حذف سجل معيّن
router.delete('/history/:id', (req, res) => {
  const history = readHistory();
  const filtered = history.filter((h) => h.id !== req.params.id);
  fs.writeFileSync(HISTORY_FILE, JSON.stringify(filtered, null, 2));
  res.json({ success: true });
});

// تسجيل تقييم دقة التشخيص (يستخدم لتحسين النتائج المستقبلية)
router.patch('/history/:id/feedback', (req, res) => {
  const { accurate } = req.body;
  const history = readHistory();
  const index = history.findIndex((h) => h.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'السجل غير موجود' });
  }
  history[index].feedback = {
    accurate: !!accurate,
    ratedAt: new Date().toISOString(),
  };
  fs.writeFileSync(HISTORY_FILE, JSON.stringify(history, null, 2));
  res.json({ success: true });
});

module.exports = router;