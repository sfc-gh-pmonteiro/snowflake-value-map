---
name: value-map-pptx-generation
description: "PPTX deck generation reference for the Snowflake Value Map study. Contains slide blueprint, helper functions, icon mapping, and generation instructions. Load this when user selects PPTX output in Step 5."
---

# Value Map PPTX Generation Reference

> **Load this file when the user requests PPTX output in Step 5.**
> This is self-contained — all helpers, patterns, and instructions needed to produce the deck.

## Prerequisites

```bash
uv pip install python-pptx
```

## Template Location

```python
import os
TEMPLATE_SEARCH = [
    os.path.join(os.getcwd(), "templates", "snowflake_template.pptx"),
    os.path.expanduser("~/.cortex/skills/snowflake-value-map/templates/snowflake_template.pptx"),
    os.path.expanduser("~/.snowflake/cortex/skills/CoCo_pptx_Skill/snowflake_template.pptx"),
]
TEMPLATE = next((p for p in TEMPLATE_SEARCH if os.path.isfile(p)), None)
assert TEMPLATE, "snowflake_template.pptx not found"
```

---

## 1. Colour Constants (Snowflake Brand Palette)

```python
from pptx.dml.color import RGBColor

DK1       = RGBColor(0x26, 0x26, 0x26)  # primary dark text
WHITE     = RGBColor(0xFF, 0xFF, 0xFF)  # white
DK2       = RGBColor(0x11, 0x56, 0x7F)  # Snowflake dark navy
SF_BLUE   = RGBColor(0x29, 0xB5, 0xE8)  # Snowflake Blue (primary brand)
TEAL      = RGBColor(0x71, 0xD3, 0xDC)  # accent3
ORANGE    = RGBColor(0xFF, 0x9F, 0x36)  # accent4
VIOLET    = RGBColor(0x7D, 0x44, 0xCF)  # accent5
PINK      = RGBColor(0xD4, 0x5B, 0x90)  # accent6
BODY_GREY = RGBColor(0x5B, 0x5B, 0x5B)  # subtitle / body
TBL_GREY  = RGBColor(0x71, 0x71, 0x71)  # table data text
LIGHT_BG  = RGBColor(0xF5, 0xF5, 0xF5)  # alternating row fill
BORDER    = RGBColor(0xC8, 0xC8, 0xC8)  # table borders
ERROR_RED = RGBColor(0xA2, 0x00, 0x00)  # GAP indicator (use sparingly)
MUTED     = RGBColor(0xBF, 0xBF, 0xBF)  # N/A indicator
CONN_LINE = RGBColor(0xCC, 0xCC, 0xCC)  # connector lines
```

### Classification Colour Mapping

| Classification | Badge Fill | Text Colour | Semantic |
|---------------|-----------|-------------|----------|
| **READY** | TEAL `#71D3DC` | DK1 | Green-ish = deploy now |
| **NEAR** | ORANGE `#FF9F36` | DK1 | Amber = minor gaps |
| **GAP** | ERROR_RED `#A20000` | WHITE | Red = significant work |
| **N/A** | MUTED `#BFBFBF` | DK1 | Grey = not applicable |

### Fill → Text Contrast (MANDATORY)

| Fill | Text | Reason |
|------|------|--------|
| DK2 | WHITE | Dark fill |
| SF_BLUE | WHITE | Brand standard |
| TEAL | **DK1** | Light fill — WHITE unreadable |
| ORANGE | **DK1** | Light fill — WHITE unreadable |
| VIOLET | WHITE | Dark fill |
| ERROR_RED | WHITE | Dark fill |

---

## 2. Dark Background Layout Sets

```python
DARK_BG_LAYOUTS = {9, 10, 18, 19, 20, 21, 22, 23, 25, 26, 27, 28}
COVER_LAYOUTS = {13, 14, 15, 16, 17}
```

---

## 3. Helper Functions (Copy ALL into every script)

### 3.1 set_ph — Set placeholder text

```python
def set_ph(slide, idx, text):
    """Set placeholder text. Styling inherits from master layout."""
    from pptx.enum.text import MSO_AUTO_SIZE
    from lxml import etree
    ph = slide.placeholders[idx]
    t_pos = (ph.top or 0) / 914400
    if t_pos < 0.50:
        clean = text.replace('\n', ' ')
        if len(clean) > 50:
            print(f"⚠ TITLE TOO LONG: {len(clean)} chars (max 50): \"{clean[:50]}...\"")
    ph.text = text
    ph.text_frame.auto_size = MSO_AUTO_SIZE.TEXT_TO_FIT_SHAPE
    ns = 'http://schemas.openxmlformats.org/drawingml/2006/main'
    bodyPr = ph.text_frame._txBody.find(f'{{{ns}}}bodyPr')
    if bodyPr is None:
        bodyPr = etree.SubElement(ph.text_frame._txBody, f'{{{ns}}}bodyPr')
    if t_pos < 0.50:
        bodyPr.set('bIns', '0')
    elif 0.60 < t_pos < 1.20:
        bodyPr.set('tIns', '54864')
    if t_pos < 1.20:
        for para in ph.text_frame.paragraphs:
            pPr = para._p.find(f'{{{ns}}}pPr')
            if pPr is None:
                pPr = etree.SubElement(para._p, f'{{{ns}}}pPr')
                para._p.insert(0, pPr)
            pPr.set('indent', '0')
            pPr.set('marL', '0')
```

### 3.2 set_ph_sections — Heading + body bullet groups

```python
def set_ph_sections(slide, idx, sections, heading_size=12, body_size=10):
    """Fill placeholder with bold-heading + indented-bullet groups.
    sections: list of (heading_str, [bullet_str, ...])
    """
    from pptx.util import Pt
    from pptx.enum.text import MSO_AUTO_SIZE
    ph = slide.placeholders[idx]
    ph.text_frame.auto_size = MSO_AUTO_SIZE.TEXT_TO_FIT_SHAPE
    tf = ph.text_frame
    tf.clear()
    first = True
    for heading, bullets in sections:
        p = tf.paragraphs[0] if first else tf.add_paragraph()
        first = False
        r = p.add_run()
        r.text = heading
        r.font.size = Pt(heading_size)
        r.font.bold = True
        r.font.color.rgb = DK2
        r.font.name = "Arial"
        for bullet in bullets:
            bp = tf.add_paragraph()
            bp.level = 1
            br = bp.add_run()
            br.text = bullet
            br.font.size = Pt(body_size)
            br.font.name = "Arial"
```

### 3.3 set_ph_lines — Flat bullet list

```python
def set_ph_lines(slide, idx, lines, font_size=11):
    """Fill placeholder with a flat bullet list."""
    from pptx.util import Pt
    from pptx.enum.text import MSO_AUTO_SIZE
    ph = slide.placeholders[idx]
    ph.text_frame.auto_size = MSO_AUTO_SIZE.TEXT_TO_FIT_SHAPE
    tf = ph.text_frame
    tf.clear()
    for i, line in enumerate(lines):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        r = p.add_run()
        r.text = line
        r.font.size = Pt(font_size)
        r.font.name = "Arial"
```

### 3.4 set_ph_bold_keywords — Bold keyword: description pairs

```python
def set_ph_bold_keywords(slide, idx, items, kw_size=11, body_size=11):
    """Fill placeholder with bold keyword + description pairs.
    items: list of (keyword, description) tuples
    """
    from pptx.util import Pt
    from pptx.enum.text import MSO_AUTO_SIZE
    ph = slide.placeholders[idx]
    ph.text_frame.auto_size = MSO_AUTO_SIZE.TEXT_TO_FIT_SHAPE
    tf = ph.text_frame
    tf.clear()
    for i, (kw, desc) in enumerate(items):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        r1 = p.add_run()
        r1.text = f"{kw}: "
        r1.font.size = Pt(kw_size)
        r1.font.bold = True
        r1.font.name = "Arial"
        r2 = p.add_run()
        r2.text = desc
        r2.font.size = Pt(body_size)
        r2.font.name = "Arial"
```

### 3.5 add_shape_text — ALL custom shapes

```python
def add_shape_text(slide, shape_type, left, top, width, height,
                   text, fill_colour, font_colour,
                   font_size=10, bold=False, alignment=PP_ALIGN.CENTER):
    """Add a shape with text — enforces ALL brand rules automatically."""
    shape = slide.shapes.add_shape(
        shape_type,
        Inches(left), Inches(top), Inches(width), Inches(height))
    shape.fill.solid()
    shape.fill.fore_color.rgb = fill_colour
    shape.line.fill.background()
    if width <= 2.0 and '\n' not in text and ' ' in text:
        text = text.replace(' ', '\n')
    tf = shape.text_frame
    tf.word_wrap = True
    tf.auto_size = MSO_AUTO_SIZE.TEXT_TO_FIT_SHAPE
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    from pptx.util import Pt as PtUtil
    tf.margin_left = PtUtil(4)
    tf.margin_right = PtUtil(4)
    tf.margin_top = PtUtil(2)
    tf.margin_bottom = PtUtil(2)
    p = tf.paragraphs[0]
    p.text = text
    p.font.name = "Arial"
    p.font.size = Pt(font_size)
    p.font.bold = bold
    p.font.color.rgb = font_colour
    p.alignment = alignment
    return shape
```

### 3.6 add_code_block — Multi-line text blocks

```python
def add_code_block(slide, left, top, width, height, lines,
                   bg_colour=None, font_colour=None, font_size=9):
    """Add a code/multi-line text block. Pass lines as a LIST."""
    if bg_colour is None: bg_colour = LIGHT_BG
    if font_colour is None: font_colour = DK1
    shape = slide.shapes.add_shape(
        MSO_SHAPE.ROUNDED_RECTANGLE,
        Inches(left), Inches(top), Inches(width), Inches(height))
    shape.fill.solid()
    shape.fill.fore_color.rgb = bg_colour
    shape.line.fill.background()
    tf = shape.text_frame
    tf.word_wrap = True
    tf.auto_size = MSO_AUTO_SIZE.TEXT_TO_FIT_SHAPE
    tf.vertical_anchor = MSO_ANCHOR.TOP
    tf.margin_left = Pt(6)
    tf.margin_right = Pt(6)
    tf.margin_top = Pt(4)
    tf.margin_bottom = Pt(4)
    text = "\n".join(lines)
    p = tf.paragraphs[0]
    p.text = text
    p.font.name = "Arial"
    p.font.size = Pt(font_size)
    p.font.color.rgb = font_colour
    p.alignment = PP_ALIGN.LEFT
    return shape
```

### 3.7 build_icon_index & place_icon — Template icons

```python
import re, copy
from pptx.enum.shapes import MSO_SHAPE_TYPE

def build_icon_index(prs):
    """Build lookup dict of template icons from slides 66 and 68.
    Call ONCE after loading template, BEFORE removing sample slides.
    """
    icon_index = {}
    def _normalize(s):
        return re.sub(r'\s+', ' ', s.strip().lower())
    for sn in [66, 68]:
        if sn - 1 >= len(prs.slides):
            continue
        slide = prs.slides[sn - 1]
        labels = []
        graphics = []
        for shape in slide.shapes:
            l = shape.left / 914400
            t = shape.top / 914400
            w = shape.width / 914400
            h = shape.height / 914400
            if t < 0.6 or shape.shape_type == MSO_SHAPE_TYPE.PLACEHOLDER:
                continue
            if shape.has_text_frame and shape.text_frame.text.strip():
                txt = shape.text_frame.text.strip().replace('\n', ' ')
                labels.append((l, t, txt))
            elif shape.shape_type in (MSO_SHAPE_TYPE.GROUP, MSO_SHAPE_TYPE.FREEFORM,
                                       MSO_SHAPE_TYPE.PICTURE):
                if w < 1.0 and h < 1.0:
                    graphics.append((l, t, shape))
        for gl, gt, gshape in graphics:
            best_label = None
            best_dist = 999
            for ll, lt, ltxt in labels:
                if lt > gt and lt - gt < 0.7 and abs(ll - gl) < 0.5:
                    dist = abs(ll - gl) + abs(lt - gt)
                    if dist < best_dist:
                        best_dist = dist
                        best_label = ltxt
            if best_label:
                key = _normalize(best_label)
                if key not in icon_index:
                    icon_index[key] = (gshape, slide.part)
    return icon_index


def place_icon(slide, icon_index, icon_name, target_left, target_top, scale=2.0):
    """Copy a template icon to a specific position on a slide."""
    key = re.sub(r'\s+', ' ', icon_name.strip().lower())
    if key not in icon_index:
        print(f"⚠ Icon not found: '{icon_name}'")
        return None
    src_shape, src_part = icon_index[key]
    new_el = copy.deepcopy(src_shape._element)
    ns_a = 'http://schemas.openxmlformats.org/drawingml/2006/main'
    ns_r = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
    for child in new_el.iter():
        if child.tag.endswith('}xfrm'):
            off = child.find(f'{{{ns_a}}}off')
            ext = child.find(f'{{{ns_a}}}ext')
            if off is not None:
                off.set('x', str(int(target_left * 914400)))
                off.set('y', str(int(target_top * 914400)))
            if ext is not None and scale != 1.0:
                cx = int(int(ext.get('cx', '0')) * scale)
                cy = int(int(ext.get('cy', '0')) * scale)
                ext.set('cx', str(cx))
                ext.set('cy', str(cy))
            break
    for blip in new_el.iter(f'{{{ns_a}}}blip'):
        embed_id = blip.get(f'{{{ns_r}}}embed')
        if embed_id:
            src_rel = src_part.rels.get(embed_id)
            if src_rel:
                new_rId = slide.part.relate_to(src_rel.target_part, src_rel.reltype)
                blip.set(f'{{{ns_r}}}embed', new_rId)
    slide.shapes._spTree.append(new_el)
    return new_el
```

### 3.8 set_table_borders — Table cell borders

```python
def set_table_borders(tbl, n_rows, n_cols):
    from pptx.oxml.ns import qn
    from lxml import etree
    for ri in range(n_rows):
        for ci in range(n_cols):
            tc = tbl.cell(ri, ci)._tc
            tcPr = tc.find(qn("a:tcPr"))
            if tcPr is None:
                tcPr = etree.SubElement(tc, qn("a:tcPr"))
            for edge in ["lnL", "lnR", "lnT", "lnB"]:
                ln = etree.SubElement(tcPr, qn(f"a:{edge}"), w="12700")
                sf = etree.SubElement(ln, qn("a:solidFill"))
                etree.SubElement(sf, qn("a:srgbClr"), val="C8C8C8")
```

---

## 4. Icon Mapping — Use Case Domains to Template Icons

When placing icons on use case slides, use this mapping to select the best template icon:

| Domain / Feature | Icon Name (from template) | Fallback |
|-----------------|--------------------------|----------|
| Predictive Maintenance / ML | `Snowflake Cortex` | `Analytics / Statistics` |
| Quality Analytics / SPC | `Analytics / Statistics` | `Data Analytics Applications` |
| IoT / Sensor / Telemetry | `Snowpark Containers` | `Server` |
| Supply Chain / Procurement | `Snowflake Marketplace` | `Sharing` |
| Production / Manufacturing | `Processes` | `Process` |
| Data Sharing / Collaboration | `Sharing` | `Snowflake Marketplace` |
| Real-time / Streaming | `Dynamic Tables` | `Speed` |
| Security / Compliance / Governance | `Security` | `Snowflake Horizon` |
| Customer 360 / CRM | `Users` | `User` |
| Financial / Revenue | `Cost Savings` | `Pricing` |
| Healthcare / Clinical | `Snowflake Cortex` | `Secure Data` |
| Network / Telecom | `Architecture` | `Performance / Scale` |
| Document / Unstructured | `Document AI` | `Unstructured Data` |
| Search / Discovery | `Universal Search` | `Search` |
| Forecasting / Planning | `Snowflake Cortex` | `Analytics / Statistics` |
| Data Integration / Pipeline | `Integrated Data` | `Data` |
| Marketplace Data | `Snowflake Marketplace` | `Data Monetization` |
| Native App | `Snowflake Native App` | `Application` |
| Geospatial | `Geospatial Analytics` | `Location` |
| Energy / Utilities | `Performance / Scale` | `Operating Snowflake` |

**Usage:**
```python
# Place icon on a use case slide (top-left area)
place_icon(slide, ICON_INDEX, "Snowflake Cortex", 0.50, 1.40, scale=2.5)
```

---

## 5. Slide Blueprint — Value Map Deck Structure

The deck follows this structure. Each slide maps to a section of the value-map study.

### Slide 1: Cover (Layout 13)

```python
slide = prs.slides.add_slide(prs.slide_layouts[13])
set_ph(slide, 3, f"{entity_name.upper()}\nVALUE MAP")  # ≤50 chars, 44pt
set_ph(slide, 0, f"{vertical} | Snowflake Strategic Assessment")  # 18pt subtitle
set_ph(slide, 2, f"Cortex Code  |  {date}")  # 14pt author
```

### Slide 2: Executive Summary (Layout 0 + Stat Callouts)

```python
slide = prs.slides.add_slide(prs.slide_layouts[0])
set_ph(slide, 0, "EXECUTIVE SUMMARY")
set_ph(slide, 1, f"{entity_name} — {vertical} vertical assessment")

# Fit Score callout (large stat)
add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, 0.50, 1.40, 2.20, 1.20,
               f"{fit_score}/10", SF_BLUE, WHITE, font_size=28, bold=True)
add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, 0.50, 2.70, 2.20, 0.40,
               "FIT SCORE", DK2, WHITE, font_size=9, bold=True)

# Classification badges row
x = 3.20
for label, count, fill, text_clr in [
    ("READY", n_ready, TEAL, DK1),
    ("NEAR", n_near, ORANGE, DK1),
    ("GAP", n_gap, ERROR_RED, WHITE),
    ("N/A", n_na, MUTED, DK1),
]:
    add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, x, 1.40, 1.50, 0.60,
                   f"{count}\n{label}", fill, text_clr, font_size=12, bold=True)
    x += 1.65
```

### Slide 3: Strategic Goals (Layout 5 + sections)

```python
slide = prs.slides.add_slide(prs.slide_layouts[5])
set_ph(slide, 0, "STRATEGIC GOALS")
set_ph(slide, 2, f"Inferred from {entity_name} data investment patterns")
# Use set_ph_sections with goals as headings, evidence as bullets
set_ph_sections(slide, 1, [
    (goal_1_text, [evidence_1]),
    (goal_2_text, [evidence_2]),
    (goal_3_text, [evidence_3]),
], heading_size=11, body_size=10)
```

### Slide 4: Fit Matrix Overview (Layout 0 + Table)

```python
slide = prs.slides.add_slide(prs.slide_layouts[0])
set_ph(slide, 0, "USE CASE FIT MATRIX")
set_ph(slide, 1, f"{n_total} canonical use cases assessed")

# Table: Use Case | Classification | Impact | Effort
headers = ["#", "Use Case", "Classification", "Impact", "Effort"]
n_rows = len(use_cases) + 1
tbl_shape = slide.shapes.add_table(
    n_rows, len(headers),
    Inches(0.40), Inches(1.35), Inches(9.10), Inches(0.35 * n_rows))
tbl = tbl_shape.table
# ... populate with colour-coded classification cells ...
```

### Slides 5-N: One Slide Per READY Use Case (Layout 0 + Icon + Feature Pills)

```python
for uc in ready_use_cases:
    slide = prs.slides.add_slide(prs.slide_layouts[0])
    set_ph(slide, 0, uc['name'].upper())
    set_ph(slide, 1, "READY — Deploy Now")
    
    # Icon (top-left)
    icon_name = ICON_MAP.get(uc['domain'], "Data")
    place_icon(slide, ICON_INDEX, icon_name, 0.50, 1.40, scale=2.5)
    
    # Content area (right of icon)
    # Supporting objects
    add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, 1.80, 1.40, 4.50, 0.50,
                   f"Data: {', '.join(uc['supporting_objects'][:3])}", LIGHT_BG, DK1,
                   font_size=9, alignment=PP_ALIGN.LEFT)
    
    # Implementation recommendation
    add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, 1.80, 2.00, 4.50, 0.50,
                   f"Approach: {uc['recommendation']}", LIGHT_BG, DK1,
                   font_size=9, alignment=PP_ALIGN.LEFT)
    
    # Expected outcome callout (right side)
    add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, 6.80, 1.40, 2.60, 1.10,
                   f"{uc['benchmark']}", TEAL, DK1, font_size=10, bold=True)
    add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, 6.80, 2.60, 2.60, 0.35,
                   "INDUSTRY BENCHMARK", DK2, WHITE, font_size=8, bold=True)
    
    # Feature pills row (bottom)
    x = 0.50
    for feat in uc['snowflake_features'][:5]:
        w = max(1.20, len(feat) * 0.09 + 0.30)
        add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, x, 4.30, w, 0.35,
                       feat, SF_BLUE, WHITE, font_size=8, bold=True)
        x += w + 0.15
```

### Slides N+1-M: One Slide Per NEAR Use Case (Layout 6 — Two Columns)

```python
for uc in near_use_cases:
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    set_ph(slide, 0, uc['name'].upper())
    set_ph(slide, 3, "NEAR — Minor Gaps to Close")
    
    # Left column: What You Have
    set_ph_sections(slide, 1, [
        ("What You Have", uc['supporting_objects']),
    ], heading_size=11, body_size=10)
    
    # Right column: Gaps to Close
    set_ph_sections(slide, 2, [
        ("Gaps to Close", uc['gaps']),
        ("Effort", [uc['effort']]),
    ], heading_size=11, body_size=10)
    
    # Feature pills row (bottom) — same pattern as READY slides
    # Place below the columns using add_shape_text
    x = 0.50
    for feat in uc['snowflake_features'][:4]:
        w = max(1.20, len(feat) * 0.09 + 0.30)
        add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, x, 4.50, w, 0.35,
                       feat, ORANGE, DK1, font_size=8, bold=True)
        x += w + 0.15
```

### Slides M+1-P: One Slide Per GAP Use Case (Layout 0 + Path)

```python
for uc in gap_use_cases:
    slide = prs.slides.add_slide(prs.slide_layouts[0])
    set_ph(slide, 0, uc['name'].upper())
    set_ph(slide, 1, "GAP — Strategic Investment Required")
    
    # Missing domains (top section)
    add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, 0.50, 1.40, 5.50, 0.50,
                   f"Missing: {', '.join(uc['missing_domains'])}", LIGHT_BG, DK1,
                   font_size=9, alignment=PP_ALIGN.LEFT)
    
    # Path to deployment (numbered steps)
    for i, step in enumerate(uc['path'][:4]):
        y = 2.10 + i * 0.55
        # Number circle
        add_shape_text(slide, MSO_SHAPE.OVAL, 0.50, y, 0.40, 0.40,
                       str(i + 1), SF_BLUE, WHITE, font_size=12, bold=True)
        # Step text
        add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, 1.05, y, 5.00, 0.45,
                       step, LIGHT_BG, DK1, font_size=9, alignment=PP_ALIGN.LEFT)
    
    # Marketplace callout (right side, if applicable)
    if uc.get('marketplace_opportunity'):
        add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, 6.50, 1.40, 2.90, 1.00,
                       f"MARKETPLACE\n{uc['marketplace_opportunity']}", DK2, WHITE,
                       font_size=9, bold=True)
    
    # Strategic value callout
    add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, 6.50, 2.60, 2.90, 1.20,
                   f"Strategic Value\n{uc['strategic_value']}", VIOLET, WHITE,
                   font_size=9, bold=True)
```

### Slide P+1: Roadmap (Layout 0 + Chevron Process)

```python
slide = prs.slides.add_slide(prs.slide_layouts[0])
set_ph(slide, 0, "IMPLEMENTATION ROADMAP")
set_ph(slide, 1, "Phased approach: quick wins → gap closure → strategic builds")

phases = [
    ("PHASE 1\nQUICK WINS", TEAL, DK1, ready_use_case_names),
    ("PHASE 2\nGAP CLOSURE", ORANGE, DK1, near_use_case_names),
    ("PHASE 3\nSTRATEGIC", DK2, WHITE, gap_use_case_names),
]
n = len(phases)
chev_w = (9.10 - 0.10 * (n - 1)) / n
x = 0.40

for i, (label, fill, text_clr, uc_names) in enumerate(phases):
    # Chevron header
    add_shape_text(slide, MSO_SHAPE.CHEVRON, x, 1.40, chev_w, 0.70,
                   label, fill, text_clr, font_size=11, bold=True)
    # Use case list below
    for j, name in enumerate(uc_names[:3]):
        add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, x, 2.25 + j * 0.55,
                       chev_w, 0.45, name, LIGHT_BG, DK1, font_size=9)
    x += chev_w + 0.10
```

### Slide P+2: Business Impact (Layout 0 + Stat Grid)

```python
slide = prs.slides.add_slide(prs.slide_layouts[0])
set_ph(slide, 0, "BUSINESS IMPACT")
set_ph(slide, 1, "Industry benchmark ranges (not customer-specific)")

# 2x2 stat callout grid
impact_categories = [
    ("REVENUE\nGROWTH", revenue_range, 0.50, 1.40),
    ("COST\nREDUCTION", cost_range, 4.90, 1.40),
    ("RISK\nMITIGATION", risk_range, 0.50, 3.00),
    ("OPERATIONAL\nEFFICIENCY", efficiency_range, 4.90, 3.00),
]
for label, value, x, y in impact_categories:
    add_shape_text(slide, MSO_SHAPE.ROUNDED_RECTANGLE, x, y, 4.10, 1.30,
                   f"{value}\n{label}", SF_BLUE, WHITE, font_size=14, bold=True)
```

### Slide P+3: Thank You / Next Steps (Layout 28)

```python
slide = prs.slides.add_slide(prs.slide_layouts[28])
set_ph(slide, 1, "NEXT\nSTEPS")
```

---

## 6. Deck Generation Script Structure

Every value-map PPTX script MUST follow this order:

```python
# 1. Imports
import os, re, copy
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR, MSO_AUTO_SIZE
from pptx.enum.shapes import MSO_SHAPE, MSO_SHAPE_TYPE
from lxml import etree

# 2. Colour constants (Section 1)

# 3. Template loading (Section "Template Location")

# 4. Load presentation + build icon index BEFORE removing slides
prs = Presentation(TEMPLATE)
ICON_INDEX = build_icon_index(prs)

# 5. Remove all sample slides
while len(prs.slides) > 0:
    sldId = prs.slides._sldIdLst[0]
    rId = (sldId.get('{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id')
           or sldId.get('r:id'))
    if rId:
        prs.part.drop_rel(rId)
    prs.slides._sldIdLst.remove(sldId)

# 6. Helper functions (Section 3)

# 7. Content data structures (from study findings)
entity_name = "..."
vertical = "..."
# ... all use case data ...

# 8. Slide generation (Section 5 blueprint)
# Cover → Exec Summary → Goals → Fit Matrix → READY slides → NEAR slides → GAP slides → Roadmap → Impact → Thank You

# 9. Save
GDRIVE_DIR = os.path.expanduser("~/Google Drive/My Drive")
deck_name = f"{entity_name.lower().replace(' ', '-')}-value-map"
if os.path.isdir(GDRIVE_DIR):
    output_path = os.path.join(GDRIVE_DIR, f"{deck_name}.pptx")
else:
    output_path = os.path.expanduser(f"~/Downloads/{deck_name}.pptx")
prs.save(output_path)
print(f"✓ Saved: {output_path}")
```

---

## 7. Content Rules for Value Map Decks

1. **One use case per slide** — NEVER combine multiple use cases on a single slide
2. **Cover title ≤ 50 chars** — e.g., "APEX MFG\nVALUE MAP" not the full entity name + assessment description
3. **Feature pills** — max 5 per slide, each as a small rounded rectangle badge
4. **Industry benchmarks** — always label as "Industry Benchmark" not "Expected ROI"
5. **Icons on every READY slide** — place the relevant Snowflake icon to add visual interest
6. **Classification colours** — use consistently: TEAL=READY, ORANGE=NEAR, ERROR_RED=GAP, MUTED=N/A
7. **Max 6 body lines per use case** — if more detail needed, prioritize the most impactful points
8. **Roadmap chevrons** — always 3 phases, always in TEAL → ORANGE → DK2 progression
9. **No generic text** — every string must be specific to the entity and use case
10. **≥40% visual slides** — icons + shapes + tables count; pure bullet slides do not

---

## 8. Output Naming & Saving

| Format | File Name | Location |
|--------|-----------|----------|
| PPTX | `<entity-slug>-value-map.pptx` | Google Drive (fallback: ~/Downloads) |
| Markdown | `<entity-slug>-value-map-study.md` | Working directory |
| HTML | `<entity-slug>-value-map-study.html` | Working directory |

---

*Generated for use with the Snowflake Value Map skill — Cortex Code*
