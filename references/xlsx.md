# Spreadsheet & OpenPyXL (.xlsx) RTL Engineering

## 1. Workbook & Worksheet RTL Direction

In OpenPyXL, setting RTL requires targeting both `ws.sheet_view` and `ws.views.sheetView[0]`.
**Important:** Always guard `ws.views.sheetView[0]` to prevent `IndexError` when the view list is uninitialized or empty.

```python
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
import re

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
```

## 2. Complete Styling & Explicit Alignment

Do not rely on default or implicit alignments. Apply explicit center/right alignment based on content type.
**Note on `isdigit()`:** In Python, `str.isdigit()` returns `True` for Arabic-Indic digits (`٠-٩`). Use an explicit Western numeric regex to avoid accidental center alignment of Arabic numbers when unexpected.

```python
def style_rtl_worksheet(ws):
    """Applies royal navy headers, zebra rows, Arabic fonts, explicit alignments, and auto-widths."""
    header_font = Font(name='Calibri', size=11, bold=True, color='FFFFFF')
    header_fill = PatternFill(start_color='1E3A8A', end_color='1E3A8A', fill_type='solid')
    
    data_font = Font(name='Calibri', size=10, color='1E293B')
    zebra_fill = PatternFill(start_color='F8FAFC', end_color='F8FAFC', fill_type='solid')
    
    align_right = Alignment(horizontal='right', vertical='center', wrap_text=True)
    align_center = Alignment(horizontal='center', vertical='center')
    
    thin_border = Border(
        left=Side(style='thin', color='CBD5E1'),
        right=Side(style='thin', color='CBD5E1'),
        top=Side(style='thin', color='CBD5E1'),
        bottom=Side(style='thin', color='CBD5E1')
    )
    
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
            for cell in row:
                cell.font = data_font
                cell.border = thin_border
                if is_even:
                    cell.fill = zebra_fill
                
                # Explicit alignment heuristic:
                # Center numeric values (supporting signs, thousands separators, decimals, and percent)
                # as well as short single-token metric codes. Right-align Arabic narrative text.
                val_str = str(cell.value or '').strip()
                if (re.match(r'^[+-]?(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\.[0-9]+)?%?$', val_str) or 
                    (len(val_str) <= 12 and ' ' not in val_str)):
                    cell.alignment = align_center
                else:
                    cell.alignment = align_right

    # Auto-fit column widths with Arabic character scaling factor
    autofit_arabic_columns(ws)

def autofit_arabic_columns(ws):
    """
    Auto-fits column widths. Since multi-byte Arabic glyphs require more horizontal space
    than standard Latin characters, apply a 1.2x scaling factor to prevent text truncation.
    """
    for col in ws.columns:
        max_len = 0
        col_letter = get_column_letter(col[0].column)
        for cell in col:
            if cell.value:
                # 1.2 factor for Arabic font rendering width
                length = len(str(cell.value)) * 1.2
                if length > max_len:
                    max_len = length
        ws.column_dimensions[col_letter].width = min(max(max_len + 4, 14), 60)
```
