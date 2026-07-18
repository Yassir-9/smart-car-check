const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/auth');
const { db } = require('../firebaseAdmin');

async function readParts() {
  try {
    const snapshot = await db.collection('parts').orderBy('createdAt', 'desc').get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  } catch (e) {
    console.error('خطأ بقراءة القطع من Firestore:', e);
    return [];
  }
}

router.get('/parts', async (req, res) => {
  const { brand, model } = req.query;
  let parts = await readParts();
  if (brand) {
    parts = parts.filter((p) => p.carBrand === brand);
  }
  if (model) {
    parts = parts.filter((p) => p.carModel && p.carModel.includes(model));
  }
  res.json(parts);
});

router.post('/parts', verifyToken, async (req, res) => {
  try {
    const { partName, carBrand, carModel, price, sellerPhone, notes, oemNumber, imageBase64, condition, partBrand } = req.body;
    if (!partName || !carBrand || !sellerPhone) {
      return res
        .status(400)
        .json({ error: 'اسم القطعة والشركة ورقم الجوال مطلوبة' });
    }
    const newPart = {
      ownerId: req.uid,
      partName,
      carBrand,
      carModel: carModel || '',
      price: price || null,
      sellerPhone,
      notes: notes || '',
      oemNumber: oemNumber || null,
      imageBase64: imageBase64 || null,
      condition: condition || null,
      partBrand: partBrand || null,
      createdAt: new Date().toISOString(),
    };
    const docRef = await db.collection('parts').add(newPart);
    res.json({ id: docRef.id, ...newPart });
  } catch (error) {
    console.error('خطأ بإضافة القطعة:', error);
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
  }
});

router.delete('/parts/:id', verifyToken, async (req, res) => {
  try {
    const docRef = db.collection('parts').doc(req.params.id);
    const doc = await docRef.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'القطعة غير موجودة' });
    }
    const part = doc.data();
    if (part.ownerId && part.ownerId !== req.uid) {
      return res.status(403).json({ error: 'لا تملك صلاحية حذف هذه القطعة' });
    }
    await docRef.delete();
    res.json({ success: true });
  } catch (error) {
    console.error('خطأ بحذف القطعة:', error);
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
  }
});

router.put('/parts/:id', verifyToken, async (req, res) => {
  try {
    const docRef = db.collection('parts').doc(req.params.id);
    const doc = await docRef.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'القطعة غير موجودة' });
    }
    const part = doc.data();
    if (part.ownerId && part.ownerId !== req.uid) {
      return res.status(403).json({ error: 'لا تملك صلاحية تعديل هذه القطعة' });
    }
    const { partName, carBrand, carModel, price, sellerPhone, notes, oemNumber, imageBase64, condition, partBrand } = req.body;
    if (!partName || !carBrand || !sellerPhone) {
      return res
        .status(400)
        .json({ error: 'اسم القطعة والشركة ورقم الجوال مطلوبة' });
    }
    const updated = {
      ...part,
      ownerId: part.ownerId || req.uid,
      partName,
      carBrand,
      carModel: carModel || '',
      price: price || null,
      sellerPhone,
      notes: notes || '',
      oemNumber: oemNumber !== undefined ? oemNumber : part.oemNumber || null,
      imageBase64: imageBase64 !== undefined ? imageBase64 : part.imageBase64 || null,
      condition: condition !== undefined ? condition : part.condition || null,
      partBrand: partBrand !== undefined ? partBrand : part.partBrand || null,
    };
    await docRef.set(updated);
    res.json({ id: docRef.id, ...updated });
  } catch (error) {
    console.error('خطأ بتعديل القطعة:', error);
    res.status(500).json({ error: 'حدث خطأ، حاول مرة أخرى' });
  }
});

module.exports = router;
