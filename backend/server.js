require('dotenv').config();
const express = require('express');
const cors = require('cors');
const diagnosisRoutes = require('./routes/diagnosis');
const downloadRoutes = require('./routes/download');
const partsRoutes = require('./routes/parts');
const adminRoutes = require('./routes/admin');
const subscriptionRoutes = require('./routes/subscription');

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

app.use('/api', diagnosisRoutes);
app.use('/download', downloadRoutes);
app.use('/api', partsRoutes);
app.use('/api', adminRoutes);
app.use('/api', subscriptionRoutes);

app.get('/', (req, res) => {
  res.send('سيرفر تطبيق تشخيص السيارات الذكي يعمل بنجاح ✅');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`السيرفر يعمل الآن على المنفذ ${PORT}`);
});