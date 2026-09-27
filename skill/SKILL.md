---
name: arabic-bidi-engineering
description: Mandatory whenever writing ANY Arabic text — chat replies, Markdown, docs, UI strings, code comments — and when generating or processing Arabic/RTL/BiDi content in Word (.docx), Excel (.xlsx), PDF, HTML/CSS/Tailwind, email, or backend code.
---

# Arabic & BiDi Engineering Guide

## 0. Always-apply: Arabic Chat & Markdown Replies

When communicating in Arabic or generating Markdown containing Arabic, these rules are **mandatory**:

1. **Native Punctuation**: Use Arabic punctuation ONLY inside Arabic prose: `،` `؛` `؟` (never `,` `;` `?` inside Arabic sentences).
2. **Quotations**: Use `«` and `»` for Arabic quotes, terms, or book titles.
3. **English & Code Isolation**: Every English term, code snippet, file path, URL, version tag, and terminal command MUST be wrapped in backticks (e.g. `\`code\``). This isolates the token as an inline LTR block, preventing brackets, dots, and slashes from flipping.
4. **No Invisible BiDi Controls in Chat**: Never insert invisible RLM/LRM (`U+200F` / `U+200E`) or directional formatting marks in chat text or Markdown — they corrupt copy/paste, terminal rendering, and code execution. Use them *only* in compiled documents (PDF canvas, Word XML).
5. **Paragraph Direction Anchor**: Avoid starting a line or bullet point with a Latin word or number. In many Markdown renderers, the first strong character determines paragraph direction.
6. **Western Digits by Default**: Use Western digits (`0-9`) by default in technical documentation and chat text unless explicitly asked otherwise.
7. **Strict LTR for Code Blocks**: Multi-line code blocks (```...```) MUST always be strictly LTR and left-aligned. Code comments inside code blocks should be English to avoid BiDi inversion of brackets (`{}`, `[]`), semicolons, and indentation. In chat/Markdown, never wrap code blocks inside `<div dir="rtl">`; keep code blocks strictly in their natural LTR direction.
8. **Standalone Paths & LTR List Items**: Never place bare file paths, URLs, or commands as naked RTL bullet points (e.g. `- \`~/.path\`` inside an RTL container), as this flips the leading tilde/slashes and forces unnatural right-alignment. Either:
   - Anchor the bullet point with Arabic text first (e.g. `- مسار الوكلاء: \`~/.agents/...\``).
   - Or isolate the list in a dedicated LTR block (`<div dir="ltr">` or code block) so the bullet points and paths are naturally left-aligned (`text-align: left;`).

**Example:**
- ❌ **Bad:** لا تقم بتشغيل (server) الآن, انتظر لـ v1.2?
- ✅ **Good:** لا تقم بتشغيل `(server)` الآن، انتظر لـ `v1.2`؟

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

### Table Cells Alignment Rule (إلزامية محاذاة نصوص الجداول نحو اليمين)
In all table implementations across all platforms (HTML/CSS, Word .docx, Excel .xlsx, PDF):
1. **Arabic Text, Prose & Descriptions**: ALL textual headers (`th`), item names, descriptions, and narrative cells MUST be strictly **aligned to the right** (`text-align: right` / `text-start`, `<w:jc w:val="right"/>`, `Alignment(horizontal='right')`). Centering or left-aligning Arabic prose, descriptions, or names inside table cells is strictly forbidden.
2. **Numeric & Metric Cells**: Only quantitative metrics (IDs, counts, percentages, status badges, serial numbers) may be centered (`text-center` / `align_center`) or aligned to the end for financial amounts (`text-end`).
3. **Codes, URLs & LTR Data**: Technical codes, IBANs, phone numbers, and URLs inside table cells must be isolated and left-aligned (`text-start` with `dir="ltr"` or `text-left`).

## 3. Digits & Dates Policy
- **Digits**: Use Western digits (`0-9`) by default in technical docs, code comments, and chat. Use Arabic-Indic digits (`٠-٩`) only when a specific regional locale or client standard explicitly requires them.
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
- [ ] **Validator**: Run `python3 scripts/check_arabic_text.py <file>` to detect punctuation or direction anomalies.
- [ ] **Chat/Markdown**: Follows Section 0 (backticks on code/Latin, native `،` `؛` `؟`, no invisible bidi marks).
- [ ] **Word (.docx)**: Section has `<w:bidi/>`, `Normal` style has `<w:bidi/>` + `<w:jc w:val="right"/>`, tables have `<w:bidiVisual/>`, and cells have right alignment.
- [ ] **Word (.docx)**: English words and bracketed expressions are wrapped in isolated LTR runs (`w:rtl val="0"`).
- [ ] **Excel (.xlsx)**: Worksheets have `ws.sheet_view.rightToLeft = True` (with `ws.views.sheetView[0]` guarded), and columns auto-fitted with the 1.2x Arabic factor.
- [ ] **PDF/HTML**: Root has `<html lang="ar" dir="rtl">`, code blocks use `unicode-bidi: isolate;`, and layout uses CSS logical properties.
- [ ] **Tables (All Formats)**: Text headers (`th`), descriptions, and narrative Arabic cells are explicitly right-aligned (never centered or left-aligned).
- [ ] **Email**: Explicit `dir="rtl"` and `align="right"` attributes on `<table>` and `<td>` tags.
