# Backend String Normalization & Text Processing

## 1. Unicode Normalization (Python)
Unify Arabic characters, hamzas, and tashkeel before indexing or comparison.

> **Warning:** `NFKC` normalization expands presentation forms and ligatures (e.g., `ﷲ` → `الله`), which alters string lengths and character offsets. Always store the original text in the database and normalize only a dedicated search/index column.

```python
import unicodedata
import re

def normalize_arabic_text(text: str) -> str:
    """Normalizes Arabic text to consistent NFKC unicode form and strips diacritics."""
    if not text:
        return ""
    text = unicodedata.normalize('NFKC', str(text))
    # Remove Arabic diacritics (Tashkeel)
    text = re.sub(r'[\u064B-\u065F\u0670]', '', text)
    return text.strip()
```

## 2. Arabic Search Normalization
Normalizes Arabic letters for robust search indexing and fuzzy matching. Optional flags are provided for `ة`→`ه` and `ى`→`ي` conversions to prevent false positives when exact spelling matters:

```python
def normalize_arabic_for_search(text: str, unify_taa: bool = False, unify_yaa: bool = False) -> str:
    """Normalizes Arabic letters for robust search indexing and matching."""
    if not text:
        return ""
    text = unicodedata.normalize('NFKC', text)
    
    # Remove Tashkeel (diacritics) & Tatweel (kashida)
    text = re.sub(r'[\u064B-\u065F\u0670\u0640]', '', text)
    
    # Unify Alef variations to bare Alef
    text = re.sub(r'[إأآٱ]', 'ا', text)
    
    # Unify Taa Marbuta to Haa (optional)
    if unify_taa:
        text = re.sub(r'ة', 'ه', text)
        
    # Unify Alef Maqsura to Yaa (optional)
    if unify_yaa:
        text = re.sub(r'ى', 'ي', text)
        
    return text.strip()
```

## 3. Arabic Slugification & Safe Filesystem Names
Generating clean, cross-platform filenames and URL slugs from Arabic strings without mojibake or illegal characters. In Python 3, `\w` natively matches Unicode word characters (including Arabic):

```python
def slugify_arabic(text: str, max_length: int = 60, separator: str = '_') -> str:
    """Generates a clean URL/filename slug preserving Arabic unicode letters."""
    if not text:
        return ""
    text = unicodedata.normalize('NFKC', text)
    text = re.sub(r'[\u064B-\u065F\u0670\u0640]', '', text)
    # \w matches Arabic Unicode characters in Python 3
    text = re.sub(r'[^\w]+', separator, text)
    return text.strip(separator)[:max_length].strip(separator)
```

## 4. JavaScript Internationalization (Intl)
Modern JS engines support full Arabic locale formatting via the standard `Intl` API:

- **Western Digits in Arabic text**: Use the `-u-nu-latn` locale extension to keep digits formatted as 0-9:
  ```javascript
  new Intl.NumberFormat('ar-SA-u-nu-latn').format(1234.56); // "١,٢٣٤.٥٦" -> "1,234.56"
  ```
- **Hijri (Umm al-Qura) Calendar**:
  ```javascript
  new Intl.DateTimeFormat('ar-SA-u-ca-islamic-umalqura', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  }).format(new Date());
  ```
- **Arabic Plural Rules (6 Categories)**:
  Arabic has 6 plural forms: `zero`, `one`, `two`, `few` (3-10), `many` (11-99), `other` (100+).
  ```javascript
  const pr = new Intl.PluralRules('ar');
  pr.select(0); // "zero"
  pr.select(1); // "one"
  pr.select(2); // "two"
  pr.select(5); // "few"
  pr.select(25); // "many"
  pr.select(100); // "other"
  ```

## 5. Punctuation & BiDi Control Marks in Generated Documents

> **Strict Scope Restriction:** Invisible BiDi control marks (`RLM` / `LRM`) MUST ONLY be used inside compiled or generated documents (Word `.docx`, PDF canvases, static print reports). **NEVER insert invisible control characters in chat messages, Markdown replies, or source code files** — they corrupt copy/paste, terminal rendering, and string searches.

### Punctuation Marks in Arabic Typography
Always use native Arabic punctuation marks to ensure correct baseline alignment and font shaping:
- **Arabic Comma**: `،` `(U+060C)` instead of English `,`.
- **Arabic Semicolon**: `؛` `(U+061B)` instead of English `;`.
- **Arabic Question Mark**: `؟` `(U+061F)` instead of English `?`.
- **Arabic Quotations**: Use Guillemets `«` `(U+00AB)` and `»` `(U+00BB)` for Arabic quotations.

### BiDi Control Characters (RLM & LRM)
When neutral punctuation marks (such as `:`, `-`, `/`, `(`, `)`) appear between an Arabic word and an English/code term in generated documents, the Unicode BiDi algorithm may place the punctuation on the wrong side. Use Unicode marks to anchor them explicitly:
- **RLM (Right-to-Left Mark `\u200F` / `&rlm;`)**: Forces neutral characters (parentheses, colons, slashes) to behave as part of the RTL flow.
- **LRM (Left-to-Right Mark `\u200E` / `&lrm;`)**: Prevents phone numbers (`+966 50...`), version numbers (`v1.2.0`), or paths from flipping inside RTL sentences.

```python
# Generated Document Example (PDF/DOCX string assembly):
RTL_MARK = "\u200F"
LTR_MARK = "\u200E"

# Pinning punctuation to Arabic flow:
text_with_colon = f"الرابط المطلوب {RTL_MARK}({url}){RTL_MARK}:"

# Pinning phone numbers or versions to LTR:
version_text = f"الإصدار الحالي: {LTR_MARK}v2.4.1{LTR_MARK}"
```
