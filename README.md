<div dir="rtl" align="right">

# مشروع مهارة هندسة اللغة العربية `arabic-bidi-engineering`

مهارة لوكلاء الذكاء الاصطناعي تجعلهم يكتبون العربية وينسقونها بشكل صحيح في المحادثة وفي المستندات والواجهات: الترقيم العربي، وعزل المصطلحات الإنجليزية، والاتجاه من اليمين لليسار في ملفات `Word` و`Excel` و`PDF` و`HTML`.

## التثبيت

### الطريقة الموصى بها عبر أداة `skills` التفاعلية

شغّل الأمر التالي في الطرفية، وستظهر لك قوائم تفاعلية لاختيار الوكلاء، ونطاق التثبيت (المشروع الحالي أو كل المشاريع)، وطريقة التثبيت (ربط رمزي أو نسخ):

</div>

```bash
npx skills add MosaabGalmod/arabic-bidi-engineering
```

<div dir="rtl" align="right">

للتثبيت العام دون أسئلة لكل الوكلاء المكتشفة:

</div>

```bash
npx skills add MosaabGalmod/arabic-bidi-engineering -g -y
```

<div dir="rtl" align="right">

وللتحديث لاحقاً إلى آخر إصدار:

</div>

```bash
npx skills update
```

<div dir="rtl" align="right">

### تطبيق `Antigravity`

المهارة وحدها لا تكفي لـ `Antigravity`؛ فأداة `skills` (الإصدار <code dir="ltr">1.7.0</code>) تضع مهارات `Antigravity` العامة في
<code dir="ltr">~/.agents/skills/</code>
وهو مجلد لا يقرأه `Antigravity`، كما يحتاج الوكيل إلى وجود المهارة في مجلده العام المعتمد
<code dir="ltr">~/.gemini/config/skills/</code>
(ومجلد التوافق <code dir="ltr">~/.gemini/antigravity/skills/</code>)
وإلى قاعدة دائمة في
<code dir="ltr">~/.gemini/GEMINI.md</code>
لضمان تفعيلها دائماً في كل محادثة حتى على أجهزة التثبيت الجديدة.
السكريبت أدناه يقوم بالتثبيت والنسخ التلقائي وإضافة القاعدة في أمر واحد وهو آمن للتشغيل المتكرر.

</div>

```powershell
# Windows
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MosaabGalmod/arabic-bidi-engineering/main/install/antigravity.ps1)))
```

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/MosaabGalmod/arabic-bidi-engineering/main/install/antigravity.sh | bash
```

<div dir="rtl" align="right">

ولإلغاء التثبيت وحذف مجلد المهارة والقاعدة الدائمة، شغّل أمر الإلغاء لنظامك:

</div>

```powershell
# Windows
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MosaabGalmod/arabic-bidi-engineering/main/install/antigravity.ps1))) -Uninstall
```

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/MosaabGalmod/arabic-bidi-engineering/main/install/antigravity.sh | bash -s -- --uninstall
```

<div dir="rtl" align="right">

أو مباشرةً عبر أداة `skills` فقط (دون إضافة القاعدة الدائمة ودون النسخ إلى مجلد `Antigravity`):

</div>

```bash
npx skills add MosaabGalmod/arabic-bidi-engineering -g -a antigravity --copy -y
```

<div dir="rtl" align="right">

**ملاحظة:** لتحديث المهارة لاحقاً لـ `Antigravity`، أعد تشغيل أمر التثبيت أعلاه (فهو يجدد نسخة مجلد `Antigravity`).

### التثبيت اليدوي

انسخ المستودع إلى جهازك:

</div>

```bash
git clone https://github.com/MosaabGalmod/arabic-bidi-engineering.git
```

<div dir="rtl" align="right">

ثم اربط مجلد <code dir="ltr">skill/</code> بمجلد المهارات لدى وكيلك. مثال لـ `Claude Code`:

</div>

```bash
ln -s "$PWD/arabic-bidi-engineering/skill" ~/.claude/skills/arabic-bidi-engineering
```

<div dir="rtl" align="right">

وللوكلاء الأخرى مثل `Cursor` و`Codex` و`Gemini` راجع ملف `skill/README.md`.

## هيكل المشروع

| المجلد أو الملف | المحتوى |
| --- | --- |
| <code dir="ltr">skill/</code> | الإصدار الحالي القابل للتثبيت <code dir="ltr">(v2.1.0)</code>، وهو المجلد الذي ترتبط به كل الوكلاء |
| `skill/SKILL.md` | الملف الأساسي: قواعد المحادثة، والقاعدة الجوهرية، وجدول التوجيه، وقائمة التحقق |
| <code dir="ltr">skill/references/</code> | التفاصيل التقنية لكل مجال: `Word` و`Excel` و`HTML/PDF` ومعالجة النصوص |
| `skill/scripts/check_arabic_text.py` | مدقق آلي لملفات `Markdown` و`HTML` و`Word` |
| <code dir="ltr">install/</code> | سكريبتا التثبيت التلقائي لـ `Antigravity`: <code dir="ltr">antigravity.ps1</code> لـ `Windows` و<code dir="ltr">antigravity.sh</code> لـ `Linux/macOS` |
| <code dir="ltr">versions/v1.0.0/</code> | الإصدار الأول الأصلي كما كان، محفوظ للرجوع إليه |
| `CHANGELOG.md` | سجل التغييرات بين الإصدارات |

## أين تعمل المهارة الآن

كل المسارات التالية روابط رمزية تشير إلى <code dir="ltr">skill/</code> في هذا المجلد، فأي تعديل هنا يصل لكل الوكلاء فوراً:

| الوكيل | المسار |
| --- | --- |
| Claude Code | <code dir="ltr">~/.claude/skills/arabic-bidi-engineering</code> |
| المسار المشترك للوكلاء | <code dir="ltr">~/.agents/skills/arabic-bidi-engineering</code> |
| Codex | <code dir="ltr">~/.codex/skills/arabic-bidi-engineering</code> |
| Gemini CLI | <code dir="ltr">~/.gemini/skills/arabic-bidi-engineering</code> |
| Antigravity | <code dir="ltr">~/.gemini/antigravity/skills/arabic-bidi-engineering</code> |
| Copilot CLI | <code dir="ltr">~/.copilot/skills/arabic-bidi-engineering</code> |

**تنبيه مهم:** لا تنقل هذا المجلد ولا تغيّر اسمه، فكل الروابط أعلاه تنكسر عندها.

## الاستخدام السريع

فحص ملف بالمدقق (يعيد رمز خروج 1 عند وجود مخالفات):

</div>

```bash
python3 ~/Desktop/arabic-bidi-engineering/skill/scripts/check_arabic_text.py report.md
```

<div dir="rtl" align="right">

الرجوع إلى الإصدار الأول عبر أمر `git` التالي:

</div>

```bash
git -C ~/Desktop/arabic-bidi-engineering show v1.0.0:SKILL.md
```

<div dir="rtl" align="right">

## المساهمة

البلاغات والاقتراحات مرحب بها عبر صفحة `Issues` في المستودع، وقبل إرسال أي تعديل شغّل المدقق على الملفات المعدلة.

## الترخيص

المشروع منشور بترخيص `MIT`، والتفاصيل في ملف `LICENSE`.

</div>
