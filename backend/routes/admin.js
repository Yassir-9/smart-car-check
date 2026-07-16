const express = require('express');
const router = express.Router();
const fs = require('fs');
const path = require('path');
const { auth } = require('../firebaseAdmin');

function requireAdminSecret(req, res, next) {
  const secret = req.query.secret;
  if (!secret || secret !== process.env.ADMIN_SECRET) {
    return res.status(401).send('غير مصرح لك بالدخول');
  }
  next();
}

function readJsonSafe(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (e) {
    return [];
  }
}

router.get('/admin/stats', requireAdminSecret, async (req, res) => {
  try {
    const partsCount = readJsonSafe(path.join(__dirname, '../parts.json')).length;
    const history = readJsonSafe(path.join(__dirname, '../history.json'));
    const diagnosesCount = history.length;
    const rated = history.filter((h) => h.feedback);
    const accurateCount = rated.filter((h) => h.feedback.accurate === true).length;
    const inaccurateCount = rated.filter((h) => h.feedback.accurate === false).length;

    let usersCount = 0;
    try {
      const list = await auth.listUsers(1000);
      usersCount = list.users.length;
    } catch (e) {
      usersCount = null;
    }

    res.json({
      usersCount,
      partsCount,
      diagnosesCount,
      feedback: {
        rated: rated.length,
        accurate: accurateCount,
        inaccurate: inaccurateCount,
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'حدث خطأ أثناء جلب الإحصائيات' });
  }
});

module.exports = router;
