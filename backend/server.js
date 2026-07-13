require('dotenv').config();
const express = require('express');
const cors = require('cors');
const diagnosisRoutes = require('./routes/diagnosis');
const downloadRoutes = require('./routes/download');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api', diagnosisRoutes);
app.use('/download', downloadRoutes);

app.get('/', (req, res) => {
  res.send('سيرفر تطبيق تشخيص السيارات الذكي يعمل بنجاح ✅');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`السيرفر يعمل الآن على المنفذ ${PORT}`);
});