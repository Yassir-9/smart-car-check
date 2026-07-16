const express = require('express');
const router = express.Router();
const fs = require('fs');
const path = require('path');
const verifyToken = require('../middleware/auth');

const PARTS_FILE = path.join(__dirname, '../parts.json');

function readParts() {
  try {
    return JSON.parse(fs.readFileSync(PARTS_FILE, 'utf8'));
  } catch (e) {
    return [];
  }
}

function saveParts(parts) {
  fs.writeFileSync(PARTS_FILE, JSON.stringify(parts, null, 2));
}

router.get('/parts', (req, res) => {
  const { brand, model } = req.query;
  let parts = readParts();
  if (brand) {
    parts = parts.filter((p) => p.carBrand === brand);
  }
  if (model) {
    parts = parts.filter((p) => p.carModel && p.carModel.includes(model));
  }
  res.json(parts);
});

router.post('/parts', verifyToken, (req, res) => {
  const { partName, carBrand, carModel, price, sellerPhone, notes, oemNumber, imageBase64 } = req.body;
  if (!partName || !carBrand || !sellerPhone) {
    return res
      .status(400)
      .json({ error: 'اسم القطعة والشركة ورقم الجوال مطلوبة' });
  }
  const parts = readParts();
  const newPart = {
    id: Date.now().toString(),
    ownerId: req.uid,
    partName,
    carBrand,
    carModel: carModel || '',
    price: price || null,
    sellerPhone,
    notes: notes || '',
    oemNumber: oemNumber || null,
    imageBase64: imageBase64 || null,
    createdAt: new Date().toISOString(),
  };
  parts.unshift(newPart);
  saveParts(parts);
  res.json(newPart);
});

router.delete('/parts/:id', verifyToken, (req, res) => {
  const parts = readParts();
  const part = parts.find((p) => p.id === req.params.id);
  if (!part) {
    return res.status(404).json({ error: 'القطعة غير موجودة' });
  }
  if (part.ownerId && part.ownerId !== req.uid) {
    return res.status(403).json({ error: 'لا تملك صلاحية حذف هذه القطعة' });
  }
  const filtered = parts.filter((p) => p.id !== req.params.id);
  saveParts(filtered);
  res.json({ success: true });
});

router.put('/parts/:id', verifyToken, (req, res) => {
  const parts = readParts();
  const index = parts.findIndex((p) => p.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'القطعة غير موجودة' });
  }
  const part = parts[index];
  if (part.ownerId && part.ownerId !== req.uid) {
    return res.status(403).json({ error: 'لا تملك صلاحية تعديل هذه القطعة' });
  }
  const { partName, carBrand, carModel, price, sellerPhone, notes, oemNumber, imageBase64 } = req.body;
  if (!partName || !carBrand || !sellerPhone) {
    return res
      .status(400)
      .json({ error: 'اسم القطعة والشركة ورقم الجوال مطلوبة' });
  }
  parts[index] = {
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
  };
  saveParts(parts);
  res.json(parts[index]);
});

module.exports = router;
