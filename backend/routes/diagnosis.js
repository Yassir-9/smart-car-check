const express = require('express');
const router = express.Router();
const fs = require('fs');
const path = require('path');
const Anthropic = require('@anthropic-ai/sdk');
const obdCodes = require('../knowledge_base/obd_codes.json');

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

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

const PARTS_FILE = path.join(__dirname, '../parts.json');

function readParts() {
  try {
    return JSON.parse(fs.readFileSync(PARTS_FILE, 'utf8'));
  } catch (e) {
    return [];
  }
}

function findMatchingParts(possibleIssue, carBrand) {
  if (!possibleIssue) return [];
  const stopWords = ['في', 'من', 'إلى', 'أو', 'مع', 'عن', 'هذا', 'هذه', 'قد'];
  const keywords = possibleIssue
    .split(/\s+/)
    .map((w) => w.replace(/[^\u0600-\u06FFa-zA-Z0-9]/g, ''))
    .filter((w) => w.length >= 3 && !stopWords.includes(w));

  const parts = readParts();
  const scored = parts
    .map((p) => {
      let score = 0;
      keywords.forEach((k) => {
        if (p.partName && p.partName.includes(k)) score += 1;
      });
      if (carBrand && p.carBrand === carBrand) score += 0.5;
      return { part: p, score };
    })
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, 5)
    .map((x) => x.part);

  return scored;
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

router.post('/diagnose', async (req, res) => {
  try {
    const { description, car, obd_codes } = req.body;

    if (!description) {
      return res.status(400).json({ error: 'الوصف مطلوب' });
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
هذا تشخيص أولي توجيهي فقط وليس بديلاً عن فحص فني متخصص، وضّح ذلك ضمن الشرح لو كانت الحالة تستدعي زيارة ورشة فوراً.`;

    const userMessage = `سيارة المستخدم: ${car?.brand || ''} ${car?.model || ''} ${car?.year || ''}
وصف المشكلة: ${description}${obdContext}`;

    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 1000,
      system: systemPrompt,
      messages: [{ role: 'user', content: userMessage }],
    });

    const rawText = response.content
      .filter((block) => block.type === 'text')
      .map((block) => block.text)
      .join('\n')
      .replace(/```json|```/g, '')
      .trim();

    const parsed = JSON.parse(rawText);
    parsed.matched_parts = findMatchingParts(parsed.possible_issue, car?.brand);

    // حفظ تلقائي بالسجل
    saveToHistory({
      id: Date.now().toString(),
      timestamp: new Date().toISOString(),
      car: car || {},
      description,
      result: parsed,
    });

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

module.exports = router;