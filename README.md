# Smart Car Check

تطبيق Flutter لتشخيص أعطال السيارات ومتابعة الصيانة، مع Backend مبني بـNode.js. يدعم Android والويب، ويستخدم Firebase للحسابات والبيانات وطبقة AI قابلة للتبديل للتحليل السياقي.

## المكونات

- `frontend/`: تطبيق Flutter لـAndroid والويب.
- `backend/`: واجهة Express API والتكامل مع Firebase Admin وGemini/Anthropic وMoyasar.
- `docs/`: نسخة Flutter Web مبنية للنشر عبر GitHub Pages.
- `backend/knowledge_base/obd_codes.json`: قاعدة تعريفات وأسباب أكواد OBD المعروفة.
- `backend/legacy/`: بيانات JSON قديمة محفوظة للمرجعية؛ التطبيق الحالي لا يقرأ منها.

## الخصائص الحالية

- تسجيل الدخول برقم الجوال وOTP عبر Firebase Authentication.
- تخزين السيارات، سجل التشخيص، الصيانة، التذكيرات، القطع والطلبات في Firestore.
- تشخيص الأعراض والصور باستخدام Gemini 2.5 Flash افتراضيًا، مع Anthropic كمزود Legacy اختياري.
- نتيجة تشخيص ثابتة ومتحقق منها، وCache معزول لكل مستخدم لتقليل استدعاءات AI.
- واجهة V2 تشمل معالج فحص، نتيجة منظمة، سجل صحة السيارة، تتبع الإصلاح وميزة «قبل ما تدفع للورشة».
- اتصال Android بأجهزة OBD-II/ELM327 عبر Bluetooth Classic وقراءة أكواد المحرك والقير.
- إرسال أكواد OBD المقروءة تلقائيًا مع التشخيص ودمج قاعدة الأكواد المحلية مع التحليل السياقي.
- دليل أكواد OBD، تقارير PDF، مشاركة، وإشعارات صيانة محلية.
- اشتراكات عبر Moyasar وسوق قطع غيار وسلة وطلبات وتقييم بائعين.
- واجهة عربية وإنجليزية ووضع فاتح/داكن.

> تشخيص التطبيق أولي وتوجيهي ولا يغني عن الفحص الفني المعتمد، خصوصًا في حالات السلامة.

## المتطلبات

### Backend

- Node.js 18 أو أحدث.
- مشروع Firebase وصلاحية Service Account.
- مفتاح Gemini API، أو Anthropic عند اختيار المزود Legacy.
- حساب Moyasar عند اختبار الدفع.

### Flutter

- Flutter بإصدار يدعم Dart `>=3.0.0 <4.0.0`.
- Android Studio وAndroid SDK وJDK 17 لتشغيل Android.
- جهاز Android أو Emulator. الاتصال بـOBD يعمل على Android ولا يعمل في الويب.

## متغيرات البيئة

انسخ `backend/.env.example` إلى `backend/.env` وأدخل القيم محليًا فقط:

```dotenv
AI_PROVIDER=gemini
AI_MODEL=gemini-3.7-flash
GEMINI_API_KEY=
ANTHROPIC_API_KEY=
FIREBASE_SERVICE_ACCOUNT=
MOYASAR_SECRET_KEY=
ADMIN_SECRET=
PORT=3000
ALLOWED_ORIGINS=https://yassir-9.github.io,http://localhost:8080
```

- `AI_PROVIDER`: القيمة الافتراضية `gemini`، ويمكن ضبطها على `anthropic` مؤقتًا.
- `AI_MODEL`: اسم النموذج دون تعديل Routes أو Flutter. الافتراضي في الكود `gemini-3.7-flash` عند عدم ضبطه (ويُستخدم الاسم نفسه مع `AI_PROVIDER=anthropic` إن ضُبط، والافتراضي هناك `claude-sonnet-4-6`).
- النموذج الاحتياطي لـ Gemini ثابت في `backend/services/ai/geminiProvider.js` وهو `gemini-3.6-flash`، ويُستخدم فقط بعد أول خطأ مؤقت (429 أو 5xx) من النموذج الأساسي.
- تنبيه: النماذج `gemini-2.5-*` مصنّفة Deprecated في توثيق Google وتتحول طلباتها تلقائيًا إلى نماذج أخرى ابتداءً من 1 ديسمبر 2026، فلا تستخدمها. تحقق من القائمة الحالية في https://aistudio.google.com/docs/models قبل تغيير الاسم.
- `GEMINI_ATTEMPT_TIMEOUT_MS` (افتراضي 25000): مهلة كل محاولة. `GEMINI_TOTAL_TIMEOUT_MS` (افتراضي 45000): السقف الإجمالي لطلب Gemini شاملًا إعادة المحاولة. `GEMINI_RETRY_BASE_MS` (افتراضي 1500): أساس التأخير التصاعدي (يُضاعف في كل محاولة وبحد أقصى 8 ثوانٍ).
- `FREE_MONTHLY_LIMIT` (افتراضي 7)، و`SUBSCRIPTIONS_ENABLED` و`MARKETPLACE_ENABLED` (قراءة السوق العامة `GET /api/parts`) و`MARKETPLACE_WRITES_ENABLED` و`ASK_EXPERT_ENABLED` (الافتراضي معطّل؛ `true` للتفعيل).
- `FREE_MONTHLY_BEFORE_YOU_PAY` (افتراضي 7): الحد الشهري المجاني لمراجعة عروض الورش (`/repair-review` و`/before-you-pay`)، بعدّاد منفصل عن التشخيصات. يُقرأ عند كل طلب؛ تغييره من Render لا يحتاج نشر كود جديد.
- دليل القطع (زر «ابحث عن القطعة»): `PARTS_GUIDE_ENABLED` (افتراضي معطّل؛ `true` لتشغيل `/go/*`، ومعطّلاً يعيد 404 فيفتح التطبيق بحث Google العام). قائمة المتاجر المسموحة في `backend/config/partnerStores.js` (Speero وبحث Google المحصور بموقعه مفعّلان؛ Odiggo وNoon وAmazon.sa جاهزة ومعطّلة بلا صيغة بحث). `PARTNER_STORES_ENABLED` (مفاتيح مفصولة بفواصل) يغيّر المفعّل. معرّفات الشراكة: `AFFILIATE_SPEERO` و`AFFILIATE_ODIGGO` و`AFFILIATE_NOON` و`AFFILIATE_AMAZON`، وقيمة كل منها جزء الاستعلام الذي يعطيه برنامج الشراكة مثل `ref=abc123` (فارغة افتراضياً = رابط عادي). `EXTERNAL_PART_SEARCH_ENABLED` (افتراضي معطّل) يتحكم بمساري البحث بالذكاء الاصطناعي `/parts/external-search` و`/obd/part-search`. `DIAGNOSIS_FEEDBACK_ENABLED` (افتراضي معطّل) يتحكم بمسار `PATCH /history/:id/feedback` (لا شاشة حية تستدعيه).
- `GEMINI_API_KEY`: مطلوب عند استخدام Gemini.
- `ANTHROPIC_API_KEY`: مطلوب فقط عند اختيار Anthropic.

- `FIREBASE_SERVICE_ACCOUNT`: كائن JSON كامل في سطر واحد. لا تحفظه كملف داخل المشروع.
- `ALLOWED_ORIGINS`: قائمة Origins مفصولة بفواصل. GitHub Pages وOrigins التطوير المحلي الشائعة مسموحة افتراضيًا.
- endpoint الإدارة يقبل السر في header باسم `x-admin-secret` فقط، وليس في Query String.

ملف `.env` وملفات المفاتيح والشهادات مستثناة من Git. لا تضع أي مفتاح في Flutter أو في مستودع Git.

## تشغيل Backend

```bash
cd backend
npm install
npm start
```

المنفذ الافتراضي هو `3000`. يفشل التشغيل برسالة واضحة إذا كان `FIREBASE_SERVICE_ACCOUNT` مفقودًا أو غير صالح.

للتطوير مع إعادة التشغيل التلقائي:

```bash
npm run dev
```

## إعداد عنوان API في Flutter

عنوان Production الافتراضي يبقى:

```text
https://car-ai-backend-7gpb.onrender.com
```

جميع الاستدعاءات تستخدم `frontend/lib/config/api_config.dart`. يمكن تغيير العنوان وقت التشغيل أو البناء باستخدام `API_BASE_URL` دون تعديل ملفات الشاشات.

### Android Emulator مع Backend محلي

```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

### Web محلي مع Backend محلي

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

### Production

```bash
cd frontend
flutter pub get
flutter run
```

عدم تمرير `API_BASE_URL` يحافظ على عنوان Production الحالي.

## مسار OBD والتشخيص

1. يقترن المستخدم بجهاز ELM327 من إعدادات Android.
2. يتصل به من شاشة OBD ويجري Scan.
3. تُحفظ الأكواد المقروءة فعليًا في جلسة التطبيق.
4. عند بدء التشخيص تُرسل الأكواد غير الفارغة في `obd_codes` مع الأعراض والسيارة والصورة الاختيارية.
5. يستخدم Backend تعريف الكود والخطورة والأسباب من `obd_codes.json` كمرجع ملزم، ويستخدم Claude للسياق والفحوصات والقطع والخطوة التالية.

لا تُنشأ أو تُرسل أكواد افتراضية عند عدم وجود نتيجة Scan.

## الدفع والأمان

- لا يمنح callback الخاص بالفاتورة اشتراكًا أو حالة دفع اعتمادًا على body الوارد وحده.
- يعيد Backend جلب الفاتورة من Moyasar باستخدام Secret الخادمي، ثم يتحقق من الحالة والمبلغ والعملة ومعرّف الفاتورة والسجل المحلي.
- أسرار الإدارة وFirebase وMoyasar وAnthropic تبقى في متغيرات البيئة.
- يسجل Backend request ID والمسار والحالة والمدة، مع حجب الحقول الحساسة وعدم تسجيل body أو headers.

## اختبارات Backend

لا تستدعي الاختبارات أي API مدفوع أو Firebase Production:

```bash
cd backend
npm test
```

تشمل اختيار مزود AI، التحقق من مخطط JSON، إثراء OBD، عزل Cache، تحقق Moyasar باستخدام mock، وحراس المصادقة.

## ملاحظات المنصات

- Firebase مهيأ حاليًا لـAndroid والويب.
- لا توجد منصة iOS ضمن المصدر الحالي.
- Bluetooth Classic وقراءة OBD خاصان بـAndroid؛ بقية الواجهة تدعم الويب بحسب دعم الحزم المستخدمة.
- ملف Android Release الحالي يستخدم توقيع Debug ويجب إعداد توقيع Release حقيقي قبل النشر الرسمي.
