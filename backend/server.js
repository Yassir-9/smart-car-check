require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { randomUUID } = require('crypto');
const logger = require('./utils/logger');
const { generalApiLimiter } = require('./middleware/rateLimit');
const { createCorsOptions, helmetOptions } = require('./middleware/httpSecurity');
const diagnosisRoutes = require('./routes/diagnosis');
const downloadRoutes = require('./routes/download');
const partsRoutes = require('./routes/parts');
const adminRoutes = require('./routes/admin');
const subscriptionRoutes = require('./routes/subscription');
const ratingsRoutes = require('./routes/ratings');
const ordersRoutes = require('./routes/orders');
const accountRoutes = require('./routes/account');

const app = express();
// Render terminates TLS at one trusted proxy hop. This keeps req.ip accurate
// without trusting an arbitrary client-supplied X-Forwarded-For chain.
app.set('trust proxy', 1);
app.disable('x-powered-by');
app.use(helmet(helmetOptions));
const { allowedOrigins, options: corsOptions } = createCorsOptions();
app.use((req, res, next) => {
  const requestId = randomUUID();
  const startedAt = Date.now();
  req.requestId = requestId;
  res.setHeader('x-request-id', requestId);
  res.on('finish', () => logger.info('HTTP request completed', {
    requestId,
    method: req.method,
    path: req.path,
    statusCode: res.statusCode,
    durationMs: Date.now() - startedAt,
  }));
  next();
});
app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));
app.use('/api', generalApiLimiter);

app.use('/api', diagnosisRoutes);
app.use('/download', downloadRoutes);
app.use('/api', partsRoutes);
app.use('/api', adminRoutes);
app.use('/api', subscriptionRoutes);
app.use('/api', ratingsRoutes);
app.use('/api', ordersRoutes);
app.use('/api', accountRoutes);

app.get('/', (req, res) => {
  res.send('سيرفر تطبيق تشخيص السيارات الذكي يعمل بنجاح ✅');
});

app.use((error, req, res, next) => {
  logger.error('Unhandled API error', error, {
    requestId: req.requestId,
    method: req.method,
    path: req.path,
  });
  if (res.headersSent) return next(error);
  const statusCode = error.statusCode || 500;
  return res.status(statusCode).json({
    error: statusCode === 403 ? 'المصدر غير مسموح' : 'حدث خطأ داخلي',
    requestId: req.requestId,
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  logger.info('Backend server started', { port: PORT, allowedOrigins: [...allowedOrigins] });
});
