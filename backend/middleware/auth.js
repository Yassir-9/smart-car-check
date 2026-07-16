const admin = require('../firebaseAdmin');

async function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'يلزم تسجيل الدخول' });
  }
  const idToken = authHeader.split('Bearer ')[1];
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    req.uid = decoded.uid;
    next();
  } catch (e) {
    return res.status(401).json({ error: 'جلسة غير صالحة، سجّل دخول من جديد' });
  }
}

module.exports = verifyToken;
