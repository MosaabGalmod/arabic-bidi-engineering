---
name: arabic-bidi-engineering
description: Use when generating, formatting, or processing Arabic bidirectional (BiDi/RTL) documents across Word (.docx), Excel (.xlsx), PDF, HTML/CSS, and backend scripts
---

# Arabic & BiDi Engineering Guide (الدليل الهندسي الشامل لمعالجة وتنسيق اللغة العربية والاتجاه ثنائي الأبعاد)

## Overview & Scope
Handling Arabic and bidirectional (BiDi) text requires strict separation between **text flow direction** (`dir="rtl"`, `<w:bidi/>`, `ws.sheet_view.rightToLeft`) and **alignment** (`text-align: right/start`, `<w:jc w:val="right"/>`, `Alignment(horizontal='right')`). Treating one as a substitute for the other causes text displacement, inverted parentheses, broken tables, and left-stuck paragraphs when documents are opened across Microsoft Office, LibreOffice, browsers, and PDF engines.

This skill provides verified, production-tested patterns for:
1. Microsoft Word (.docx / OpenXML) Bidirectional & RTL Engineering.
2. Microsoft Excel (.xlsx / OpenPyXL) RTL Workbook & Formatting.
3. HTML/CSS & Headless Chrome PDF Rendering for RTL.
4. Python/PHP/JS Backend Tokenization, Normalization, & String Isolation.

---

## 1. Wordprocessing & OpenXML (.docx) RTL Engineering

### The Critical Core Rule: Direction vs Alignment
In OpenXML (ECMA-376) and Microsoft Word:
- `<w:bidi/>` (or `<w:bidi w:val="1"/>`) sets the **BiDi reading order** (cursor movement, punctuation placement, Arabic complex script shaping).
- `<w:jc w:val="right"/>` sets the **horizontal paragraph alignment**.
- **Crucial Word Trap:** In Microsoft Word, setting `<w:bidi/>` **WITHOUT** setting `<w:jc w:val="right"/>` causes the paragraph to inherit `Normal` style's alignment (which defaults to `left`). As a result, Arabic text sits against the **left margin** of the page or table cell.
- **Rule:** Every RTL paragraph and table cell MUST have **both** `<w:bidi/>` and explicit `<w:jc w:val="right"/>` (or `center` for titles/metrics).

### Full Architecture for `python-docx`
When constructing `.docx` reports via `python-docx` or raw OpenXML:

```python
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import qn, nsdecls

class BiDiDocxBuilder:
    def __init__(self):
        self.doc = Document()
        self._setup_rtl_environment()

    def _setup_rtl_environment(self) -> None:
        """Configures document-level, section-level, and style-level RTL defaults."""
        # 1. Section-level RTL (margins, header/footer, column flow)
        for section in self.doc.sections:
            sectPr = section._sectPr
            if sectPr.find(qn('w:bidi')) is None:
                sectPr.append(parse_xml(f'<w:bidi {nsdecls("w")}/>'))

        # 2. Normal style RTL + Right Alignment
        style = self.doc.styles['Normal']
        style.font.name = 'Calibri'
        style.font.size = Pt(11)
        style.font.color.rgb = RGBColor(30, 41, 59)
        style.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        pPr = style._element.get_or_add_pPr()
        if pPr.find(qn('w:bidi')) is None:
            pPr.append(parse_xml(f'<w:bidi {nsdecls("w")}/>'))
        if pPr.find(qn('w:jc')) is None:
            pPr.append(parse_xml(f'<w:jc {nsdecls("w")} w:val="right"/>'))

        # 3. Document-level Defaults (pPrDefault & rPrDefault) in styles.xml
        pPrDefault = self.doc.styles.element.xpath('//w:pPrDefault')
        if pPrDefault:
            pPr_def = pPrDefault[0].find(qn('w:pPr'))
            if pPr_def is not None:
                if pPr_def.find(qn('w:bidi')) is None:
                    pPr_def.append(parse_xml(f'<w:bidi {nsdecls("w")}/>'))
                if pPr_def.find(qn('w:jc')) is None:
                    pPr_def.append(parse_xml(f'<w:jc {nsdecls("w")} w:val="right"/>'))

        rPrDefault = self.doc.styles.element.xpath('//w:rPrDefault')
        if rPrDefault:
            rPr_def = rPrDefault[0].find(qn('w:rPr'))
            if rPr_def is not None:
                lang = rPr_def.find(qn('w:lang'))
                if lang is not None:
                    lang.set(qn('w:bidi'), 'ar-SA')
                else:
                    rPr_def.append(parse_xml(f'<w:lang {nsdecls("w")} w:val="ar-SA" w:bidi="ar-SA"/>'))

    def set_paragraph_rtl(self, paragraph, align: WD_ALIGN_PARAGRAPH = WD_ALIGN_PARAGRAPH.RIGHT) -> None:
        """Enforces both RTL reading order and explicit margin alignment."""
        pPr = paragraph._p.get_or_add_pPr()
        if pPr.find(qn('w:bidi')) is None:
            pPr.append(OxmlElement('w:bidi'))
        paragraph.alignment = align

    def set_table_rtl(self, table) -> None:
        """Enforces RTL table column ordering (w:bidiVisual) and executive styling."""
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        tblPr = table._tbl.tblPr
        
        # w:bidiVisual is MANDATORY so Column 0 renders on the far right
        if tblPr.find(qn('w:bidiVisual')) is None:
            tblPr.append(OxmlElement('w:bidiVisual'))
            
        # Subtle executive borders
        if tblPr.find(qn('w:tblBorders')) is None:
            tblPr.append(parse_xml(
                f'<w:tblBorders {nsdecls("w")}>'
                f'  <w:top w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>'
                f'  <w:left w:val="none"/>'
                f'  <w:bottom w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>'
                f'  <w:right w:val="none"/>'
                f'  <w:insideH w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
                f'  <w:insideV w:val="none"/>'
                f'</w:tblBorders>'
            ))
            
        # Comfortable internal cell padding
        if tblPr.find(qn('w:tblCellMar')) is None:
            tblPr.append(parse_xml(
                f'<w:tblCellMar {nsdecls("w")}>'
                f'  <w:top w:w="120" w:type="dxa"/>'
                f'  <w:bottom w:w="120" w:type="dxa"/>'
                f'  <w:left w:w="160" w:type="dxa"/>'
                f'  <w:right w:w="160" w:type="dxa"/>'
                f'</w:tblCellMar>'
            ))

    def add_arabic_run(self, paragraph, text: str, bold: bool = False, color=None, size_pt: float = None):
        """Adds a run with explicit Arabic Complex Script (w:cs) and language tagging."""
        run = paragraph.add_run(text)
        run.bold = bold
        if color:
            run.font.color.rgb = color
        if size_pt:
            run.font.size = Pt(size_pt)
            
        run.font.name = 'Calibri'
        rPr = run._r.get_or_add_rPr()
        
        # Complex Script font declaration
        rFonts = rPr.find(qn('w:rFonts'))
        if rFonts is not None:
            rFonts.set(qn('w:ascii'), 'Calibri')
            rFonts.set(qn('w:hAnsi'), 'Calibri')
            rFonts.set(qn('w:cs'), 'Calibri')
        else:
            rPr.append(parse_xml(f'<w:rFonts {nsdecls("w")} w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>'))
            
        # Direction & Language
        rPr.append(parse_xml(f'<w:rtl {nsdecls("w")} w:val="1"/>'))
        rPr.append(parse_xml(f'<w:lang {nsdecls("w")} w:bidi="ar-SA"/>'))
        return run

    def add_isolated_ltr_run(self, paragraph, text: str, is_code: bool = False, bold: bool = False, color=None, size_pt: float = None):
        """Adds an English/Code run isolated from the surrounding Arabic BiDi stream."""
        run = paragraph.add_run(text)
        run.bold = bold
        if color:
            run.font.color.rgb = color
        if size_pt:
            run.font.size = Pt(size_pt)
            
        run.font.name = 'Consolas' if is_code else 'Calibri'
        rPr = run._r.get_or_add_rPr()
        # Explicit LTR run (w:rtl val="0") prevents parenthesis inversion
        rPr.append(parse_xml(f'<w:rtl {nsdecls("w")} w:val="0"/>'))
        rPr.append(parse_xml(f'<w:lang {nsdecls("w")} w:val="en-US"/>'))
        return run
```

### Mixed Text Tokenization (Preventing Parenthesis & Punctuation Inversion)
When English terms (e.g., `(Meta Description)` or `sitemap.xml`) appear inside Arabic paragraphs, naive concatenation causes brackets and trailing dots to invert.
Split sentences into isolated tokens:

```python
import re

def add_mixed_arabic_english(builder: BiDiDocxBuilder, paragraph, text: str) -> None:
    """Splits text on English words/URLs/tags and outputs isolated runs."""
    # Split on continuous ASCII/English tokens while keeping punctuation attached to Arabic
    tokens = re.split(r'([a-zA-Z0-9_\-\.\:\/\<\>\=\"]{2,})', str(text))
    for token in tokens:
        if not token:
            continue
        is_eng = bool(re.match(r'^[a-zA-Z0-9_\-\.\:\/\<\>\=\"]+$', token))
        is_code = bool(re.search(r'[\/\<\>\=\_]', token))
        if is_eng:
            builder.add_isolated_ltr_run(paragraph, token, is_code=is_code)
        else:
            builder.add_arabic_run(paragraph, token)
```

---

## 2. Spreadsheet & OpenPyXL (.xlsx) RTL Engineering

### Workbook & Worksheet RTL Direction
In OpenPyXL, setting RTL requires targeting both `ws.sheet_view` and `ws.views.sheetView[0]`:

```python
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

def create_rtl_excel_workbook():
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "الملخص التنفيذي"
    
    # 1. Enable RTL at the worksheet level (Column A starts on the top right)
    ws.sheet_view.rightToLeft = True
    if hasattr(ws, 'views') and ws.views.sheetView:
        ws.views.sheetView[0].rightToLeft = True
        
    # 2. Freeze header row
    ws.freeze_panes = 'A2'
    return wb, ws

def style_rtl_worksheet(ws):
    """Applies royal navy headers, zebra rows, Arabic fonts, and right-alignment."""
    header_font = Font(name='Calibri', size=11, bold=True, color='FFFFFF')
    header_fill = PatternFill(start_color='1E3A8A', end_color='1E3A8A', fill_type='solid') # Royal Deep Blue
    
    data_font = Font(name='Calibri', size=10, color='1E293B')
    bold_data_font = Font(name='Calibri', size=10, bold=True, color='1E293B')
    zebra_fill = PatternFill(start_color='F8FAFC', end_color='F8FAFC', fill_type='solid')
    
    # Alignments
    align_right = Alignment(horizontal='right', vertical='center', wrap_text=True)
    align_center = Alignment(horizontal='center', vertical='center')
    
    # Borders
    thin_border = Border(
        left=Side(style='thin', color='CBD5E1'),
        right=Side(style='thin', color='CBD5E1'),
        top=Side(style='thin', color='CBD5E1'),
        bottom=Side(style='thin', color='CBD5E1')
    )
    
    # Style rows
    for row_idx, row in enumerate(ws.iter_rows(), start=1):
        if row_idx == 1:
            ws.row_dimensions[row_idx].height = 28
            for cell in row:
                cell.font = header_font
                cell.fill = header_fill
                cell.alignment = align_center
                cell.border = thin_border
        else:
            ws.row_dimensions[row_idx].height = 24
            is_even = (row_idx % 2 == 0)
            for col_idx, cell in enumerate(row, start=1):
                cell.font = data_font
                cell.border = thin_border
                if is_even:
                    cell.fill = zebra_fill
                
                # Center short badge/metric values, percentages and numbers; right-align Arabic narrative text
                val_str = str(cell.value or '').strip()
                if val_str.endswith('%') or val_str.isdigit() or (len(val_str) <= 12 and ' ' not in val_str):
                    cell.alignment = align_center
                else:
                    cell.alignment = align_right

    # 3. Auto-fit column widths considering multi-byte Arabic character widths
    for col in ws.columns:
        max_len = 0
        col_letter = get_column_letter(col[0].column)
        for cell in col:
            if cell.value:
                # Arabic characters typically take slightly more horizontal space
                length = len(str(cell.value))
                if length > max_len:
                    max_len = length
        ws.column_dimensions[col_letter].width = min(max(max_len + 4, 14), 60)
```

---

## 3. HTML, CSS & Headless Chrome PDF Rendering

### HTML Document Level
```html
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>التقرير التشخيصي</title>
  <style>
    /* 1. Global Typography */
    body {
      font-family: 'IBM Plex Sans Arabic', 'Tajawal', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      direction: rtl;
      text-align: right;
      line-height: 1.6;
      color: #1e293b;
    }

    /* 2. CSS Logical Properties */
    .card {
      margin-inline-start: 1rem;
      padding-inline-end: 1.5rem;
      border-inline-start: 4px solid #1e3a8a;
    }

    /* 3. Code & English Isolation inside Arabic */
    code, pre, .font-mono {
      direction: ltr;
      text-align: left;
      unicode-bidi: isolate;
      font-family: 'Consolas', 'Fira Code', monospace;
    }

    /* 4. Headless Chrome PDF Print Rules */
    @page {
      size: A4;
      margin: 15mm 15mm 20mm 15mm;
      @bottom-center {
        content: counter(page) " / " counter(pages);
        font-family: 'Calibri', sans-serif;
        font-size: 9pt;
      }
    }

    @media print {
      body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .page-break { page-break-before: always; }
      .avoid-break { break-inside: avoid; page-break-inside: avoid; }
      tr { break-inside: avoid; page-break-inside: avoid; }
    }
  </style>
</head>
<body>
  <h1>عنوان المستند أو التقرير العربي</h1>
  <p>
    هذه فقرة توضيحية باللغة العربية تحتوي على مسار تقني <bdi>https://example.com/api/v1</bdi> مع كود استجابة <bdi>200 OK</bdi> معزولين بدقة.
  </p>
</body>
</html>
```

### Headless Chrome PDF Generation Command (Linux / CI)
```bash
google-chrome --headless=new --disable-gpu --no-sandbox \
  --print-to-pdf=/path/to/report.pdf \
  --run-all-compositor-stages-before-draw \
  --no-pdf-header-footer \
  file:///path/to/report.html
```

---

## 4. Backend String Normalization & Clean Filenames

### Unicode Normalization (Python)
Unify Arabic characters, hamzas, and tashkeel before indexing or comparison:
```python
import unicodedata
import re

def normalize_arabic_text(text: str) -> str:
    """Normalizes Arabic text to consistent NFKC unicode form."""
    if not text:
        return ""
    text = unicodedata.normalize('NFKC', str(text))
    # Remove Arabic diacritics (Tashkeel)
    text = re.sub(r'[\u064B-\u065F\u0670]', '', text)
    return text.strip()
```

### Arabic Search Normalization
Normalizes Arabic letters for robust search indexing and fuzzy matching:
```python
def normalize_arabic_for_search(text: str) -> str:
    """Normalizes Arabic letters for robust search indexing and matching."""
    if not text:
        return ""
    text = unicodedata.normalize('NFKC', text)
    # Remove Tashkeel (diacritics) & Tatweel (kashida)
    text = re.sub(r'[\u064B-\u065F\u0670\u0640]', '', text)
    # Unify Alef variations (أ, إ, آ, ٱ -> ا)
    text = re.sub(r'[إأآٱ]', 'ا', text)
    # Unify Taa Marbuta (ة -> ه)
    text = re.sub(r'ة', 'ه', text)
    # Unify Alef Maqsura / Yaa (ى -> ي)
    text = re.sub(r'ى', 'ي', text)
    return text.strip()
```

### Arabic Slugification & Safe Filesystem Names
Generating clean, cross-platform filenames and URL slugs from Arabic strings without mojibake or illegal characters:
```python
def slugify_arabic(text: str, max_length: int = 60, separator: str = '_') -> str:
    """Generates a clean URL/filename slug preserving Arabic unicode letters."""
    if not text:
        return ""
    text = unicodedata.normalize('NFKC', text)
    text = re.sub(r'[\u064B-\u065F\u0670\u0640]', '', text)
    text = re.sub(r'[^\w\u0600-\u06FF]+', separator, text)
    text = re.sub(rf'{re.escape(separator)}+', separator, text).strip(separator)
    return text[:max_length].rstrip(separator)
```

---

## 5. Arabic Punctuation, Digits & BiDi Control Marks (الترقيم والأرقام وعلامات التوجيه)

### Punctuation Marks in Arabic Typography
Always use native Arabic punctuation marks to ensure correct baseline alignment and font shaping:
- **Arabic Comma**: `،` (`U+060C`) instead of English `,`.
- **Arabic Semicolon**: `؛` (`U+061B`) instead of English `;`.
- **Arabic Question Mark**: `؟` (`U+061F`) instead of English `?`.
- **Arabic Quotations**: Use Guillemets `«` (`U+00AB`) and `»` (`U+00BB`) for distinguished Arabic quotations, or ensure quotes are inside isolated text runs.

### BiDi Control Characters (RLM & LRM)
When punctuation (like `:`, `-`, `/`, `(`, `)`) appears between an Arabic word and an English/code term, BiDi algorithms may place the punctuation on the wrong side. Use Unicode marks to anchor them explicitly:
- **RLM (Right-to-Left Mark `\u200F` / `&rlm;`)**: Forces neutral characters (parentheses, colons, slashes) to behave as part of the RTL flow.
- **LRM (Left-to-Right Mark `\u200E` / `&lrm;`)**: Prevents phone numbers (`+966 50...`), version numbers (`v1.2.0`), or paths from flipping inside RTL sentences.

```python
# Example: Ensuring a colon after an English word stays on the right in Arabic flow
RTL_MARK = "\u200F"
LTR_MARK = "\u200E"

# Pinning punctuation to Arabic flow:
text_with_colon = f"الرابط المطلوب {RTL_MARK}({url}){RTL_MARK}:"

# Pinning phone numbers or versions to LTR:
version_text = f"الإصدار الحالي: {LTR_MARK}v2.4.1{LTR_MARK}"
```

---

## Checklist for Every Arabic & BiDi Release
- [ ] **Word (.docx)**: Section has `<w:bidi/>`, `Normal` style has `<w:bidi/>` + `<w:jc w:val="right"/>`, all tables have `<w:bidiVisual/>`, and table cell paragraphs explicitly have `<w:jc w:val="right"/>`.
- [ ] **Word (.docx)**: English keywords, URLs, and code blocks have `<w:rtl w:val="0"/>` to prevent parenthesis/punctuation inversion.
- [ ] **Excel (.xlsx)**: Every sheet has `ws.sheet_view.rightToLeft = True` and auto-fitted columns.
- [ ] **PDF/HTML**: Root has `dir="rtl" lang="ar"`, code blocks are isolated with `direction: ltr; unicode-bidi: isolate;`, and `@media print` rules prevent table row breaks.
- [ ] **Typography**: Native Arabic punctuation (`،`, `؛`, `؟`) used consistently, and BiDi marks (`\u200F` / `\u200E`) applied to neutral symbols where needed.
