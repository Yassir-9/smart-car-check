const express = require('express');
const path = require('path');
const router = express.Router();
const logger = require('../utils/logger');

router.get('/app-release.apk', (req, res) => {
  const filePath = path.join(__dirname, '..', 'public', 'downloads', 'app-release.apk');
  res.download(filePath, 'app-release.apk', (err) => {
    if (err) {
      logger.error('APK download failed', err, { requestId: req.requestId });
      if (!res.headersSent) {
        res.status(404).send('الملف غير موجود');
      }
    }
  });
});

module.exports = router;
