#!/usr/bin/env python3
import sys
import os
import re
import argparse
import zipfile
import xml.etree.ElementTree as ET
from typing import List, Tuple

def has_arabic(text: str) -> bool:
    return bool(re.search(r'[\u0600-\u06FF]', text))

def check_markdown_txt(filepath: str) -> List[Tuple[int, str]]:
    findings = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f, start=1):
            # Check for invisible BiDi control marks on ALL lines (not just Arabic lines)
            if re.search(r'[\u200E\u200F\u202A-\u202E\u2066-\u2069]', line):
                findings.append((i, "[BIDI_CONTROL] Invisible BiDi control characters found. Do not use in chat/markdown."))

            if not has_arabic(line):
                continue
            
            # Check for Latin punctuation adjacent to Arabic letters
            if re.search(r'[\u0600-\u06FF]\s*[,;\?]|[,;\?]\s*[\u0600-\u06FF]', line):
                findings.append((i, "[PUNCTUATION] Latin punctuation (, ; ?) used near Arabic text. Use ، ؛ ؟ instead."))
                
    return findings

def check_html(filepath: str) -> List[Tuple[int, str]]:
    findings = []
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    content = "".join(lines)
        
    if has_arabic(content):
        # Look for <html ...>
        html_tag_match = re.search(r'<html[^>]*>', content, re.IGNORECASE)
        if html_tag_match:
            html_tag = html_tag_match.group(0)
            # Accept dir="rtl" or dir="auto" as valid
            has_valid_dir = bool(re.search(r'dir=["\'](rtl|auto)["\']', html_tag, re.IGNORECASE))
            has_valid_lang = bool(re.search(r'lang=["\']ar(?:-[a-zA-Z]+)?["\']', html_tag, re.IGNORECASE))
            if not has_valid_dir or not has_valid_lang:
                findings.append((1, '[HTML_ROOT] <html> tag missing dir="rtl" (or dir="auto") or lang="ar".'))
        else:
            findings.append((1, "[HTML_ROOT] No <html> tag found, but Arabic text is present."))
            
    # Check for all physical horizontal CSS properties as warnings
    physical_props = [
        (r'\bmargin-(?:left|right)\b', 'margin-left/right (prefer ms-*/me-* or margin-inline-start/end)'),
        (r'\bpadding-(?:left|right)\b', 'padding-left/right (prefer ps-*/pe-* or padding-inline-start/end)'),
        (r'\b(?:left|right)\s*:', 'left/right positioning (prefer start-*/end-* or inset-inline-start/end)'),
        (r'\btext-align\s*:\s*(?:left|right)\b', 'text-align: left/right (prefer text-start/end or text-align: start/end)'),
        (r'\bborder-(?:left|right)\b', 'border-left/right (prefer border-s-*/border-e-* or border-inline-start/end)'),
    ]
    for i, line in enumerate(lines, start=1):
        for pattern, desc in physical_props:
            if re.search(pattern, line, re.IGNORECASE):
                findings.append((i, f"[CSS_PHYSICAL] Warning: Physical CSS property found matching '{desc}'."))
                
    return findings

def check_docx(filepath: str) -> List[Tuple[int, str]]:
    findings = []
    try:
        with zipfile.ZipFile(filepath, 'r') as docx_zip:
            if 'word/document.xml' not in docx_zip.namelist():
                return findings
            
            xml_content = docx_zip.read('word/document.xml')
            root = ET.fromstring(xml_content)
            
            ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
            
            # Check Paragraphs
            for p_idx, p in enumerate(root.findall('.//w:p', ns), start=1):
                p_text = "".join(t.text for t in p.findall('.//w:t', ns) if t.text)
                if has_arabic(p_text):
                    pPr = p.find('w:pPr', ns)
                    has_bidi = pPr is not None and pPr.find('w:bidi', ns) is not None
                    
                    # Require w:jc val right/end/center (flag left/start/both or missing as error)
                    jc_elem = pPr.find('w:jc', ns) if pPr is not None else None
                    jc_val = jc_elem.attrib.get(f"{{{ns['w']}}}val") if jc_elem is not None else None
                    valid_jc = jc_val in ('right', 'end', 'center')
                    
                    if not has_bidi or not valid_jc:
                        preview = p_text[:20].strip()
                        reasons = []
                        if not has_bidi:
                            reasons.append("missing w:bidi")
                        if not valid_jc:
                            reasons.append(f"invalid/missing w:jc (val='{jc_val}', expected 'right', 'end', or 'center')")
                        findings.append((0, f"[DOCX_PARAGRAPH] Arabic paragraph '{preview}...' has {' and '.join(reasons)}."))
                        
            # Check Tables
            for tbl in root.findall('.//w:tbl', ns):
                tbl_text = "".join(t.text for t in tbl.findall('.//w:t', ns) if t.text)
                if has_arabic(tbl_text):
                    tblPr = tbl.find('w:tblPr', ns)
                    if tblPr is None or tblPr.find('w:bidiVisual', ns) is None:
                        findings.append((0, "[DOCX_TABLE] Table containing Arabic text is missing w:bidiVisual."))
                        
    except Exception as e:
        findings.append((0, f"[DOCX_ERROR] Could not parse docx: {e}"))
        
    return findings

def main():
    parser = argparse.ArgumentParser(description="Check files for Arabic engineering best practices.")
    parser.add_argument("file", help="The file to check (.md, .txt, .html, .docx)")
    args = parser.parse_args()
    
    filepath = args.file
    if not os.path.isfile(filepath):
        print(f"Error: File '{filepath}' not found.")
        sys.exit(1)
        
    ext = os.path.splitext(filepath)[1].lower()
    
    findings = []
    if ext in ['.md', '.txt']:
        findings = check_markdown_txt(filepath)
    elif ext in ['.html', '.htm']:
        findings = check_html(filepath)
    elif ext == '.docx':
        findings = check_docx(filepath)
    else:
        print(f"Unsupported file extension '{ext}'")
        sys.exit(0)
        
    if findings:
        for line_num, msg in findings:
            print(f"{filepath}:{line_num}: {msg}")
        sys.exit(1)
    else:
        print(f"No issues found in {filepath}")
        sys.exit(0)

if __name__ == "__main__":
    main()
