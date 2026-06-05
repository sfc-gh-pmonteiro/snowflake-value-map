# Decisions Log - snowflake-value-map Skill

## Skill Design Decisions

| # | Decision | Options Considered | Chosen | Rationale |
|---|----------|-------------------|--------|-----------|
| 1 | Skill name | `deployment-use-case-xref`, `vertical-fit-analysis`, `strategic-gap-analysis`, `snowflake-value-map` | `snowflake-value-map` | Maps Snowflake capabilities to business value - clearest intent |
| 2 | Installation location | Global (`~/.snowflake/cortex/skills/`), Project-local (`.cortex/skills/`) | Project-local | Scoped to this project for now |
| 3 | Knowledge base approach | Embedded reference KB, Dynamic research each run, Hybrid | Embedded reference KB | Speed - pre-built vertical use case mappings avoid runtime research |
| 4 | Verticals covered | Individual selection | All 5: Healthcare, Financial Services, Retail/CPG, Telecom, Manufacturing | Broad coverage for demo/testing |
| 5 | Output structure | Custom format, Study template | Strategic study pattern: Goals → Gaps → Snowflake Fit → Impact | Matches consulting deliverable format user specified |

## Architecture Decisions

| # | Decision | Chosen | Rationale |
|---|----------|--------|-----------|
| 6 | Skill file structure | SKILL.md + `references/` with verticals, capabilities, and study template | Modular - vertical KBs loadable on demand without bloating main prompt |
| 7 | Use case classification scheme | READY / NEAR / GAP / N/A | Clear actionability signal - maps directly to roadmap phases |
| 8 | Snowflake capabilities as separate reference | Dedicated `snowflake-capabilities.md` | Reusable across verticals, updatable independently |
| 9 | Workflow stopping points | After Step 1 (inventory), Step 4 (findings), Step 5 (final review) | Balances user control with workflow continuity |

## Sample DDL Design Decisions

| # | Decision | Chosen | Rationale |
|---|----------|--------|-----------|
| 10 | Source system simulation | Real-world systems per vertical (SAP, Salesforce, Epic, Amdocs, etc.) | Realistic naming helps skill detect patterns and demonstrate value |
| 11 | Table naming in silver | Prefix with source system (e.g., `SAP_MATERIAL_MASTER`, `EPIC_PATIENT`) | Clearly indicates provenance, aids vertical detection |
| 12 | Gold layer naming | Standard dimensional (`DIM_`, `FACT_`, `AGG_`, `BRIDGE_`) | Universal star schema convention |
| 13 | SCD2 in silver | `VALID_FROM`, `VALID_TO`, `IS_CURRENT` columns | Shows temporal tracking capability for pattern detection |
| 14 | VARIANT columns | Included in each vertical (FHIR payloads, JSON events, etc.) | Tests semi-structured pattern detection |
| 15 | Intentional gaps per vertical | 2-3 missing domains per DDL | Ensures skill produces meaningful GAP classifications during testing |
| 16 | DDL idempotency | `CREATE OR REPLACE TABLE` | Safe for re-execution in Snowsight/CLI |

## Synth Data Generation Decisions

| # | Decision | Chosen | Rationale |
|---|----------|--------|-----------|
| 17 | Date range approach | Dynamic: `DATEADD('year', -5, CURRENT_DATE())` to yesterday | Re-runnable - always produces last 5 years relative to execution time |
| 18 | SQL-only generation | Pure Snowflake SQL (GENERATOR, UNIFORM, NORMAL, RANDOM) | Runs in Snowsight, CLI, any SQL client - no external dependencies |
| 19 | Idempotency pattern | TRUNCATE at top + INSERT | Clean slate each run, no duplicate data on re-execution |
| 20 | Seasonality modeling | `CASE WHEN MONTH(d) IN (...)` multipliers + SIN wave patterns | Realistic without over-engineering |
| 21 | Distribution approach | `NORMAL()` for quantities, `EXP(NORMAL())` for revenue (log-normal) | Power-law/Pareto approximation for financial values |
| 22 | NULL injection | `IFF(UNIFORM(0,100,RANDOM()) < 2, NULL, value)` at 1-3% | Realistic data quality scenarios |
| 23 | Anomaly injection | `IFF(UNIFORM(0,1000,RANDOM()) < 5, value * N, value)` at 0.3-0.5% | Demo-worthy outliers without overwhelming |
| 24 | Volume targets | 50K-200K rows per major fact (XS warehouse friendly) | Fast generation (<5 min), enough for meaningful analysis |
| 25 | YoY growth modeling | `1.0 + rate * DATEDIFF('month',...) / 12` | Compound-ish growth without complexity |

## Bug Fixes Applied

| # | Issue | Fix |
|---|-------|-----|
| 26 | Healthcare synth-gen referenced `APEX_MFG.GOLD.DIM_DATE` | Removed broken block, kept correct `MERIDIAN_HEALTH.GOLD.DIM_DATE` reference |
| 27 | Telecom `HANDOVER_SUCCESS_PCT NUMBER(5,4)` overflow | Changed to `NUMBER(7,4)` - values like 98.65 need 3 digits before decimal |
| 28 | DDL files got line-number prefixes baked in during idempotency script | Stripped with `sed 's/^[0-9]*\.\.\. //'` |

## Report Generation Decisions

| # | Decision | Chosen | Rationale |
|---|----------|--------|-----------|
| 29 | Languages | EN, PT, ES | User requirement - three languages per vertical |
| 30 | Translation approach | Full content translation (not just headers) | Usable deliverable in each language |
| 31 | Report naming | `<entity>-value-map-<LANG>.md` | Clear, sortable, language-identifiable |
| 32 | Execution mode | Background tasks in parallel (5 agents, one per vertical) | Speed - all 15 reports in ~12 minutes |

## V2 Improvement Decisions

| # | Decision | Options Considered | Chosen | Rationale |
|---|----------|-------------------|--------|-----------|
| 33 | Data grounding via live connection | DDL-only (status quo), Mandatory live queries, Optional live queries with graceful degradation | Optional with graceful degradation (Step 1.5) | DDL-only gives false confidence; mandatory breaks offline use. Optional with disclaimer is honest without blocking the workflow. |
| 34 | ROI presentation approach | Remove all numbers, Keep as-is, Reframe as industry benchmarks with calibration guidance | Reframe with explicit "not customer-specific" label + "Calibration Data Needed" column | Numbers have value as directional indicators. Removing them weakens the deliverable. Explicit framing prevents misuse without losing signal. |
| 35 | Unsupported vertical handling | Hallucinate a reference (status quo), Hard stop, User-consented best-effort with disclaimer | User-consented best-effort with banner | Respects user agency. Clear disclaimer prevents silent quality degradation. Hard stop loses value when user is aware of limitations. |
| 36 | Input mode expansion | DDL file only (status quo), Add live discovery, Add multi-file support | All three: DDL file(s) + live account discovery + inline SQL | Real deployments are rarely a single file. Live discovery leverages the existing Snowflake connection. Zero cost to support — just SHOW + GET_DDL. |

## V3 Improvement Decisions

| # | Decision | Options Considered | Chosen | Rationale |
|---|----------|-------------------|--------|-----------|
| 37 | Vertical expansion scope | Add 2-3 most requested, Add all common verticals (7), Wait for user demand | Add 7 new verticals (total 12) | Addresses the "entire addressable market is everything else" criticism. 12 verticals covers ~80% of enterprise Snowflake deployments. Remaining edge cases use best-effort fallback. |
| 38 | Signal detection approach | Flat keyword list (status quo), Weighted scoring with tiers, ML-based classification | Weighted scoring with PRIMARY/SECONDARY/NEGATIVE tiers | Eliminates cross-vertical collision (e.g., "patient" in insurance vs healthcare). Cheap to implement, interpretable, asks user when ambiguous instead of guessing wrong. ML overkill for 12 categories. |
| 39 | Fit score formula | Count-based (status quo), Weighted by impact, Multi-dimensional scoring (data + features + effort) | Weighted by impact (HIGH=3, MED=2, LOW=1 × classification score) | Count-based treats toy use cases same as strategic ones. Multi-dimensional too complex to explain in a deliverable. Impact weighting is the sweet spot: meaningful differentiation, easy to understand. |
| 40 | Health threshold design | Static thresholds for all (status quo), Table-type-aware, User-configurable | Table-type-aware (FACT/DIM/AGG/REF have different expectations) | A 50-row dimension table is healthy; a 50-row fact table is sparse. One-size-fits-all creates false positives on lookups and false negatives on thin facts. |
| 41 | Semantic validation approach | Skip (DDL-only), Full statistical profiling, LIMIT 5 sample check | LIMIT 5 sample check + MISLEADING flag | Full profiling too expensive (100+ queries per table). LIMIT 5 is one query per table, catches obvious problems (all-zero columns, static timestamps). Not perfect but catches the worst cases cheaply. |
| 42 | Marketplace gap-filling | Document as planned (status quo), Implement with cortex search marketplace | Implement live `cortex search marketplace` calls | The tool exists and works. No reason to leave it as vaporware. Upgrades effort category when data is purchasable. |
| 43 | Non-standard naming handling | Assume medallion (status quo), Ask user always, Ask only when ambiguous | Ask when non-standard (no DIM_/FACT_/AGG_/STG_ prefixes detected) AND no helpful comments | Most real-world schemas don't follow textbook naming. Asking is better than guessing wrong. Only asks when genuinely unclear — clean schemas proceed without friction. |
| 44 | Comment-aware discovery | Ignore comments, Parse DDL COMMENT= only, Full comment extraction (DDL + inline SQL + INFORMATION_SCHEMA) | Full comment extraction with ×2 signal weight boost | Comments are intentional human-authored metadata — far more reliable than naming conventions. Source system citations in comments (e.g., "Source: Guidewire ClaimCenter") definitively resolve vertical ambiguity that names alone cannot. Column comments reveal grain and business logic. Inline SQL comments in shared .sql files often document provenance. ×2 boost reflects higher signal confidence vs. bare names. |
| 45 | HTML output format | Markdown only, Optional HTML, Always dual output | Optional HTML (user chooses in Step 5) | HTML is higher-impact for exec delivery but adds generation time. Let user decide per engagement. Design system extracted from production report ensures consistency. |

## V4 PPTX Decisions

| # | Decision | Options Considered | Chosen | Rationale |
|---|----------|-------------------|--------|-----------|
| 46 | PPTX output format | No PPTX (status quo), Always generate PPTX, Optional PPTX (user chooses) | Optional PPTX (user chooses in Step 5) | PPTX is highest-impact for exec presentations but takes longer to generate. One use case per slide makes each slide digestible. User decides format per engagement. |
| 47 | PPTX generation approach | Inline code in SKILL.md, Separate reference file, External script | Self-contained reference file (`references/pptx-generation.md`) | Keeps SKILL.md lean. Reference file is loaded on-demand only when PPTX is requested. Contains all helpers, patterns, icons — no external dependency at runtime. |
| 48 | Template source | Generate from scratch (`Presentation()`), Copy from CoCo_pptx_Skill, Embed minimal template | Copy full Snowflake template into skill's `templates/` folder | Self-contained — skill works without the CoCo_pptx_Skill being installed. Template has 29 layouts and 103 icons baked in. |
| 49 | Slide structure | One slide per section (8 slides), One slide per use case + framing slides, Condensed summary only | One slide per use case + framing slides (~12-18 slides total) | Executive audiences consume one idea per slide. Per-use-case slides allow cherry-picking for tailored presentations. Visual variety via different patterns per classification. |
| 50 | Classification colour mapping | Use Snowflake brand colours only, Custom traffic-light colours, Map to existing palette accents | TEAL=READY, ORANGE=NEAR, ERROR_RED=GAP, MUTED=N/A | Leverages existing Snowflake palette (no custom colours needed). Semantic mapping: green-ish=go, amber=caution, red=stop, grey=skip. All pass contrast checks per fill→text table. |
| 51 | Icon placement on use case slides | No icons (text-only), Icon per slide from domain mapping, Random decorative icons | Domain-specific icon per use case from mapping table | Icons add visual interest and instant domain recognition. Template has 103 icons covering all major Snowflake product areas. Mapping table ensures correct icon per domain. |
| 52 | Feature pills pattern | Bullet list of features, Tags/pills as rounded rectangles, Table column | SF_BLUE rounded rectangle badges (pills) at bottom of slide | Visually distinct from body text. Immediately communicates which Snowflake features enable the use case. Consistent pattern across all use case slides. |
| 53 | Roadmap visual | Table (status quo from markdown), Timeline, Chevron process | 3-phase chevron process with use case names below each phase | Chevrons communicate progression and phasing better than a table. Three phases map directly to READY→NEAR→GAP classification. Familiar consulting pattern. |
