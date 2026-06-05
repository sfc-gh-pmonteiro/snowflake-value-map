---
name: snowflake-value-map
description: "Cross-reference user silver/gold layer deployments against typical vertical use cases. Identifies strategic goals, gaps, Snowflake fit, and business impact. Use when: user provides DDL/SQL with data layer definitions and wants use case mapping, gap analysis, feasibility study, or value assessment. Triggers: value-map, use-case-xref, vertical-fit, gap-analysis, deployment-analysis, strategic-assessment."
---

# Snowflake Value Map

Cross-reference silver/gold layer deployments with typical vertical use cases. Produce a strategic study: goals, gaps, Snowflake capabilities, business impact.

## Input

User provides ONE of:
1. **DDL file(s)**: One or more .sql files with CREATE TABLE statements
2. **Live account discovery**: User says "analyze my account" or provides database/schema names → skill runs `SHOW TABLES IN SCHEMA` + `GET_DDL('TABLE', ...)` to extract DDL automatically
3. **Inline SQL**: Pasted CREATE TABLE statements directly in chat

For mode 2 (live discovery):
- Ask user which database(s)/schema(s) to analyze
- Run `SHOW TABLES IN SCHEMA <db>.<schema>` to enumerate objects
- Run `SELECT GET_DDL('TABLE', '<db>.<schema>.<table>')` for each table
- **Extract metadata comments:**
  ```sql
  -- Table-level comments
  SELECT TABLE_NAME, COMMENT 
  FROM <db>.INFORMATION_SCHEMA.TABLES 
  WHERE TABLE_SCHEMA = '<schema>' AND COMMENT IS NOT NULL;

  -- Column-level comments
  SELECT TABLE_NAME, COLUMN_NAME, COMMENT 
  FROM <db>.INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = '<schema>' AND COMMENT IS NOT NULL;
  ```
- Proceed with Step 1 as normal using extracted DDL + comments

Optionally user provides:
- Target vertical (auto-detected if not specified)
- Entity name (company/org being assessed)
- Known strategic goals

## Workflow

### Step 1: Parse & Catalog Deployment

**Actions:**

1. **Read** the DDL input (file(s), live discovery output, or inline SQL). If multiple files, concatenate and deduplicate.
2. **Extract comments** from all available sources:
   - **DDL `COMMENT =` clauses**: Parse `COMMENT = '...'` on CREATE TABLE/VIEW statements
   - **Inline SQL comments**: Parse `-- Source: ...`, `-- Description: ...`, and any `--` comments adjacent to column definitions
   - **Live metadata** (if available): Table and column comments from INFORMATION_SCHEMA queries above
   
   Build a comment registry:
   | Object | Comment Source | Comment Text |
   |--------|--------------|--------------|
   
3. **Use comments to inform classification:**
   - **Silver/Gold layer**: Comments containing "raw", "staging", "cleaned", "conformed", "source:" → Silver. Comments containing "mart", "aggregate", "business", "reporting", "summary" → Gold.
   - **Table type**: Comments like "daily snapshot", "append-only", "SCD Type 2", "lookup", "reference", "dimension", "fact" directly classify the table.
   - **Grain**: Comments stating "one row per customer per day" or "grain: order line" provide explicit grain.
   - **Domain**: Comments citing source systems ("Source: SAP PM", "Source: Epic EHR", "From Stripe billing") directly reveal the domain.
   - If comments resolve layer/type/grain ambiguity, DO NOT ask the user — trust the comment.

4. **Extract** all table/view definitions, categorizing into:
   - **Silver layer**: Cleaned, conformed data (identify by naming convention, schema, comment, or user indication)
   - **Gold layer**: Business-ready aggregates, dimensions, facts
   - If naming is non-standard AND no helpful comments exist, ASK the user which objects are silver vs. gold.
5. **Classify table type** for each object (comments override name-based inference):
   - **FACT**: Event/transaction grain, append pattern, high-volume expected
   - **DIMENSION**: Entity grain, SCD pattern, low-volume expected
   - **AGGREGATE**: Pre-computed rollup, periodic refresh
   - **REFERENCE**: Lookup/code table, rarely changes
6. **Build inventory table**:

| Layer | Object Name | Table Type | Key Columns | Grain | Domain | Data Patterns | Comment Summary |
|-------|-------------|-----------|-------------|-------|--------|---------------|-----------------|

7. **Identify data domains** present: customer, product, transaction, clinical, financial, network, IoT, etc.
8. **Detect vertical using weighted signal scoring:**

   For each of the 12 supported verticals, load the `## Vertical Signals` section from `references/verticals/<vertical>.md` and compute:

   ```
   score = (count_of_PRIMARY_matches × 3) + (count_of_SECONDARY_matches × 1) + (count_of_NEGATIVE_matches × -2)
   ```
   
   **Signal sources and weight multipliers:**
   - Match in **table/column/schema name** → base weight (×1)
   - Match in **table COMMENT or column COMMENT** → boosted weight (×2)
   - Match in **inline SQL comment** (e.g., `-- Source: Guidewire ClaimCenter`) → boosted weight (×2)
   
   ```
   normalized_score = score / max_possible_score_for_vertical
   ```

   Comments are especially valuable for disambiguation: a table named `CLAIM` could be insurance or healthcare, but `COMMENT = 'Guidewire ClaimCenter - P&C claims'` resolves to insurance definitively.

   - If top vertical's normalized_score > 0.3 AND leads second-place by >20% → auto-detect that vertical
   - If top-2 verticals are within 20% of each other → present both to user with evidence and ask to disambiguate
   - If NO vertical scores above 0.15 → state: "No strong vertical signal detected. Supported verticals: [list all 12]. Would you like best-effort analysis using general knowledge?"

**Output:** Deployment inventory + detected vertical (with signal evidence) + table type classifications

**STOP**: Present inventory, detected vertical with top-3 scores and matching signals, and ask user for confirmation before proceeding.

### Step 1.5: Data Grounding (Live Connection)

**Condition:** Run this step ONLY if user has an active Snowflake connection AND the cataloged tables exist in the account. Skip if input was DDL-only with no live environment.

**Actions:**

1. **For each cataloged table**, run health checks:
   ```sql
   SELECT COUNT(*) AS row_count,
          MAX(<best_timestamp_col>) AS last_updated
   FROM <table>;
   ```
   Where `<best_timestamp_col>` is `_LOADED_AT`, or most recent TIMESTAMP column, or fallback to any date column.

2. **For key columns** (identified in Step 1 grain/domain analysis), check NULL density:
   ```sql
   SELECT '<col>' AS col_name,
          COUNT(*) AS total,
          SUM(CASE WHEN <col> IS NULL THEN 1 ELSE 0 END) AS null_count
   FROM <table>;
   ```

3. **Classify table health using table-type-aware thresholds** (table type determined in Step 1):

   | Table Type | Healthy Min Rows | Stale After | Sparse Threshold | Notes |
   |---|---|---|---|---|
   | FACT | >10,000 | 7 days | <500 rows | High-volume event/transaction tables |
   | DIMENSION | >50 | 90 days | <10 rows | Entities change slowly |
   | AGGREGATE | >100 | 30 days | <20 rows | Refresh frequency varies |
   | REFERENCE | >5 | 365 days | 0 rows | Code tables rarely change |

   Health classifications:
   - **HEALTHY**: Exceeds min rows for type, fresher than stale threshold, <5% NULLs on key columns
   - **STALE**: Exceeds min rows but older than stale threshold for its type
   - **SPARSE**: Below sparse threshold for its type (likely test/seed data)
   - **HOLLOW**: 0 rows (table exists but empty)
   - **DEGRADED**: >20% NULLs on key columns
   - **MISLEADING**: Sample data contradicts schema's apparent purpose (see step 4 below)

4. **Semantic validation** — for each table, run:
   ```sql
   SELECT * FROM <table> LIMIT 5;
   ```
   Check: Does the sample data match what the column names promise? Flag as **MISLEADING** if:
   - A column named REVENUE/AMOUNT/COST contains all zeros or a single repeated value
   - A TIMESTAMP/DATE column has identical values across all rows (synthetic placeholder)
   - A column clearly intended as a foreign key (ending in _ID, _KEY) contains NULLs or a single value for all rows
   - Numeric columns that should vary (measures) show zero variance in the sample

5. **Add health to inventory table:**

| Layer | Object Name | Table Type | Key Columns | Grain | Domain | Data Patterns | Rows | Freshness | Health |
|-------|-------------|-----------|-------------|-------|--------|---------------|------|-----------|--------|

6. **Downstream impact on classification (Step 3):**
   - HOLLOW/SPARSE tables → treat as non-existent for READY/NEAR/GAP determination
   - STALE tables → downgrade readiness by one level (READY→NEAR, NEAR→GAP)
   - DEGRADED tables → flag in Gap Analysis with specific columns affected
   - MISLEADING tables → treat as GAP (data exists structurally but cannot support the use case)

**If NO live connection available:** Skip this step entirely. Add disclaimer banner to final output:
> ⚠ DDL-ONLY ASSESSMENT: This analysis is based on table structure alone. Data volumes, freshness, and quality were not validated against a live environment.

### Step 2: Load Vertical Use Case Reference

**Actions:**

1. **Load** the matching vertical reference file from `references/verticals/<vertical>.md`
2. If vertical not covered by a reference file:
   a. State clearly: "This vertical does not have a pre-built use case catalog. Supported: Healthcare, Financial Services, Retail/CPG, Telecom, Manufacturing, Insurance, Energy & Utilities, Media & Entertainment, Life Sciences & Pharma, Logistics & Transportation, Public Sector, Technology/SaaS."
   b. ASK user: "Would you like a best-effort analysis using general knowledge? Results will be less precise than supported verticals."
   c. If user agrees → produce analysis with banner: "⚠ UNSUPPORTED VERTICAL: Uses general industry knowledge, not a validated use case catalog."
   d. If user declines → end workflow, suggest which supported vertical is closest match.
3. **Extract** the canonical use case catalog for that vertical with:
   - Use case name
   - Required data domains
   - Required data patterns (SCD, time-series, graph, real-time, etc.)
   - Typical Snowflake features leveraged
   - Business outcome category

### Step 3: Cross-Reference & Match

**Actions:**

1. **For each canonical use case**, evaluate against the deployment inventory:
   - **Data availability**: Are required domains/entities present in silver/gold?
   - **Data health** (if Step 1.5 was performed): Are supporting tables HEALTHY? Factor HOLLOW/SPARSE/STALE/DEGRADED/MISLEADING into classification.
   - **Pattern readiness**: Do existing tables support required patterns (SCD2, streaming, semi-structured)?
   - **Feature alignment**: Which Snowflake features are already leveraged vs. needed?
2. **Classify each use case** into:
   - **READY**: Data + patterns exist. Deployment feasible now.
   - **NEAR**: Most data exists. Minor gaps (missing columns, additional transforms, new features to enable).
   - **GAP**: Significant data or capability gaps requiring new sources or major architecture changes.
   - **NOT APPLICABLE**: Use case doesn't align with entity's data footprint.

3. **For READY/NEAR cases**, identify:
   - Specific tables/views that support the use case
   - Missing pieces (if NEAR)
   - Recommended Snowflake features to enable

4. **For GAP cases**, identify:
   - What data sources are missing
   - What architectural changes are needed
   - Effort category (Low/Medium/High)
   - Whether Snowflake Marketplace can fill data gaps

5. **Compute Weighted Fit Score:**

   Each use case has an `Impact Weight` in the vertical reference (HIGH=3, MEDIUM=2, LOW=1).
   Each classification has a score: READY=1.0, NEAR=0.6, GAP=0.1, N/A=0.

   ```
   fit_score = (Σ impact_weight × classification_score) / (Σ impact_weight) × 10
   ```

   This produces a 0-10 score where HIGH-impact READY use cases contribute more than LOW-impact NEAR ones.

   Also compute breakdown:
   ```
   weighted_ready  = Σ(impact_weight for READY cases)  / Σ(all impact_weights)
   weighted_near   = Σ(impact_weight for NEAR cases)   / Σ(all impact_weights)
   weighted_gap    = Σ(impact_weight for GAP cases)    / Σ(all impact_weights)
   ```

   Present as: "Fit Score: X.X / 10 (Y% of strategic value deployable now, Z% near-term)"

### Step 4: Research Feasibility & Impact

**Actions:**

1. **For each READY/NEAR use case**, research:
   - Industry benchmark ranges (from vertical reference)
   - Snowflake-specific acceleration (Cortex AI, Dynamic Tables, Snowpark, etc.)
   - Implementation complexity
2. **For GAP use cases**, research Marketplace data availability:
   - Run `cortex search marketplace "<missing_domain> <vertical>"` for each major data gap
   - Record listing names, providers, and relevance to the gap
   - If Marketplace listings can fill a gap, upgrade the use case's effort category (e.g., High→Medium if data is purchasable)
   - Also check `references/verticals/<vertical>.md` → `## Marketplace Opportunities` for curated suggestions
   - Note: Partner solutions and alternative approaches within current deployment
3. **Present impact as industry benchmarks**, NOT entity-specific projections:
   - Always prefix with "Industry benchmarks suggest..." 
   - Identify what entity-specific data would be needed to calibrate (e.g., "requires actual maintenance spend figures")
   - Use ranges, never point estimates
   - Impact categories: Revenue, Cost Reduction, Risk Mitigation, Operational Efficiency
   - Do NOT include a "Confidence" column — the confidence is inherently low without entity calibration

**STOP**: Present findings summary to user. Ask if they want to focus on specific use cases or adjust priorities.

### Step 5: Produce Strategic Study

**Actions:**

1. **Structure output** following the study template (`references/study-template.md`):

```
## Executive Summary
[Entity] | [Vertical] | [Date]
Quick summary of fit score and top opportunities.

## 1. Entity Strategic Goals
Inferred or stated goals based on data investment patterns.

## 2. Current Deployment Assessment
Silver/Gold inventory with capability mapping.

## 3. Use Case Fit Matrix
Full classification table: READY / NEAR / GAP / N/A per use case.

## 4. Gap Analysis
For each GAP: what's missing, why it matters, how to close it.

## 5. Snowflake Value Proposition
How Snowflake features specifically address each gap.
Map features -> gaps -> business outcomes.

## 6. Business Impact Assessment
Per use case: impact category, industry benchmark range, calibration data needed.

## 7. Recommended Roadmap
Prioritized sequence: Quick wins (READY) -> Near-term (NEAR) -> Strategic (GAP).

## 8. Appendix
- Full data inventory
- Feature capability matrix
- Marketplace opportunities identified
```

2. **Ask user:** "Output format: Markdown only, HTML, PPTX, or combination?"
3. **Write** the study to a markdown file: `<entity-name>-value-map-study.md`
4. **If HTML requested:** Also produce `<entity-name>-value-map-study.html` using the design system from `references/study-template.html`:
   - Preserve exact CSS (sidebar, badges, cards, pills, phases, score cards)
   - Generate sidebar nav from section headings
   - Use `.badge-ready`, `.badge-near`, `.badge-gap`, `.badge-na` for classifications
   - Use `.uc-card` blocks for READY/NEAR use cases (`.uc-card.near` for NEAR)
   - Use `.pill` spans for Snowflake features
   - Use `.phase-header.phase-1/2/3` for roadmap phases
   - Use `.effort-low/med/high` for effort indicators
   - Include scroll-spy JS
5. **If PPTX requested:** Also produce `<entity-name>-value-map.pptx` using `references/pptx-generation.md`:
   - Load the reference file for full generation instructions (helpers, icons, slide blueprint)
   - Generate a Python script following the blueprint: Cover → Exec Summary → Strategic Goals → Fit Matrix → **one slide per use case** → Roadmap → Business Impact → Thank You
   - **One use case per slide**: READY slides use icon + feature pills + benchmark callout. NEAR slides use 2-column (have vs gaps). GAP slides show path + marketplace + strategic value.
   - Use Snowflake template icons via `place_icon()` for visual impact on every use case slide
   - Classification colour coding: TEAL=READY, ORANGE=NEAR, ERROR_RED=GAP, MUTED=N/A
   - Feature pills as SF_BLUE rounded rectangle badges below each use case
   - Roadmap slide uses chevron process pattern (Phase 1→2→3)
   - Ensure ≥40% of content slides have visual elements (icons, shapes, stat callouts)
   - Run `python-pptx` script via bash, save to Google Drive (fallback: ~/Downloads)
6. **Present** executive summary to user

**STOP**: Final review. User approves or requests revisions.

## Stopping Points

- After Step 1: Confirm deployment inventory and vertical detection
- After Step 1.5: Present data health findings (if live connection available)
- After Step 4: Validate findings before producing final study
- After Step 5: Final review of complete study

## Output

- **Always:** Markdown file `<entity-name>-value-map-study.md`
- **If requested:** HTML file `<entity-name>-value-map-study.html` (uses `references/study-template.html` design system)
- **If requested:** PPTX file `<entity-name>-value-map.pptx` (uses `references/pptx-generation.md` — Snowflake-branded deck, one use case per slide, icons + feature pills)

## Capabilities Reference

Load `references/snowflake-capabilities.md` when mapping features to gaps.

## Error Handling

- **No DDL provided**: Ask user to provide DDL.SQL file or paste table definitions
- **Vertical not recognized**: Present detected domains, ask user to specify vertical
- **Ambiguous layer classification**: Ask user to confirm which schema/tables are silver vs gold
- **Mixed verticals**: Produce separate assessments per vertical, then a consolidated view
