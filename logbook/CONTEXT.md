# Context - snowflake-value-map Skill

## What This Is

A Cortex Code skill that cross-references customer silver/gold layer Snowflake deployments against canonical vertical use cases. Produces a strategic study documenting: entity goals, deployment gaps, how Snowflake addresses them, and business impact.

## File Structure

```
.cortex/skills/snowflake-value-map/
├── SKILL.md                                    # Main workflow (5 steps, 4 stopping points)
├── references/
│   ├── snowflake-capabilities.md              # 293 lines - Feature→Pattern→Gap mapping
│   ├── study-template.md                      # Output document structure
│   ├── pptx-generation.md                     # PPTX deck generation reference (NEW v4)
│   └── verticals/                             # 12 vertical reference files
│       ├── healthcare.md                      # 10 use cases + compliance + marketplace
│       ├── financial-services.md              # 10 use cases + compliance + marketplace
│       ├── retail-cpg.md                      # 10 use cases + compliance + marketplace
│       ├── telecom.md                         # 10 use cases + compliance + marketplace
│       ├── manufacturing.md                   # 10 use cases + compliance + marketplace
│       ├── insurance.md                       # 10 use cases + compliance + marketplace (NEW v3)
│       ├── energy-utilities.md                # 10 use cases + compliance + marketplace (NEW v3)
│       ├── media-entertainment.md             # 10 use cases + compliance + marketplace (NEW v3)
│       ├── life-sciences-pharma.md            # 10 use cases + compliance + marketplace (NEW v3)
│       ├── logistics-transportation.md        # 10 use cases + compliance + marketplace (NEW v3)
│       ├── public-sector.md                   # 10 use cases + compliance + marketplace (NEW v3)
│       └── technology-saas.md                 # 10 use cases + compliance + marketplace (NEW v3)
├── templates/
│   └── snowflake_template.pptx               # Snowflake corporate PPTX template (NEW v4)
├── logbook/
│   ├── CONTEXT.md                             # This file
│   └── DECISIONS.md                           # All design decisions
├── samples-DDL/                               # DDL + synth-gen for 5 original verticals
│   ├── manufacturing-ddl.sql
│   ├── healthcare-ddl.sql
│   ├── retail-cpg-ddl.sql
│   ├── financial-services-ddl.sql
│   ├── telecom-ddl.sql
│   └── *-synth-gen.sql                        # Dynamic 5yr synthetic data (pure SQL)
└── samples-REPORTS/                           # 15 generated sample reports (5 verticals × 3 languages)
    └── *-value-map-{EN,PT,ES}.md
```

## Workflow Summary

```
User provides DDL.SQL → 
  Step 1: Parse tables, classify silver/gold, detect vertical →
  Step 2: Load matching vertical reference KB →
  Step 3: X-ref each canonical use case (READY/NEAR/GAP/N/A) →
  Step 4: Research feasibility + impact per use case →
  Step 5: Produce strategic study markdown
```

## Output Design Pattern

**Entity Strategic Goals** → **Gaps** → **How Snowflake Helps** → **Business Impact**

**Output Formats** (user chooses in Step 5):
- **Markdown** (always): Full study document
- **HTML** (optional): Interactive single-page with sidebar TOC, classification badges, scroll-spy
- **PPTX** (optional): Snowflake-branded deck — one use case per slide, icons, feature pills, chevron roadmap. Uses `python-pptx` with official Snowflake template.

## Key Design Patterns

- **Vertical detection**: Weighted signal scoring — PRIMARY (unique, ×3), SECONDARY (shared, ×1), NEGATIVE (contradicts, ×-2). Disambiguation when top-2 are within 20%.
- **Use case classification**: READY (data exists), NEAR (minor gaps), GAP (major investment), N/A (irrelevant)
- **Fit scoring**: Impact-weighted formula — HIGH=3, MEDIUM=2, LOW=1 per use case. Score = Σ(weight × class_score) / Σ(weights) × 10
- **Health assessment**: Table-type-aware thresholds (FACT/DIM/AGG/REF have different expectations) + semantic MISLEADING check
- **Impact quantification**: Industry ROI benchmarks embedded in vertical references — explicitly NOT customer-specific
- **Roadmap phasing**: Phase 1 = READY quick wins, Phase 2 = NEAR gap closure, Phase 3 = GAP strategic builds

## Snowflake Capabilities Covered (references/snowflake-capabilities.md)

**AI/ML (17 entries):** Cortex ML (Forecasting, Anomaly, Classification, Top Insights), Cortex AI (LLM Functions, EMBED, Fine-Tuning), Cortex Agents, Cortex Analyst, Cortex Search, Document AI, Semantic Views, Snowflake Intelligence, Snowpark ML, Feature Store, Notebooks, SPCS, Cortex Guard

**Platform (4):** Dynamic Tables, Streams & Tasks, Snowpipe Streaming, Time Travel & Cloning

**Collaboration (3):** Secure Data Sharing, Data Clean Rooms, Marketplace

**Governance (3):** RLS & Masking, Lineage, Object Tagging

**Performance (3):** Materialized Views, Search Optimization, Clustering

**Semi-Structured (3):** VARIANT, Geospatial, Alerts

**Engineering & Apps (5):** Native Apps, Iceberg, Snowpark, Streamlit, External Functions

**Architecture Patterns (4):** Medallion, Data Mesh, Lambda/Kappa, AI-Native, RAG

## Synth Data Properties

- **Date range**: Dynamic last 5 years from `CURRENT_DATE() - 1`
- **Idempotent**: TRUNCATE + INSERT, re-runnable
- **Pure SQL**: No external tools, runs in Snowsight/CLI
- **Seasonality**: US calendar (holidays, fiscal quarters, industry cycles)
- **Distributions**: Normal (quantities), Log-normal (revenue), Power-law approximation
- **Data quality**: 1-3% NULLs, 0.3-0.5% anomalies
- **Growth**: YoY trends modeled per metric

## Snowflake Databases Created (PAULO account)

| Database | Vertical | Silver Tables | Gold Tables |
|----------|----------|:---:|:---:|
| `APEX_MFG` | Manufacturing | 14 | 11 |
| `MERIDIAN_HEALTH` | Healthcare | 12 | 11 |
| `SUMMIT_RETAIL` | Retail/CPG | 11 | 12 |
| `PINNACLE_FIN` | Financial Services | 12 | 13 |
| `HORIZON_TELCO` | Telecom | 12 | 13 |

## Invocation

```
$snowflake-value-map
```

Or naturally via: "value-map", "vertical-fit", "gap-analysis", "deployment-analysis", "strategic-assessment"

## Test Results (all passing)

| Vertical | Fit Score | READY | NEAR | GAP | N/A |
|----------|:---------:|:---:|:---:|:---:|:---:|
| Manufacturing | 8/10 | 4 | 4 | 2 | 0 |
| Healthcare | 7/10 | 5 | 2 | 2 | 1 |
| Retail/CPG | 8/10 | 5 | 3 | 2 | 0 |
| Financial Services | 7/10 | 4 | 3 | 2 | 1 |
| Telecom | 8/10 | 5 | 3 | 2 | 0 |

## Known Limitations

- Mixed-vertical DDLs produce separate assessments (not yet implemented)
- Impact estimates use industry averages — explicitly labeled as such with calibration guidance
- Semantic validation (MISLEADING check) depends on LIMIT 5 sample — may miss issues in larger dataset
- Data grounding (Step 1.5) requires live Snowflake connection; degrades gracefully to DDL-only with banner
- Comment extraction from DDL files depends on well-formatted COMMENT = clauses; minified/generated DDL may lack them
- Column-level INFORMATION_SCHEMA comments require SELECT privilege on the schema

## V2 Changes (2026-05-20)

1. **Data Grounding (Step 1.5)**: Optional live-connection validation — row counts, freshness, NULL density. Classifies tables as HEALTHY/STALE/SPARSE/HOLLOW/DEGRADED. Adjusts downstream READY/NEAR/GAP classification. Graceful degradation with DDL-only disclaimer if no connection.
2. **ROI Honesty**: Renamed "Typical ROI" → "Industry Benchmark (not customer-specific)" in all vertical references. Study template Section 6 now has mandatory disclaimer and "Calibration Data Needed" column. Step 4 instructions prohibit presenting benchmarks as entity-specific projections.
3. **Vertical Fallback**: Unsupported verticals no longer silently hallucinate. Explicit user consent required with accuracy disclaimer banner.
4. **Multi-Input Support**: Now accepts DDL file(s), live account discovery (SHOW TABLES + GET_DDL), or inline SQL. Step 1 handles deduplication across multiple inputs.

## V3 Changes (2026-05-21)

1. **12 Verticals**: Added Insurance, Energy & Utilities, Media & Entertainment, Life Sciences & Pharma, Logistics & Transportation, Public Sector, Technology/SaaS. Total: 12 supported verticals with pre-built use case catalogs.
2. **Weighted Signal Detection**: Replaced flat keyword matching with PRIMARY (weight 3) / SECONDARY (weight 1) / NEGATIVE (weight -2) signal scoring. Auto-detects when clear winner; asks user to disambiguate when top-2 are close. Eliminates cross-vertical signal collision.
3. **Comment-Aware Discovery**: Extracts comments from three sources: DDL `COMMENT =` clauses, inline SQL comments (`-- Source: ...`), and live INFORMATION_SCHEMA metadata. Comments get ×2 weight boost in signal scoring. Comments also directly inform layer classification, table type, grain detection, and domain identification — reducing need to ask user.
4. **Weighted Fit Score**: Replaced naive count-based score with impact-weighted formula. Each use case has Impact Weight (HIGH=3, MEDIUM=2, LOW=1). Score reflects strategic value coverage, not just use case count.
5. **Table-Type-Aware Health Thresholds**: FACT tables expect >10K rows / 7-day freshness. DIMENSION tables expect >50 rows / 90-day freshness. REFERENCE tables expect >5 rows / 365 days. Eliminates false positives on low-volume lookup tables.
6. **Semantic Validation (MISLEADING)**: New health classification. LIMIT 5 sample check catches tables where data contradicts schema (all-zero revenue columns, static timestamps, single-value FKs). MISLEADING tables treated as GAP.
7. **Marketplace Integration (live)**: Step 4 now runs `cortex search marketplace` for GAP use cases instead of noting it as "planned." Results feed into gap-closing recommendations.
8. **Table Type Classification**: Step 1 now classifies objects as FACT/DIMENSION/AGGREGATE/REFERENCE to drive type-aware thresholds and improve health assessment.
9. **HTML Output**: Optional HTML format using extracted design system (sidebar TOC, scroll-spy, classification badges, use case cards, feature pills, phase headers). Template at `references/study-template.html`.
10. **Sample DDL/Synth-Gen for All 12 Verticals**: Added 7 new DDL + synth-gen pairs (insurance, energy, media, life-sciences, logistics, public-sector, tech-saas). All follow existing patterns.

## V4 Changes (2026-05-21)

1. **PPTX Output**: New optional output format — Snowflake-branded PowerPoint deck generated via `python-pptx`. Uses the official Snowflake corporate template (`templates/snowflake_template.pptx`) with 29 layouts and 103 embedded vector icons.
2. **One Use Case Per Slide**: Each use case gets a dedicated slide with domain-specific icon, feature pills (SF_BLUE badges), and industry benchmark callout. READY/NEAR/GAP slides have distinct visual patterns.
3. **Icon Integration**: Template icons (Snowflake Cortex, Dynamic Tables, Marketplace, etc.) placed on use case slides via `place_icon()`. Domain-to-icon mapping table in reference file.
4. **Classification Colour System**: TEAL=READY, ORANGE=NEAR, ERROR_RED=GAP, MUTED=N/A — used consistently in badges, chevrons, and callout shapes.
5. **Chevron Roadmap Slide**: Three-phase roadmap using chevron process pattern (Phase 1 TEAL → Phase 2 ORANGE → Phase 3 DK2) with use case names listed under each phase.
6. **Stat Callout Slides**: Executive summary uses stat callout grid (fit score + classification counts). Business impact uses 2×2 stat grid (revenue/cost/risk/efficiency ranges).
7. **Reference File**: Full self-contained `references/pptx-generation.md` with all helper functions, icon mapping, slide blueprint, colour constants, and content rules. No dependency on the separate CoCo_pptx_Skill at runtime.
