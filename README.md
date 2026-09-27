# مشروع مهارة هندسة اللغة العربية `arabic-bidi-engineering`

مهارة لوكلاء الذكاء الاصطناعي تجعلهم يكتبون العربية وينسقونها بشكل صحيح في المحادثة وفي المستندات والواجهات: الترقيم العربي، وعزل المصطلحات الإنجليزية، والاتجاه من اليمين لليسار في ملفات Word وExcel وPDF وHTML.

## التثبيت

### الطريقة الموصى بها عبر أداة `skills` التفاعلية

شغّل الأمر التالي في الطرفية، وستظهر لك قوائم تفاعلية لاختيار الوكلاء، ونطاق التثبيت (المشروع الحالي أو كل المشاريع)، وطريقة التثبيت (ربط رمزي أو نسخ):

```bash
npx skills add MosaabGalmod/arabic-bidi-engineering
```

للتثبيت العام دون أسئلة لكل الوكلاء المكتشفة:

```bash
npx skills add MosaabGalmod/arabic-bidi-engineering -g -y
```

وللتحديث لاحقاً إلى آخر إصدار:

```bash
npx skills update
```

### التثبيت اليدوي

انسخ المستودع إلى جهازك:

```bash
git clone https://github.com/MosaabGalmod/arabic-bidi-engineering.git
```

ثم اربط مجلد `skill/` بمجلد المهارات لدى وكيلك. مثال لـ `Claude Code`:

```bash
ln -s "$PWD/arabic-bidi-engineering/skill" ~/.claude/skills/arabic-bidi-engineering
```

وللوكلاء الأخرى مثل `Cursor` و`Codex` و`Gemini` راجع ملف `skill/README.md`.

## هيكل المشروع

| المجلد أو الملف | المحتوى |
| --- | --- |
| `skill/` | الإصدار الحالي القابل للتثبيت `(v2.1.0)`، وهو المجلد الذي ترتبط به كل الوكلاء |
| `skill/SKILL.md` | الملف الأساسي: قواعد المحادثة، والقاعدة الجوهرية، وجدول التوجيه، وقائمة التحقق |
| `skill/references/` | التفاصيل التقنية لكل مجال: Word وExcel وHTML/PDF ومعالجة النصوص |
| `skill/scripts/check_arabic_text.py` | مدقق آلي لملفات Markdown وHTML وWord |
| `versions/v1.0.0/` | الإصدار الأول الأصلي كما كان، محفوظ للرجوع إليه |
| `CHANGELOG.md` | سجل التغييرات بين الإصدارات |

## أين تعمل المهارة الآن

كل المسارات التالية روابط رمزية تشير إلى `skill/` في هذا المجلد، فأي تعديل هنا يصل لكل الوكلاء فوراً:

| الوكيل | المسار |
| --- | --- |
| Claude Code | `~/.claude/skills/arabic-bidi-engineering` |
| المسار المشترك للوكلاء | `~/.agents/skills/arabic-bidi-engineering` |
| Codex | `~/.codex/skills/arabic-bidi-engineering` |
| Gemini CLI | `~/.gemini/skills/arabic-bidi-engineering` |
| Antigravity | `~/.gemini/antigravity/skills/arabic-bidi-engineering` |
| Copilot CLI | `~/.copilot/skills/arabic-bidi-engineering` |

**تنبيه مهم:** لا تنقل هذا المجلد ولا تغيّر اسمه، فكل الروابط أعلاه تنكسر عندها.

## الاستخدام السريع

فحص ملف بالمدقق (يعيد رمز خروج 1 عند وجود مخالفات):

```bash
python3 ~/Desktop/arabic-bidi-engineering/skill/scripts/check_arabic_text.py report.md
```

الرجوع إلى الإصدار الأول عبر أمر `git` التالي:

```bash
git -C ~/Desktop/arabic-bidi-engineering show v1.0.0:SKILL.md
```

## المساهمة

البلاغات والاقتراحات مرحب بها عبر صفحة `Issues` في المستودع، وقبل إرسال أي تعديل شغّل المدقق على الملفات المعدلة.

## الترخيص

المشروع منشور بترخيص `MIT`، والتفاصيل في ملف `LICENSE`.
