#!/usr/bin/env python3
import sys
import os
import re
import argparse
import zipfile
import xml.etree.ElementTree as ET
from typing import List, Tuple

KNOWN_CLIS = {
    'git', 'gh', 'npm', 'npx', 'pnpm', 'yarn', 'composer', 'php', 'artisan',
    'python', 'python3', 'pip', 'cd', 'ls', 'cp', 'mv', 'rm', 'mkdir', 'ln',
    'curl', 'wget', 'docker', 'sudo', 'bash', 'sh', 'node', 'cat', 'grep',
    'find', 'chmod'
}

def has_arabic(text: str) -> bool:
    return bool(re.search(r'[\u0600-\u06FF]', text))

def is_path_command_or_url(span: str) -> bool:
    s = span.strip()
    if s.startswith(('~/', '/', './', '../')):
        return True
    if '://' in s:
        return True
    tokens = s.split()
    if tokens:
        first = tokens[0].lower()
        if first in KNOWN_CLIS:
            return True
        if '/' in s and any(re.match(r'^-{1,2}[a-zA-Z0-9]', t) for t in tokens[1:]):
            return True
    return False

def check_markdown_txt(filepath: str) -> List[Tuple[int, str]]:
    findings = []
    in_code_block = False
    fence_char = None
    fence_length = 0
    bracket_pat = re.compile(r'\(\s*(?<!`)(`{1,2})(?!`)(.*?)(?<!`)\1(?!`)\s*\)|\[\s*(?<!`)(`{1,2})(?!`)(.*?)(?<!`)\3(?!`)\s*\](?!\()')

    with open(filepath, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f, start=1):
            # Check for invisible BiDi control marks on ALL lines (not just Arabic lines)
            if re.search(r'[\u200E\u200F\u202A-\u202E\u2066-\u2069]', line):
                findings.append((i, "[BIDI_CONTROL] Invisible BiDi control characters found. Do not use in chat/markdown."))

            # Track fenced code blocks per CommonMark (indentation 0-3 spaces, same char, length >= opening)
            if not in_code_block:
                m_open = re.match(r'^[ ]{0,3}(`{3,}|~{3,})', line)
                if m_open:
                    fence = m_open.group(1)
                    in_code_block = True
                    fence_char = fence[0]
                    fence_length = len(fence)
                    continue
            else:
                m_close = re.match(r'^[ ]{0,3}(`{3,}|~{3,})\s*$', line)
                if m_close:
                    fence = m_close.group(1)
                    if fence[0] == fence_char and len(fence) >= fence_length:
                        in_code_block = False
                        fence_char = None
                        fence_length = 0
                        continue

            if in_code_block:
                # [CODEBLOCK_ARABIC_COMMENT]: comment line containing Arabic letters inside code block
                stripped = line.strip()
                if stripped.startswith(('#', '//', '/*', '*', '<!--', '--')) and re.search(r'[\u0621-\u064A\u0671-\u06D5]', line):
                    findings.append((i, "[CODEBLOCK_ARABIC_COMMENT] Arabic comment found inside code block. Code comments must be in English."))
                continue

            # Outside code blocks:
            if not has_arabic(line):
                continue

            # Skip counter-example lines that start (after optional whitespace/list marker) with ❌ or **Bad:**
            stripped_lead = re.sub(r'^\s*(?:[-*+]\s+|\d+[.)]\s+)?', '', line)
            if stripped_lead.startswith(('❌', '**Bad:**', 'Bad:')):
                continue

            # [BRACKET_OUTSIDE_BACKTICK]: pattern like (`x`) or [`x`] where a bracket directly wraps a backtick span
            if bracket_pat.search(line):
                findings.append((i, "[BRACKET_OUTSIDE_BACKTICK] Pattern like (`x`) or [`x`] found. Include brackets inside backticks: `(x)` or `[x]`."))

            # [PUNCTUATION]: Latin punctuation adjacent to Arabic letters
            if re.search(r'[\u0600-\u06FF]\s*[,;\?]|[,;\?]\s*[\u0600-\u06FF]', line):
                findings.append((i, "[PUNCTUATION] Latin punctuation (, ; ?) used near Arabic text. Use ، ؛ ؟ instead."))

            # [INLINE_PATH_END]: non-code-block line containing Arabic ending with path/command/URL backtick span
            if not line.strip().startswith('|'):
                clean_line = re.sub(r'[\s.:,;?!،؛؟\-\*]+$', '', line.rstrip())
                m = re.search(r'(`+)([^`]+)\1$', clean_line)
                if m:
                    last_span = m.group(2).strip()
                    if is_path_command_or_url(last_span):
                        findings.append((i, f"[INLINE_PATH_END] Path, command, or URL (`{last_span}`) at end of Arabic line. Move to dedicated code block or table."))

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
    parser.add_argument("files", nargs="+", help="Files to check (.md, .txt, .html, .docx)")
    parser.add_argument("--warn-only", action="store_true", help="Only warn; do not exit with error code 1 on findings.")
    args = parser.parse_args()
    
    total_findings = 0
    file_errors = 0
    for filepath in args.files:
        if not os.path.isfile(filepath):
            print(f"Error: File '{filepath}' not found.")
            file_errors += 1
            continue
            
        ext = os.path.splitext(filepath)[1].lower()
        findings = []
        try:
            if ext in ['.md', '.txt']:
                findings = check_markdown_txt(filepath)
            elif ext in ['.html', '.htm']:
                findings = check_html(filepath)
            elif ext == '.docx':
                findings = check_docx(filepath)
            else:
                print(f"Unsupported file extension '{ext}' for {filepath}")
                continue
        except Exception as e:
            print(f"Error reading '{filepath}': {e}")
            file_errors += 1
            continue
            
        if findings:
            total_findings += len(findings)
            for line_num, msg in findings:
                print(f"{filepath}:{line_num}: {msg}")
        else:
            print(f"No issues found in {filepath}")
            
    if file_errors > 0:
        sys.exit(1)
    if total_findings > 0 and not args.warn_only:
        sys.exit(1)
    sys.exit(0)

if __name__ == "__main__":
    main()
