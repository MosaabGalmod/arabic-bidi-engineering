# HTML, CSS & PDF Rendering RTL Engineering

## 1. Full HTML5 & Print CSS Template
Always declare `<html lang="ar" dir="rtl">` on the root. For user-generated or dynamic content where language is mixed, use `dir="auto"`. Use `<bdi>` (Bi-Directional Isolation) for inline English URLs, code, or metrics.

> **Note on Page Numbers in Headless Chrome:** CSS `@page { @bottom-center { ... } }` margin boxes are **not supported** by Chromium / Headless Chrome. Use Puppeteer or Playwright's `displayHeaderFooter` API with a `footerTemplate` containing `dir="rtl"`. Dedicated print engines like WeasyPrint and PrinceXML support standard CSS margin boxes natively.

```html
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>التقرير التشخيصي</title>
  <style>
    /* 1. Global Arabic Typography */
    body {
      font-family: 'IBM Plex Sans Arabic', 'Tajawal', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      direction: rtl;
      text-align: right;
      line-height: 1.6;
      color: #1e293b;
    }

    /* 2. CSS Logical Properties (Independent of LTR/RTL) */
    .card {
      margin-inline-start: 1rem;
      padding-inline-end: 1.5rem;
      border-inline-start: 4px solid #1e3a8a;
    }

    /* 3. Code & English Isolation inside Arabic prose */
    code, pre, .font-mono {
      direction: ltr;
      text-align: start;
      unicode-bidi: isolate;
      font-family: 'Consolas', 'Fira Code', monospace;
    }

    /* 4. Table Arabic Alignment Rules */
    table {
      width: 100%;
      border-collapse: collapse;
      direction: rtl;
    }
    th, td {
      text-align: right; /* Mandatory: All Arabic headers and text cells strictly right-aligned */
      vertical-align: middle;
    }
    th.metric, td.metric {
      text-align: center; /* Quantitative metrics, counts, and status codes */
    }
    th.amount, td.amount {
      text-align: end; /* Financial totals and currencies */
      font-variant-numeric: tabular-nums;
    }
    th.code, td.code, th.ltr, td.ltr {
      direction: ltr;
      text-align: start; /* Codes, URLs & LTR Data: text-start with dir="ltr" */
    }

    /* 5. Print & PDF Pagination Rules */
    @page {
      size: A4;
      margin: 15mm 15mm 20mm 15mm;
    }

    @media print {
      body {
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
      }
      .page-break { page-break-before: always; }
      .avoid-break { break-inside: avoid; page-break-inside: avoid; }
      tr { break-inside: avoid; page-break-inside: avoid; }
    }
  </style>
</head>
<body>
  <h1>عنوان المستند أو التقرير العربي</h1>
  <div class="card">
    <p>
      هذه فقرة توضيحية باللغة العربية تحتوي على مسار تقني <bdi>https://example.com/api/v1</bdi> مع كود استجابة <bdi>200 OK</bdi> معزولين بدقة.
    </p>
  </div>
</body>
</html>
```

## 2. Headless Chrome PDF Generation Command (Linux / CI)
Run Chrome in new headless mode with background graphics and print margins enabled:

```bash
google-chrome --headless=new --disable-gpu --no-sandbox \
  --print-to-pdf=/path/to/report.pdf \
  --run-all-compositor-stages-before-draw \
  --no-pdf-header-footer \
  file:///path/to/report.html
```

### Page Numbers via Puppeteer / Playwright
To inject headers and footers with page numbering in Headless Chrome:

> **Important Font Caveat:** Puppeteer/Playwright header/footer templates run in an isolated browser shadow context and **cannot load page web fonts or external stylesheets**. You must either use an OS-installed font (e.g. `'Tahoma', 'Arial', sans-serif`) or inline a base64-encoded `@font-face` directly inside the template.

```javascript
await page.pdf({
  path: 'report.pdf',
  format: 'A4',
  printBackground: true,
  displayHeaderFooter: true,
  headerTemplate: '<div></div>',
  footerTemplate: `
    <div dir="rtl" style="font-family: 'Tahoma', 'Arial', sans-serif; font-size: 9pt; width: 100%; text-align: center; color: #64748b;">
      صفحة <span class="pageNumber"></span> من <span class="totalPages"></span>
    </div>
  `,
  margin: { top: '15mm', bottom: '20mm', left: '15mm', right: '15mm' }
});
```

## 3. Tailwind CSS: Direction Variants & Logical Utilities
- Use logical utilities instead of physical ones:
  - Margins: `ms-*` (margin-start), `me-*` (margin-end) instead of `ml-*`, `mr-*`.
  - Paddings: `ps-*` (padding-start), `pe-*` (padding-end) instead of `pl-*`, `pr-*`.
  - Position: `start-*`, `end-*` instead of `left-*`, `right-*`.
  - Alignment: `text-start`, `text-end` instead of `text-left`, `text-right`.
  - Borders: `border-s-*`, `border-e-*`, `rounded-s-*`, `rounded-e-*`.
  - Spacing / Layout: Use `gap-*` (direction-agnostic) instead of `space-x-*` / `space-x-reverse`.
- Use `rtl:` and `ltr:` modifier variants when differing behavior is strictly required:

```html
<!-- Tailwind Logical Properties Snippet -->
<div class="flex items-center gap-4 p-4">
  <div class="ms-4 me-2 ps-3 pe-6 border-s-4 border-blue-700 text-start">
    <p class="text-sm text-slate-600 text-start">
      نص عربي مع زر توجيهي:
    </p>
  </div>
  <button class="ms-auto rounded-s-lg rounded-e-none px-4 py-2 bg-blue-900 text-white">
    تأكيد
  </button>
</div>

<!-- Tailwind Table RTL Alignment Pattern -->
<table class="w-full text-start border-collapse">
  <thead>
    <tr class="border-b border-slate-200 text-xs font-bold text-slate-600">
      <!-- 1. Textual headers MUST be text-start (right in RTL) -->
      <th class="py-3 ps-4 pe-2 text-start">البند / وصف الخدمة</th>
      <!-- 2. Metric headers centered -->
      <th class="py-3 px-4 text-center w-24">الكمية</th>
      <!-- 3. Financial amounts end-aligned -->
      <th class="py-3 ps-2 pe-4 text-end w-36">المجموع الإجمالي</th>
      <!-- 4. Codes, URLs & LTR Data: text-start with dir="ltr" -->
      <th class="py-3 ps-2 pe-4 text-start w-40" dir="ltr">Endpoint</th>
    </tr>
  </thead>
  <tbody class="divide-y divide-slate-100 text-sm">
    <tr>
      <!-- Narrative text cell: strictly text-start -->
      <td class="py-3 ps-4 pe-2 text-start font-medium text-slate-800">
        تطوير لوحة تحكم المنصة الموحدة مع تقارير التحليلات
      </td>
      <!-- Quantitative metric cell: centered -->
      <td class="py-3 px-4 text-center font-mono">1</td>
      <!-- Numeric amount cell: text-end -->
      <td class="py-3 ps-2 pe-4 text-end font-mono font-bold text-slate-900">
        5,200.00 ر.س
      </td>
      <!-- Codes, URLs & LTR cell: text-start with dir="ltr" -->
      <td class="py-3 ps-2 pe-4 text-start font-mono text-xs text-slate-500" dir="ltr">
        /api/v1/analytics
      </td>
    </tr>
  </tbody>
</table>
```

## 4. Multi-Engine PDF Generation

### ReportLab (Python)
ReportLab does not perform OpenType complex script shaping or BiDi reordering by default. You must reshape glyphs with `arabic-reshaper`, reorder with `python-bidi`, and embed a TrueType Arabic font:

```python
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import arabic_reshaper
from bidi.algorithm import get_display

# 1. Register an Arabic Unicode TTF font
pdfmetrics.registerFont(TTFont('ArabicFont', 'Amiri-Regular.ttf'))

# 2. Reshape glyphs and apply BiDi visual ordering
raw_text = "تقرير الإنجاز: تم تنفيذ 12 عملية بنجاح."
reshaped = arabic_reshaper.reshape(raw_text)
bidi_text = get_display(reshaped)

# 3. Render on canvas
c = canvas.Canvas("reportlab_arabic.pdf")
c.setFont('ArabicFont', 14)
# Use drawRightString for RTL visual alignment
c.drawRightString(550, 780, bidi_text)
c.save()
```

### mPDF (PHP / Laravel)
mPDF supports Arabic out of the box when automatic font and script detection are enabled.
*(Note: Avoid `dompdf` for Arabic as it lacks complex script shaping support).*

```php
$mpdf = new \Mpdf\Mpdf([
    'mode' => 'utf-8',
    'format' => 'A4',
    'default_font' => 'dejavusans',
    'autoScriptToLang' => true,
    'autoLangToFont' => true,
]);

// Explicitly set RTL directionality
$mpdf->SetDirectionality('rtl');
$mpdf->WriteHTML($htmlContent);
$mpdf->Output('report.pdf', \Mpdf\Output\Destination::INLINE);
```

### WeasyPrint (Python)
WeasyPrint uses HarfBuzz and Pango under the hood and shapes Arabic complex scripts natively. Standard CSS `@page` margin boxes work out of the box without extra reshaping libraries.

## 5. Email HTML (Outlook & Webmail Compatibility)
Many desktop email clients (especially Microsoft Outlook on Windows) ignore CSS `direction: rtl` or flexbox. Always set explicit HTML attributes `dir="rtl"` and `align="right"` directly on tables and table cells:

```html
<table dir="rtl" align="right" width="100%" border="0" cellpadding="0" cellspacing="0" style="direction: rtl; text-align: right;">
  <tr>
    <td dir="rtl" align="right" style="direction: rtl; text-align: right; font-family: Tahoma, Arial, sans-serif; font-size: 14px; color: #1e293b; padding: 16px;">
      مرحباً بك، تم استلام طلبك رقم <strong>#10492</strong> وجارٍ معالجته.
    </td>
  </tr>
</table>
```
