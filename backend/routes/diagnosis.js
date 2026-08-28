const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/auth');
const { db } = require('../firebaseAdmin');
const logger = require('../utils/logger');
const { getAiProvider } = require('../services/ai/aiProvider');
const { validateDiagnosis, normalizeDiagnosis, fallbackDiagnosis, addLegacyAliases, DIAGNOSIS_RESPONSE_SCHEMA } = require('../services/diagnosis/diagnosisSchema');
const { normalizeObdCodes, localObdContext, enrichObdResults } = require('../services/diagnosis/obdEnrichment');
const { createCacheKey, getCachedDiagnosis, setCachedDiagnosis } = require('../services/diagnosis/diagnosisCache');
const { isDevelopmentUsageLimitBypassEnabled, isQaUsageLimitBypassEnabled } = require('../services/diagnosis/usageLimit');
const { buildDiagnosisPrompts } = require('../services/diagnosis/diagnosisPrompt');
const { normalizeDiagnosisImage } = require('../services/diagnosis/diagnosisImage');
const { generateRepairReview } = require('../services/repairReview/repairReviewService');

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

async function saveToHistory(uid, entry) {
  try {
    await db.collection('users').doc(uid)
      .collection('history').doc(entry.id).set(entry);
  } catch (e) {
    logger.error('Failed to save diagnosis history', e);
  }
}

async function getUserHistory(uid) {
  try {
    const snapshot = await db.collection('users').doc(uid)
      .collection('history').orderBy('timestamp', 'desc').get();
    return snapshot.docs.map((doc) => doc.data());
  } catch (e) {
    logger.error('Failed to load diagnosis history', e);
    return [];
  }
}

async function readParts() {
  try {
    const snapshot = await db.collection('parts').orderBy('createdAt', 'desc').get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  } catch (e) {
    logger.error('Failed to read parts from Firestore', e);
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
    const rawText = await getAiProvider().generateJson({
      system: 'ابحث عن قطع سيارات للسوق السعودي. أرجع JSON فقط، ولا تخترع متجرًا أو رابطًا أو سعرًا.',
      prompt: `ابحث عن: ${query}. المخطط: {"found":boolean,"suggestions":[{"name":string,"estimated_price":string|null,"store_name":string,"url":string|null}],"summary":string|null}. إذا لم تجد مصدرًا واضحًا أرجع found:false.`,
      maxOutputTokens: 650,
      useWebSearch: true,
    });
    return JSON.parse(rawText.replace(/```json|```/g, '').trim());
  } catch (e) {
    logger.error('External parts search failed', e);
    return { found: false, suggestions: [], summary: null };
  }
}

async function findSimilarConfirmedCases(description, carBrand) {
  if (!description) return '';
  const stopWords = ['في', 'من', 'إلى', 'أو', 'مع', 'عن', 'هذا', 'هذه', 'قد'];
  const keywords = description
    .split(/\s+/)
    .map((w) => w.replace(/[^\u0600-\u06FFa-zA-Z0-9]/g, ''))
    .filter((w) => w.length >= 3 && !stopWords.includes(w));

  let confirmed = [];
  try {
    const snapshot = await db.collection('confirmed_diagnoses')
      .orderBy('confirmedAt', 'desc').limit(200).get();
    confirmed = snapshot.docs.map((doc) => doc.data());
  } catch (e) {
    logger.error('Failed to load confirmed diagnoses', e);
    return '';
  }

  const scored = confirmed
    .map((h) => {
      let score = 0;
      keywords.forEach((k) => {
        if (h.description && h.description.includes(k)) score += 1;
        if (h.possibleIssue && h.possibleIssue.includes(k)) score += 1;
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
        `- وصف مشابه: "${x.entry.description}" → تم تأكيد إن التشخيص الصحيح كان: ${x.entry.possibleIssue}`
    )
    .join('\n');

  return `\n\nملاحظة: عندنا حالات مشابهة سابقة أكّد مستخدمون دقة تشخيصها، استفد منها كمرجع إضافي (لا تنسخها حرفياً، فقط استرشد بها):\n${lines}`;
}

router.post('/diagnose', verifyToken, async (req, res) => {
  try {
    const { description, car, obd_codes, image: rawImage } = req.body;
    const normalizedObdCodes = normalizeObdCodes(obd_codes);
    const imageResult = normalizeDiagnosisImage(rawImage);
    if (imageResult.error) {
      return res.status(400).json({ error: imageResult.error });
    }
    const image = imageResult.image;

    if (!description && !image && normalizedObdCodes.length === 0) {
      return res.status(400).json({ error: 'الوصف أو الصورة أو أكواد OBD مطلوبة' });
    }

    const developmentBypass = isDevelopmentUsageLimitBypassEnabled();
    const qaBypass = isQaUsageLimitBypassEnabled(req.uid);
    const usageLimitBypassed = developmentBypass || qaBypass;
    if (developmentBypass) {
      logger.warn('Development usage limit bypass active');
    } else if (qaBypass) {
      logger.warn('QA usage limit bypass active for allowlisted test account');
    }
    const usageCheck = usageLimitBypassed
      ? { allowed: true, isActive: false, bypassed: true }
      : await checkAndTrackUsage(req.uid);
    if (!usageCheck.allowed) {
      return res.status(402).json({
        error: 'استنفدت عدد التشخيصات المجانية لهذا الشهر',
        subscriptionRequired: true,
        freeUsageLimit: FREE_MONTHLY_LIMIT,
      });
    }

    const obdContext = localObdContext(normalizedObdCodes);
    const cacheKey = createCacheKey({
      uid: req.uid,
      car,
      description,
      obdCodes: normalizedObdCodes,
      image,
    });
    let diagnosis = await getCachedDiagnosis(db, req.uid, cacheKey);
    let cacheHit = !!diagnosis;

    if (!diagnosis) {
      const schemaDescription = '{"title":string,"summary":string,"severity":"low|medium|high|critical","confidence":number,"can_drive":boolean,"drive_advice":string,"likely_causes":string[],"recommended_checks":string[],"possible_parts":string[],"next_step":string,"workshop_questions":string[],"warnings":string[],"obd_codes":[{"code":string,"meaning":string,"severity":string,"recommended_checks":string[],"possible_parts":string[],"urgent":boolean,"next_step":string}]}';
      const { system: systemPrompt, prompt } = buildDiagnosisPrompts({
        car,
        description,
        obdContext,
        hasImage: !!image,
        schemaDescription,
      });
      const provider = getAiProvider();
      let rawText;
      let parsedCandidate;
      let errors = [];
      for (let attempt = 0; attempt < 2; attempt += 1) {
        try {
          rawText = await provider.generateJson({
            system: systemPrompt,
            prompt: attempt === 0 || !rawText
              ? prompt
              : `صحح الاستجابة التالية لتطابق المخطط فقط دون إضافة معلومات جديدة. الأخطاء: ${errors.join(', ')}\n${rawText}`,
            image: attempt === 0 ? image : null,
            maxOutputTokens: 950,
            responseSchema: DIAGNOSIS_RESPONSE_SCHEMA,
          });
          parsedCandidate = JSON.parse(rawText.replace(/```json|```/g, '').trim());
          errors = validateDiagnosis(parsedCandidate);
          if (errors.length === 0) break;
        } catch (error) {
          errors = ['provider response unavailable or invalid'];
          logger.warn('AI diagnosis attempt failed', { provider: provider.name, attempt: attempt + 1, error });
        }
      }
      if (errors.length !== 0) {
        const providerError = new Error(`AI provider ${provider.name} failed to return a valid diagnosis`);
        providerError.statusCode = 502;
        providerError.provider = provider.name;
        throw providerError;
      }
      diagnosis = normalizeDiagnosis(parsedCandidate);
      diagnosis.obd_codes = enrichObdResults(normalizedObdCodes, parsedCandidate?.obd_codes, diagnosis);
      await setCachedDiagnosis(db, req.uid, cacheKey, diagnosis);
    }

    const parsed = addLegacyAliases(diagnosis);
    parsed.obd_analysis = diagnosis.obd_codes;
    parsed.matched_parts = await findMatchingParts(diagnosis.title, car?.brand);
    parsed.cache_hit = cacheHit;

    // البحث الخارجي صار عند الطلب فقط (زر يدوي بالتطبيق) لتوفير تكلفة API

    // حفظ تلقائي بالسجل (خاص بالمستخدم فقط)
    const historyId = Date.now().toString();
    await saveToHistory(req.uid, {
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
    logger.error('Diagnosis request failed', error, { requestId: req.requestId });
    const statusCode = error.statusCode || 500;
    res.status(statusCode).json({
      error: statusCode === 502 ? 'مزود الذكاء الاصطناعي غير متاح حاليًا' : 'حدث خطأ أثناء التحليل، حاول مرة أخرى',
    });
  }
});

// جلب سجل الحوادث (خاص بالمستخدم المسجّل فقط)
router.get('/history', verifyToken, async (req, res) => {
  const history = await getUserHistory(req.uid);
  res.json(history);
});

// حذف سجل معيّن (خاص بالمستخدم فقط)
router.delete('/history/:id', verifyToken, async (req, res) => {
  try {
    await db.collection('users').doc(req.uid)
      .collection('history').doc(req.params.id).delete();
    res.json({ success: true });
  } catch (error) {
    logger.error('Failed to delete diagnosis history', error, { requestId: req.requestId });
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
  }
});

// تسجيل تقييم دقة التشخيص (يستخدم لتحسين النتائج المستقبلية)
router.patch('/history/:id/feedback', verifyToken, async (req, res) => {
  try {
    const { accurate } = req.body;
    const docRef = db.collection('users').doc(req.uid).collection('history').doc(req.params.id);
    const doc = await docRef.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'السجل غير موجود' });
    }
    const feedback = {
      accurate: !!accurate,
      ratedAt: new Date().toISOString(),
    };
    await docRef.set({ feedback }, { merge: true });

    if (accurate === true) {
      const entry = doc.data();
      await db.collection('confirmed_diagnoses').add({
        description: entry.description,
        possibleIssue: entry.result?.possible_issue || null,
        carBrand: entry.car?.brand || null,
        confirmedAt: new Date().toISOString(),
      });
    }

    res.json({ success: true });
  } catch (error) {
    logger.error('Failed to save diagnosis feedback', error, { requestId: req.requestId });
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
  }
});

router.post('/ask-expert', verifyToken, async (req, res) => {
  try {
    const { question, diagnosis, car } = req.body;
    if (!question || !question.trim()) {
      return res.status(400).json({ error: 'السؤال مطلوب' });
    }

    const contextText = diagnosis
      ? `سياق التشخيص السابق للسيارة:
المشكلة: ${diagnosis.possible_issue || ''}
الخطورة: ${diagnosis.severity || ''}
هل يمكن القيادة: ${diagnosis.can_drive || ''}
الشرح: ${diagnosis.explanation || ''}
السيارة: ${car?.brand || ''} ${car?.model || ''} ${car?.year || ''}`
      : `السيارة: ${car?.brand || ''} ${car?.model || ''} ${car?.year || ''}`;

    const answer = await getAiProvider().generateText({
      maxOutputTokens: 450,
      system: `أنت خبير سيارات ذكي وودود تجيب على أسئلة المستخدم المتابعة بعد تشخيص أولي لسيارته.
أجب بالعربي بشكل مباشر ومختصر ومفهوم لغير المتخصصين، بدون مقدمات طويلة.
لو السؤال يخص القيادة أو السلامة، كن واضحاً وحاسماً.
لا تكرر معلومات التشخيص الأصلي إلا لو ضروري للإجابة.`,
      prompt: `${contextText}

سؤال المستخدم: ${question.trim()}`,
    });

    res.json({ answer });
  } catch (error) {
    logger.error('Expert assistant request failed', error, { requestId: req.requestId });
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
  }
});

router.post('/obd/part-search', verifyToken, async (req, res) => {
  try {
    const { code, car } = req.body;
    if (!code) {
      return res.status(400).json({ error: 'كود العطل مطلوب' });
    }
    const info = localObdContext(normalizeObdCodes([code]))[0];
    const issueText = info?.known
      ? `${info.official_title} (${info.likely_causes.join('، ')})`
      : `قطعة غيار متعلقة بكود عطل السيارة ${code} (اقرأ رمز OBD-II هذا وابحث عن أشهر أسباب حدوثه والقطعة المرتبطة به)`;
    const result = await searchPartOnline(issueText, car || {});
    res.json(result);
  } catch (error) {
    logger.error('OBD part search failed', error, { requestId: req.requestId });
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
  }
});

router.post('/parts/external-search', verifyToken, async (req, res) => {
  try {
    const { query, car } = req.body;
    if (!query) {
      return res.status(400).json({ error: 'وصف المشكلة مطلوب' });
    }
    const result = await searchPartOnline(query, car || {});
    res.json(result);
  } catch (error) {
    logger.error('Manual part search failed', error, { requestId: req.requestId });
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
  }
});

async function repairReviewHandler(req, res) {
  try {
    const { workshopStatement, proposedPart, proposedParts, quotedPrice, car, diagnosis, obd_codes, image: rawImage, openIssues, maintenanceHistory, repairHistory } = req.body;
    const imageResult = normalizeDiagnosisImage(rawImage);
    if (imageResult.error) return res.status(400).json({ error: imageResult.error });
    const image = imageResult.image;
    const parts = Array.isArray(proposedParts)
      ? proposedParts.filter((part) => typeof part === 'string' && part.trim()).slice(0, 20)
      : (typeof proposedPart === 'string' && proposedPart.trim() ? [proposedPart.trim()] : []);
    if (!String(workshopStatement || '').trim() && parts.length === 0 && !image) {
      return res.status(400).json({ error: 'أدخل كلام الورشة أو القطع المقترحة أو صورة العرض' });
    }
    const codes = normalizeObdCodes(obd_codes);
    const numericPrice = quotedPrice === null || quotedPrice === undefined || String(quotedPrice).trim() === ''
      ? null
      : Number(quotedPrice);
    const input = {
      vehicle: { id: car?.id || null, make: car?.brand || car?.make || null, model: car?.model || null, year: car?.year || null, mileage: car?.currentMileage || car?.mileage || null },
      workshop_statement: String(workshopStatement || '').trim() || null,
      proposed_parts: parts,
      quoted_price_sar: Number.isFinite(numericPrice) ? numericPrice : null,
      previous_diagnosis: diagnosis ? {
        id: diagnosis.id || diagnosis.diagnosis_id || null,
        title: diagnosis.title || diagnosis.possible_issue,
        summary: diagnosis.summary || diagnosis.explanation || null,
        likely_causes: diagnosis.likely_causes || [],
        recommended_checks: diagnosis.recommended_checks || diagnosis.recommendations || [],
      } : null,
      scanned_obd_codes: localObdContext(codes),
      open_issues: Array.isArray(openIssues) ? openIssues.slice(0, 10) : [],
      maintenance_history: Array.isArray(maintenanceHistory) ? maintenanceHistory.slice(0, 10) : [],
      repair_history: Array.isArray(repairHistory) ? repairHistory.slice(0, 10) : [],
      quote_image_attached: !!image,
    };
    const result = await generateRepairReview({ provider: getAiProvider(), input, image });
    if (!result.analysis_complete) return res.status(200).json(result);
    const reviewId = Date.now().toString();
    result.review_id = reviewId;
    try {
      await db.collection('users').doc(req.uid).collection('repair_reviews').doc(reviewId).set({
        id: reviewId, vehicleId: car?.id || null,
        diagnosisId: diagnosis?.id || diagnosis?.diagnosis_id || null,
        obdCodes: codes, transportType: req.body.obdScan?.transportType || null,
        workshopStatement: input.workshop_statement, proposedParts: parts,
        quotedPrice: input.quoted_price_sar, result, createdAt: new Date().toISOString(),
        repairOutcome: null,
      });
    } catch (storageError) {
      logger.warn('Failed to save repair review', { error: storageError, requestId: req.requestId });
    }
    return res.json(result);
  } catch (error) {
    logger.error('Before-you-pay analysis failed', error, { requestId: req.requestId });
    return res.status(500).json({ error: 'تعذر مراجعة العرض الآن' });
  }
}

router.post('/repair-review', verifyToken, repairReviewHandler);
router.post('/before-you-pay', verifyToken, repairReviewHandler);

module.exports = router;
