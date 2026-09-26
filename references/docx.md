# Wordprocessing & OpenXML (.docx) RTL Engineering

## The Critical Core Rule: Direction vs Alignment
In OpenXML (ECMA-376) and Microsoft Word:
- `<w:bidi/>` sets the **BiDi reading order** (cursor movement, punctuation placement, Arabic complex script shaping).
- `<w:jc w:val="right"/>` sets the **horizontal paragraph alignment**.
- **Crucial Word Trap:** In Microsoft Word, setting `<w:bidi/>` **WITHOUT** setting `<w:jc w:val="right"/>` causes the paragraph to inherit `Normal` style's alignment (which defaults to `left`). As a result, Arabic text sits against the **left margin** of the page or table cell.
- **Rule:** Every RTL paragraph and table cell MUST have **both** `<w:bidi/>` and explicit `<w:jc w:val="right"/>` (or `center` for titles/metrics).

## Tables
When creating RTL tables:
- `<w:bidiVisual/>` is **mandatory** on table properties (`tblPr`) so Column 0 renders on the far right.
- Note: `<w:bidiVisual/>` only affects visual column order; it does **not** align paragraph text within cells. Each cell paragraph still requires explicit `<w:jc w:val="right"/>` and `<w:bidi/>`.

## Schema-Order & Idempotent XML Insertion
Blindly calling `.append()` on OpenXML elements causes duplicate tags and ECMA-376 child-order violations (e.g., placing `<w:bidi/>` after `<w:jc/>` in `w:pPr`, or appending `w:bidi` at the end of `w:sectPr`), triggering Word repair warnings.
All element insertions route through an order-aware, idempotent helper with explicit ECMA-376 child order lists:

```python
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import qn, nsdecls

PPR_ORDER = [
    'w:pStyle', 'w:keepNext', 'w:keepLines', 'w:pageBreakBefore', 'w:framePr',
    'w:widowControl', 'w:numPr', 'w:pBdr', 'w:shd', 'w:tabs',
    'w:suppressAutoHyphens', 'w:kinsoku', 'w:wordWrap', 'w:overflowPunct',
    'w:topLinePunct', 'w:autoSpaceDE', 'w:autoSpaceDN', 'w:bidi',
    'w:adjustRightInd', 'snapToGrid', 'w:spacing', 'w:ind',
    'w:contextualSpacing', 'w:mirrorIndents', 'w:suppressOverlap', 'w:jc',
    'w:textDirection', 'w:textAlignment', 'w:textboxTightWrap',
    'w:outlineLvl', 'w:divId', 'w:cnfStyle', 'w:rPr', 'w:sectPr',
    'w:pPrChange'
]

RPR_ORDER = [
    'w:rStyle', 'w:rFonts', 'w:b', 'w:bCs', 'w:i', 'w:iCs', 'w:caps',
    'w:smallCaps', 'w:strike', 'w:dstrike', 'w:outline', 'w:shadow',
    'w:emboss', 'w:imprint', 'w:noProof', 'w:snapToGrid', 'w:vanish',
    'w:color', 'w:spacing', 'w:w', 'w:kern', 'w:position', 'w:sz',
    'w:szCs', 'w:highlight', 'w:u', 'w:effect', 'w:bdr', 'w:shd',
    'w:fitText', 'w:vertAlign', 'w:rtl', 'w:cs', 'w:em', 'w:lang',
    'w:eastAsianLayout', 'w:specVanish', 'w:oMath', 'w:rPrChange'
]

TBLPR_ORDER = [
    'w:tblStyle', 'w:tblpPr', 'w:tblOverlap', 'w:bidiVisual',
    'w:tblStyleRowBandSize', 'w:tblStyleColBandSize', 'w:tblW', 'w:jc',
    'w:tblCellSpacing', 'w:tblInd', 'w:tblBorders', 'w:shd',
    'w:tblLayout', 'w:tblCellMar', 'w:tblLook'
]

SECTPR_ORDER = [
    'w:headerReference', 'w:footerReference', 'w:footnotePr', 'w:endnotePr',
    'w:type', 'w:pgSz', 'w:pgMar', 'w:paperSrc', 'w:pgBorders', 'w:lnNumType',
    'w:pgNumType', 'w:cols', 'w:formProt', 'w:vAlign', 'w:noEndnote',
    'w:titlePg', 'w:textDirection', 'w:bidi', 'w:rtlGutter', 'w:docGrid',
    'w:printerSettings', 'w:sectPrChange'
]

def get_or_insert_element(parent, tag_name: str, schema_order: list, elem_to_insert=None, **attrs):
    """
    Idempotent find-or-create that inserts an element in strict ECMA-376 schema order.
    Updates attributes if present; otherwise inserts elem_to_insert or creates a new element
    and places it before the first existing successor child according to schema_order.
    """
    elem = parent.find(qn(tag_name))
    if elem is not None:
        for k, v in attrs.items():
            elem.set(qn(k), v)
        return elem

    if elem_to_insert is not None:
        elem = elem_to_insert
    else:
        elem = OxmlElement(tag_name)
        for k, v in attrs.items():
            elem.set(qn(k), v)

    if tag_name in schema_order:
        idx = schema_order.index(tag_name)
        successors = set(schema_order[idx + 1:])
        for child in parent:
            child_tag = f"w:{child.tag.split('}')[-1]}" if '}' in child.tag else child.tag
            if child_tag in successors:
                child.addprevious(elem)
                return elem

    parent.append(elem)
    return elem
```

## Complete BiDi Word Document Builder
Full implementation using native `python-docx` APIs (`run.font.rtl`, `paragraph.alignment`, `run.font.size`, etc.) with order-safe XML fallbacks:

```python
import re
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
        # 1. Section-level RTL (margins, header/footer, column flow) in schema order
        for section in self.doc.sections:
            sectPr = section._sectPr
            get_or_insert_element(sectPr, 'w:bidi', SECTPR_ORDER)

        # 2. Normal style RTL + Right Alignment
        style = self.doc.styles['Normal']
        style.font.name = 'Calibri'
        style.font.size = Pt(11)
        style.font.color.rgb = RGBColor(30, 41, 59)
        style.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        pPr = style._element.get_or_add_pPr()
        get_or_insert_element(pPr, 'w:bidi', PPR_ORDER)
        get_or_insert_element(pPr, 'w:jc', PPR_ORDER, **{'w:val': 'right'})

        # 3. Document-level Defaults (pPrDefault & rPrDefault) in styles.xml
        pPrDefault = self.doc.styles.element.xpath('//w:pPrDefault')
        if pPrDefault:
            pPr_def = pPrDefault[0].find(qn('w:pPr'))
            if pPr_def is not None:
                get_or_insert_element(pPr_def, 'w:bidi', PPR_ORDER)
                get_or_insert_element(pPr_def, 'w:jc', PPR_ORDER, **{'w:val': 'right'})

        rPrDefault = self.doc.styles.element.xpath('//w:rPrDefault')
        if rPrDefault:
            rPr_def = rPrDefault[0].find(qn('w:rPr'))
            if rPr_def is not None:
                lang = rPr_def.find(qn('w:lang'))
                if lang is not None:
                    lang.set(qn('w:bidi'), 'ar-SA')
                else:
                    get_or_insert_element(rPr_def, 'w:lang', RPR_ORDER, **{'w:val': 'ar-SA', 'w:bidi': 'ar-SA'})

    def set_paragraph_rtl(self, paragraph, align: WD_ALIGN_PARAGRAPH = WD_ALIGN_PARAGRAPH.RIGHT) -> None:
        """Enforces both RTL reading order and explicit margin alignment."""
        pPr = paragraph._p.get_or_add_pPr()
        get_or_insert_element(pPr, 'w:bidi', PPR_ORDER)
        paragraph.alignment = align

    def set_table_rtl(self, table) -> None:
        """Enforces RTL table column ordering (w:bidiVisual), borders, and cell alignment."""
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        tblPr = table._tbl.tblPr
        
        # w:bidiVisual in schema order
        get_or_insert_element(tblPr, 'w:bidiVisual', TBLPR_ORDER)
            
        # Subtle executive borders in schema order
        tbl_borders = parse_xml(
            f'<w:tblBorders {nsdecls("w")}>'
            f'  <w:top w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>'
            f'  <w:left w:val="none"/>'
            f'  <w:bottom w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>'
            f'  <w:right w:val="none"/>'
            f'  <w:insideH w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
            f'  <w:insideV w:val="none"/>'
            f'</w:tblBorders>'
        )
        get_or_insert_element(tblPr, 'w:tblBorders', TBLPR_ORDER, elem_to_insert=tbl_borders)
            
        # Comfortable internal cell padding in schema order
        tbl_cell_mar = parse_xml(
            f'<w:tblCellMar {nsdecls("w")}>'
            f'  <w:top w:w="120" w:type="dxa"/>'
            f'  <w:bottom w:w="120" w:type="dxa"/>'
            f'  <w:left w:w="160" w:type="dxa"/>'
            f'  <w:right w:w="160" w:type="dxa"/>'
            f'</w:tblCellMar>'
        )
        get_or_insert_element(tblPr, 'w:tblCellMar', TBLPR_ORDER, elem_to_insert=tbl_cell_mar)

        # Enforce right-alignment and RTL on every cell paragraph
        for row in table.rows:
            for cell in row.cells:
                for p in cell.paragraphs:
                    self.set_paragraph_rtl(p, WD_ALIGN_PARAGRAPH.RIGHT)

    def add_arabic_run(self, paragraph, text: str, bold: bool = False, color=None, size_pt: float = None):
        """Adds a run with explicit Arabic Complex Script (w:cs) and language tagging."""
        run = paragraph.add_run(text)
        run.bold = bold
        if color:
            run.font.color.rgb = color
        if size_pt:
            run.font.size = Pt(size_pt)
            
        run.font.name = 'Calibri'
        run.font.rtl = True
        
        rPr = run._r.get_or_add_rPr()
        # Declare complex script font in rFonts
        rFonts = rPr.find(qn('w:rFonts'))
        if rFonts is not None:
            rFonts.set(qn('w:ascii'), 'Calibri')
            rFonts.set(qn('w:hAnsi'), 'Calibri')
            rFonts.set(qn('w:cs'), 'Calibri')
        else:
            get_or_insert_element(rPr, 'w:rFonts', RPR_ORDER, **{
                'w:ascii': 'Calibri',
                'w:hAnsi': 'Calibri',
                'w:cs': 'Calibri'
            })
            
        get_or_insert_element(rPr, 'w:lang', RPR_ORDER, **{'w:bidi': 'ar-SA'})
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
        run.font.rtl = False
        
        rPr = run._r.get_or_add_rPr()
        get_or_insert_element(rPr, 'w:lang', RPR_ORDER, **{'w:val': 'en-US'})
        return run

def add_mixed_arabic_english(builder: BiDiDocxBuilder, paragraph, text: str) -> None:
    """
    Splits text on English words, multi-word Latin spans (e.g. 'Meta Description', '200 OK'),
    programming terms with symbols (e.g. 'C++', 'C#'), emails, URLs with query strings,
    bracketed expressions (e.g. '(Meta)'), single characters, or numbers, outputting isolated runs.
    """
    # Includes @ + # & ? % = so C++, C#, emails, query strings stay one LTR run.
    # Excludes trailing dot from absorbing sentence-ending punctuation.
    token_pattern = (
        r'([\[\(\{]?'
        r'[a-zA-Z0-9_\-\.\:\/\<\>\=\"@\+\#\&\?\%=]*[a-zA-Z0-9][a-zA-Z0-9_\-\.\:\/\<\>\=\"@\+\#\&\?\%=]*'
        r'(?<!\.)'
        r'(?:[ \t]+[a-zA-Z0-9_\-\.\:\/\<\>\=\"@\+\#\&\?\%=]*[a-zA-Z0-9][a-zA-Z0-9_\-\.\:\/\<\>\=\"@\+\#\&\?\%=]*(?<!\.))*'
        r'[\]\)\}]?)'
    )
    is_eng_pattern = (
        r'^[\[\(\{]?'
        r'[a-zA-Z0-9_\-\.\:\/\<\>\=\"@\+\#\&\?\%=]*[a-zA-Z0-9][a-zA-Z0-9_\-\.\:\/\<\>\=\"@\+\#\&\?\%=]*'
        r'(?<!\.)'
        r'(?:[ \t]+[a-zA-Z0-9_\-\.\:\/\<\>\=\"@\+\#\&\?\%=]*[a-zA-Z0-9][a-zA-Z0-9_\-\.\:\/\<\>\=\"@\+\#\&\?\%=]*(?<!\.))*'
        r'[\]\)\}]?$'
    )

    tokens = re.split(token_pattern, str(text))
    for token in tokens:
        if not token:
            continue
        is_eng = bool(re.match(is_eng_pattern, token))
        is_code = bool(re.search(r'[\/\<\>\=\_\@\+\#\&\?]', token))
        if is_eng:
            builder.add_isolated_ltr_run(paragraph, token, is_code=is_code)
        else:
            builder.add_arabic_run(paragraph, token)

if __name__ == "__main__":
    builder = BiDiDocxBuilder()

    # 1. Heading
    heading = builder.doc.add_heading(level=1)
    builder.set_paragraph_rtl(heading)
    builder.add_arabic_run(heading, "تقرير الأداء الفني والتشغيلي", bold=True, size_pt=18)

    # 2. Mixed Arabic/English paragraph with technical tokens
    p = builder.doc.add_paragraph()
    builder.set_paragraph_rtl(p)
    add_mixed_arabic_english(
        builder,
        p,
        "فحص برمجيات C++ و C# وتأكيد الاستجابة عبر dev@example.com بكود 200 OK ورابط (https://api.com?page=1&status=active) بنسبة 95%."
    )

    # 3. 3-column table
    table = builder.doc.add_table(rows=3, cols=3)
    builder.set_table_rtl(table)

    headers = ["المعرف", "الحالة", "ملاحظات الفحص"]
    for i, h in enumerate(headers):
        cell_p = table.rows[0].cells[i].paragraphs[0]
        builder.add_arabic_run(cell_p, h, bold=True)

    data = [
        ["101", "ناجح", "تم التوافق مع v2.0 و C++20"],
        ["102", "قيد المراجعة", "تحقق من SSL Cert عبر admin@site.org"]
    ]
    for row_idx, row_data in enumerate(data, start=1):
        for col_idx, val in enumerate(row_data):
            cell_p = table.rows[row_idx].cells[col_idx].paragraphs[0]
            add_mixed_arabic_english(builder, cell_p, val)

    builder.doc.save("test_arabic_report.docx")
```
