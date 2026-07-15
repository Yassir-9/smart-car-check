const express = require('express');
const router = express.Router();
const fs = require('fs');
const path = require('path');

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

// جلب القطع (مع فلترة اختيارية بالشركة/الموديل)
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

// إضافة قطعة جديدة (بدون تسجيل دخول، برقم جوال للتواصل)
router.post('/parts', (req, res) => {
  const { partName, carBrand, carModel, price, sellerPhone, notes } = req.body;
  if (!partName || !carBrand || !sellerPhone) {
    return res
      .status(400)
      .json({ error: 'اسم القطعة والشركة ورقم الجوال مطلوبة' });
  }
  const parts = readParts();
  const newPart = {
    id: Date.now().toString(),
    partName,
    carBrand,
    carModel: carModel || '',
    price: price || null,
    sellerPhone,
    notes: notes || '',
    createdAt: new Date().toISOString(),
  };
  parts.unshift(newPart);
  saveParts(parts);
  res.json(newPart);
});

// حذف قطعة
router.delete('/parts/:id', (req, res) => {
  const parts = readParts();
  const filtered = parts.filter((p) => p.id !== req.params.id);
  saveParts(filtered);
  res.json({ success: true });
});

module.exports = router;
