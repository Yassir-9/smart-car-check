# تطبيق تشخيص السيارات الذكي - الهيكل الأولي

هذا هيكل أولي (MVP Skeleton) للمشروع، يحتوي على:
- **frontend/**: تطبيق Flutter (الواجهة)
- **backend/**: سيرفر Node.js يتصل بـ Claude API (العقل المدبر)

---

## 1. تشغيل الباك اند (السيرفر)

### المتطلبات
- تثبيت [Node.js](https://nodejs.org) (نسخة 18 أو أحدث)
- حساب على [console.anthropic.com](https://console.anthropic.com) للحصول على مفتاح API

### الخطوات
```bash
cd backend
npm install
cp .env.example .env
# افتح ملف .env وضع مفتاح ANTHROPIC_API_KEY الخاص فيك
npm run start
```
لو كل شي تمام، بترى رسالة: `السيرفر يعمل الآن على المنفذ 3000`

### تجربة سريعة (بدون التطبيق) عبر Postman أو curl:
```bash
curl -X POST http://localhost:3000/api/diagnose \
  -H "Content-Type: application/json" \
  -d '{"description": "صوت طقطقة عند الدوران يمين", "car": {"brand": "تويوتا", "model": "كامري", "year": 2022}, "obd_codes": ["P0300"]}'
```

---

## 2. تشغيل الفرونت اند (تطبيق Flutter)

### المتطلبات
- تثبيت [Flutter SDK](https://docs.flutter.dev/get-started/install)
- تأكد من `flutter doctor` يطلع بدون أخطاء حرجة

### الخطوات
```bash
cd frontend
flutter pub get
flutter run
```

⚠️ **مهم**: في ملف `lib/services/api_service.dart` غيّر السطر:
```dart
static const String baseUrl = 'https://YOUR_BACKEND_DOMAIN.com/api';
```
- أثناء التطوير المحلي: استخدم `http://10.0.2.2:3000/api` لمحاكي Android
  أو `http://localhost:3000/api` لمحاكي iOS
- بعد نشر السيرفر: ضع الرابط الفعلي

---

## 3. الخطوات القادمة (Roadmap مقترح)

### المرحلة القادمة مباشرة
- [ ] بناء نظام تسجيل دخول / حسابات مستخدمين (Firebase Auth مقترح، سهل ومجاني للبداية)
- [ ] توسيع قاعدة بيانات أكواد OBD (backend/knowledge_base/obd_codes.json) — هذا أهم استثمار بالمشروع
- [ ] ربط قسم الأخبار بمصدر حقيقي (RSS أو تجميع يدوي عبر لوحة تحكم بسيطة)

### مرحلة متوسطة
- [ ] دمج قراءة فعلية من جهاز OBD-II عبر بلوتوث (مكتبة flutter_blue_plus مضافة بالفعل)
- [ ] بناء قاعدة معرفة موسعة (RAG) بدل تمرير الأكواد كنص مباشر، باستخدام Vector DB
- [ ] شبكة ورش: قاعدة بيانات ورش موثقة + نظام تقييم وحجز

### مرحلة النضج
- [ ] نشر السيرفر على استضافة حقيقية (Render, Railway, أو AWS)
- [ ] نظام اشتراكات / نموذج ربحي
- [ ] اعتماد رسمي أو شراكات مع جهات معتمدة

---

## ملاحظات أمان مهمة
- لا تضع مفتاح API أبداً داخل كود التطبيق (Frontend) — دائماً عبر السيرفر فقط
- أضف صفحة "إخلاء مسؤولية" واضحة في التطبيق: التشخيص توجيهي وليس بديلاً عن فحص فني معتمد
- لما توسّع الفريق، فكر بترخيص البيانات وحماية خصوصية المستخدم (خاصة بيانات الموقع لو ربطته بالورش)
