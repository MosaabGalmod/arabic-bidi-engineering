---
name: arabic-bidi-engineering
description: Mandatory whenever writing ANY Arabic text — chat replies, Markdown, docs, UI strings, code comments — and when generating or processing Arabic/RTL/BiDi content in Word (.docx), Excel (.xlsx), PDF, HTML/CSS/Tailwind, email, or backend code.
---

# Arabic & BiDi Engineering Guide

## 0. Always-apply: Arabic Chat & Markdown Replies

When communicating in Arabic or generating Markdown containing Arabic, these rules are **mandatory**:

1. **Native Punctuation**: Use Arabic punctuation ONLY inside Arabic prose: `،` `؛` `؟` (never `,` `;` `?` inside Arabic sentences).
2. **Quotations**: Use `«` and `»` for Arabic quotes, terms, or book titles.
3. **English & Code Isolation**: Every English term, identifier, code snippet, short file name, version tag, or short command mid-sentence MUST be wrapped in inline backticks (e.g. `\`code\``). When parentheses or brackets surround Latin text, the brackets MUST be included INSIDE the backticks (e.g. `\`(term)\``, NEVER `(\`term\`)`). Never place naked punctuation or dots directly touching English text without backtick isolation. (Note: For full file paths, terminal commands, or URLs at the end of an Arabic sentence or bullet, see Rule 8 for dedicated code block isolation).
4. **No Invisible BiDi Controls in Chat**: Never insert invisible RLM/LRM (`U+200F` / `U+200E`) or directional formatting marks in chat text or Markdown — they corrupt copy/paste, terminal rendering, and code execution. Use them *only* in compiled documents (PDF canvas, Word XML).
5. **Paragraph Direction Anchor**: Avoid starting a line or bullet point with a Latin word or number. In many Markdown renderers, the first strong character determines paragraph direction. In list-based renderers the first item of a bullet or numbered list decides the direction of the whole list, so the first item must begin with an Arabic word. Text inside inline backticks counts as a strong character for this decision, so a line or first list item must not begin with a code span. Numbers and punctuation are skipped, so the first letter after them decides — a leading number or symbol followed by a Latin term or code span still flips the line to LTR.
6. **Western Digits by Default**: Use Western digits `(0-9)` by default in technical documentation and chat text unless explicitly asked otherwise.
7. **Strict LTR & English Comments for Code Blocks**: Multi-line code blocks (```...```) MUST always be strictly LTR and left-aligned. The ban on Arabic applies to comments and explanatory text inside code blocks in chat and Markdown replies (comments inside code must be in English; Arabic prose explanations go outside the block as standard RTL paragraphs). Arabic string literals, UI text, translation values, and sample data inside real code (HTML, PHP, Python, JSON) are ALLOWED and expected. In chat/Markdown, never wrap code blocks inside `<div dir="rtl">`.
8. **File Paths & Commands Isolation**: Full file paths, terminal commands, and URLs MUST NEVER be appended inline at the end of Arabic sentences or bullet points (e.g. `مسار: ~/.path` is strictly forbidden because neutral colons `:` and leading symbols `~/` collide and render paths unreadable). Always place full paths and commands on a separate line as a dedicated LTR code block (```bash...```), ensuring 100% left-alignment, natural reading order, and clean one-click copying. Note: A short file name or identifier in backticks mid-sentence is fine; Markdown tables may also contain paths in backtick cells (inside an RTL HTML wrapper on GitHub, paths or code spans with neutral edges need `<code dir="ltr">` to prevent visual reordering).

**Example:**
- ❌ **خطأ (`Bad`):** لا تقم بتشغيل (server) الآن, انتظر لـ v1.2?
- ✅ **صحيح `(Good)`:** لا تقم بتشغيل `(server)` الآن، انتظر لـ `v1.2`؟

## 1. When NOT to Apply
Do NOT apply Arabic BiDi rules or translations to:
- Code identifiers, variable names, function signatures, and database schemas.
- Shell scripts, CLI commands, and flags.
- Git commit messages, branch names, and PR titles (unless the repository explicitly standardizes on Arabic commits).
- English-only documentation and configuration files.

## 2. Core Rule: Direction vs Alignment
Handling Arabic and bidirectional (BiDi) text requires strict separation between **text flow direction** and **alignment**:
- **Direction** (`dir="rtl"`, `<w:bidi/>`, `ws.sheet_view.rightToLeft`): Controls reading order, cursor behavior, punctuation attachment, and Arabic font shaping.
- **Alignment** (`text-align: right/start`, `<w:jc w:val="right"/>`, `Alignment(horizontal='right')`): Controls horizontal positioning relative to the margin.

**Rule:** Every RTL block (paragraph, table cell, or container) MUST have **both** an RTL direction explicitly declared **and** an explicit right alignment (or center for metrics/titles). Relying on one without the other causes layout displacement across Office, LibreOffice, and PDF engines.

### إلزامية محاذاة نصوص الجداول نحو اليمين `(Table Cells Alignment Rule)`
In all table implementations across all platforms (HTML/CSS, Word .docx, Excel .xlsx, PDF):
1. **Arabic Text, Prose & Descriptions**: ALL textual headers (`th`), item names, descriptions, and narrative cells MUST be strictly **aligned to the right** (`text-align: right` / `text-start`, `<w:jc w:val="right"/>`, `Alignment(horizontal='right')`). Centering or left-aligning Arabic prose, descriptions, or names inside table cells is strictly forbidden.
2. **Numeric & Metric Cells**: Only quantitative metrics (IDs, counts, percentages, status badges, serial numbers) may be centered (`text-center` / `align_center`) or aligned to the end for financial amounts (`text-end`).
3. **Codes, URLs & LTR Data**: Technical codes, IBANs, phone numbers, and URLs inside table cells must be isolated and left-aligned (`text-start` with `dir="ltr"` on the cell).

## 3. Digits & Dates Policy
- **Digits**: Use Western digits `(0-9)` by default in technical docs, code comments, and chat. Use Arabic-Indic digits `(٠-٩)` only when a specific regional locale or client standard explicitly requires them.
- **Hijri Dates**: Format Islamic dates using the Umm al-Qura calendar via the Intl API:
  `new Intl.DateTimeFormat('ar-SA-u-ca-islamic-umalqura', ...)`
- **Official Documents**: In formal reports and official documents, always pair the Hijri date with the Gregorian date (e.g., `1448/03/15 هـ (الموافق 2026/09/27 م)`).

## 4. Routing Table: Domain-Specific References
For deep technical patterns and complete code implementations, refer to the domain guides:

| Task / Domain | Reference File |
| :--- | :--- |
| **Word (.docx)** / OpenXML builder, tables, schema order | [references/docx.md](references/docx.md) |
| **Excel (.xlsx)** / OpenPyXL RTL sheets, styling, auto-fit | [references/xlsx.md](references/xlsx.md) |
| **Web & PDF** / HTML5 template, Chrome PDF, Tailwind, mPDF, ReportLab, Email | [references/html-pdf.md](references/html-pdf.md) |
| **Backend & Text** / Normalization, search indexing, slugify, JS Intl | [references/text-processing.md](references/text-processing.md) |
| **Document BiDi Marks** / RLM & LRM usage in generated documents | [references/text-processing.md#5-punctuation--bidi-control-marks-in-generated-documents](references/text-processing.md#5-punctuation--bidi-control-marks-in-generated-documents) |

## 5. Release Checklist
Before concluding any Arabic text, document generation, or UI task:
- [ ] **Validator**: Run `python3 scripts/check_arabic_text.py <file>` to detect punctuation, direction anomalies, naked Latin words (`[NAKED_LATIN]`), or LTR line starts (`[LATIN_LINE_START]`).
- [ ] **Chat/Markdown**: Follows Section 0 (backticks on code/Latin, native `،` `؛` `؟`, no invisible bidi marks).
- [ ] **Word (.docx)**: Section has `<w:bidi/>`, `Normal` style has `<w:bidi/>` + `<w:jc w:val="right"/>`, tables have `<w:bidiVisual/>`, and cells have right alignment.
- [ ] **Word (.docx)**: English words and bracketed expressions are wrapped in isolated LTR runs (`w:rtl val="0"`).
- [ ] **Excel (.xlsx)**: Worksheets have `ws.sheet_view.rightToLeft = True` (with `ws.views.sheetView[0]` guarded), and columns auto-fitted with the 1.2x Arabic factor.
- [ ] **PDF/HTML**: Root has `<html lang="ar" dir="rtl">`, code blocks use `unicode-bidi: isolate;`, and layout uses CSS logical properties.
- [ ] **Tables (All Formats)**: Text headers (`th`), descriptions, and narrative Arabic cells are explicitly right-aligned (never centered or left-aligned).
- [ ] **Email**: Explicit `dir="rtl"` and `align="right"` attributes on `<table>` and `<td>` tags.
