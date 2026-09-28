# Arabic BiDi Engineering Agent Skill

This is an Agent Skill designed for AI coding assistants. It enforces mandatory rules for generating, formatting, or processing Arabic bidirectional (BiDi/RTL) documents across Word (.docx), Excel (.xlsx), PDF, HTML/CSS, and backend scripts.

By loading this skill, AI agents learn to correctly handle Arabic text layout and styling without relying on naive translation or default LTR conventions, avoiding common issues like inverted punctuation or broken tables.

## Installation / Usage

### Recommended: Interactive Installation via `skills` CLI

Run the following command in your terminal, which provides interactive menus to select agents, installation scope (current project or global), and installation method (symlink or copy):

شغّل الأمر التالي في الطرفية، وستظهر لك قوائم تفاعلية لاختيار الوكلاء، ونطاق التثبيت (المشروع الحالي أو كل المشاريع)، وطريقة التثبيت (ربط رمزي أو نسخ):

```bash
npx skills add MosaabGalmod/arabic-bidi-engineering
```

For non-interactive global installation across all detected agents:

للتثبيت العام دون أسئلة لكل الوكلاء المكتشفة:

```bash
npx skills add MosaabGalmod/arabic-bidi-engineering -g -y
```

To update later to the latest version:

وللتحديث لاحقاً إلى آخر إصدار:

```bash
npx skills update
```

### Antigravity (one-command installer)

Antigravity loads global skills from its config folder (`~/.gemini/config/skills/`, mirrored also to `~/.gemini/antigravity/skills/` for compatibility) and needs a
permanent rule in `~/.gemini/GEMINI.md` to stay always-on across fresh installs.
Because the `skills` CLI (1.7.0) installs Antigravity global skills to `~/.agents/skills/` (which Antigravity does not read),
the scripts below run the installer and mirror the skill into Antigravity's folders automatically:

```powershell
# Windows
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MosaabGalmod/arabic-bidi-engineering/main/install/antigravity.ps1)))
```

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/MosaabGalmod/arabic-bidi-engineering/main/install/antigravity.sh | bash
```

To update the skill later, re-run the installer command above (it refreshes the Antigravity copy).

To uninstall (removes the Antigravity skill directory and the permanent rule):
- On Windows: `& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MosaabGalmod/arabic-bidi-engineering/main/install/antigravity.ps1))) -Uninstall`
- On Linux/macOS: `curl -fsSL https://raw.githubusercontent.com/MosaabGalmod/arabic-bidi-engineering/main/install/antigravity.sh | bash -s -- --uninstall`

### Manual Installation (Alternative)

Depending on your AI assistant, configure it to load `SKILL.md` from this directory.

بحسب وكيل الذكاء الاصطناعي المستخدم، قم بتهيئة تحميل ملف `SKILL.md` من هذا المجلد.

#### Claude Code
Add this directory to your Claude skills:

أضف هذا المجلد إلى مهارات `Claude Code`:

```bash
cp -r . ~/.claude/skills/arabic-bidi-engineering
```

#### Cursor
Create a rule in your `.cursor/rules` directory:

أنشئ قاعدة لمحرر `Cursor` داخل مجلد القواعد الخاص به عبر الأمر التالي:

```bash
cp SKILL.md .cursor/rules/arabic-bidi-engineering.mdc
```

#### Codex / Gemini
Reference the `SKILL.md` in your `AGENTS.md` or `GEMINI.md` system prompt guidelines, or include the contents directly in your project instructions.

أشر إلى ملف `SKILL.md` في إرشادات `AGENTS.md` أو `GEMINI.md` الخاصة بنظامك، أو ضمّن المحتوى مباشرة في تعليمات مشروعك.
