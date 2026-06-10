# Snowflake Value Map

A [Cortex Code](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code) skill that cross-references your silver/gold layer Snowflake deployments against canonical vertical use cases. It produces a strategic study covering: inferred goals, deployment gaps, Snowflake capabilities that close them, and industry-benchmarked business impact.

## Features

- **Automatic vertical detection** -- weighted signal scoring across 12 industries
- **Live data grounding** -- optional row counts, freshness, NULL density, and semantic validation against a live Snowflake connection
- **Use case classification** -- each canonical use case rated READY / NEAR / GAP / N/A with impact-weighted fit scoring (0-10)
- **Multi-format output** -- Markdown (always), interactive HTML with sidebar TOC, or Snowflake-branded PPTX deck
- **Marketplace integration** -- searches Snowflake Marketplace to find data that can close GAP use cases
- **Comment-aware discovery** -- extracts and leverages DDL comments, inline SQL comments, and INFORMATION_SCHEMA metadata

## Supported Verticals

| Vertical | Reference File |
|----------|---------------|
| Healthcare | `references/verticals/healthcare.md` |
| Financial Services | `references/verticals/financial-services.md` |
| Retail / CPG | `references/verticals/retail-cpg.md` |
| Telecom | `references/verticals/telecom.md` |
| Manufacturing | `references/verticals/manufacturing.md` |
| Insurance | `references/verticals/insurance.md` |
| Energy & Utilities | `references/verticals/energy-utilities.md` |
| Media & Entertainment | `references/verticals/media-entertainment.md` |
| Life Sciences & Pharma | `references/verticals/life-sciences-pharma.md` |
| Logistics & Transportation | `references/verticals/logistics-transportation.md` |
| Public Sector | `references/verticals/public-sector.md` |
| Technology / SaaS | `references/verticals/technology-saas.md` |

Each vertical includes 10 canonical use cases with required data domains, Snowflake feature mappings, impact weights, and industry benchmark ranges.

## Installation

Copy or symlink this directory into your Cortex Code skills folder:

```bash
cp -r snowflake-value-map ~/.snowflake/cortex/skills/snowflake-value-map
```

Or for project-local use:

```bash
cp -r snowflake-value-map .cortex/skills/snowflake-value-map
```

## Usage

Invoke in Cortex Code with:

```
$snowflake-value-map
```

Or use any of the natural-language triggers:
`value-map`, `use-case-xref`, `vertical-fit`, `gap-analysis`, `deployment-analysis`, `strategic-assessment`

### Input modes

1. **DDL file(s)** -- provide `.sql` files with CREATE TABLE statements
2. **Live account discovery** -- say "analyze my account" or name a database/schema; the skill runs `SHOW TABLES` + `GET_DDL` automatically
3. **Inline SQL** -- paste CREATE TABLE statements directly in chat

## Workflow

```
Input (DDL / live discovery / inline SQL)
  |
  v
Step 1 -- Parse & catalog deployment (inventory + vertical detection)
  |       [STOP: confirm inventory and vertical]
  v
Step 1.5 -- Data grounding (live connection only: health checks)
  |          [STOP: present health findings]
  v
Step 2 -- Load vertical use case reference (10 canonical use cases)
  |
  v
Step 3 -- Cross-reference & match (READY / NEAR / GAP / N/A + fit score)
  |
  v
Step 4 -- Research feasibility & impact (benchmarks + Marketplace search)
  |       [STOP: validate findings]
  v
Step 5 -- Produce strategic study (Markdown + optional HTML / PPTX)
          [STOP: final review]
```

## Output Formats

| Format | File | Description |
|--------|------|-------------|
| Markdown | `<entity>-value-map-study.md` | Full study with 8 sections (always generated) |
| HTML | `<entity>-value-map-study.html` | Interactive single-page with sidebar TOC, classification badges, scroll-spy |
| PPTX | `<entity>-value-map.pptx` | Snowflake-branded deck -- one use case per slide, icons, feature pills, chevron roadmap |

## Project Structure

```
snowflake-value-map/
├── SKILL.md                          # Main skill workflow (5 steps, 4 stopping points)
├── references/
│   ├── snowflake-capabilities.md     # 38 Snowflake features mapped to patterns and gaps
│   ├── study-template.md             # Markdown output template (8 sections)
│   ├── study-template.html           # HTML design system (sidebar, badges, cards, pills)
│   ├── pptx-generation.md            # PPTX generation reference (helpers, icons, blueprint)
│   └── verticals/                    # 12 vertical use case catalogs
│       ├── healthcare.md
│       ├── financial-services.md
│       └── ...
├── samples-DDL/                      # Sample DDL + synthetic data generators (12 verticals)
│   ├── <vertical>-ddl.sql            # CREATE TABLE statements
│   └── <vertical>-synth-gen.sql      # 5-year synthetic data (pure SQL, idempotent)
├── templates/
│   └── snowflake_template.pptx       # Snowflake corporate PPTX template (29 layouts, 103 icons)
├── logbook/
│   ├── CONTEXT.md                    # Project context and changelog
│   └── DECISIONS.md                  # Architecture decision log (53 decisions)
├── LICENSE                           # MIT
└── README.md                         # This file
```

## Sample DDL

The `samples-DDL/` directory contains DDL and synthetic data generators for all 12 verticals. Use these to test the skill or demo its capabilities:

```bash
# Example: load healthcare sample into Snowflake
snowsql -f samples-DDL/healthcare-ddl.sql
snowsql -f samples-DDL/healthcare-synth-gen.sql
```

Synth-gen properties:

- 5 years of data (dynamic from `CURRENT_DATE`)
- Pure SQL (no external dependencies)
- Idempotent (TRUNCATE + INSERT)
- Realistic distributions (log-normal revenue, seasonal patterns, 1-3% NULLs, 0.3-0.5% anomalies)

## Known Limitations

- Mixed-vertical DDLs produce separate assessments (not consolidated)
- Impact estimates use industry averages -- explicitly labeled, not entity-specific
- Semantic validation (`MISLEADING` check) uses a `LIMIT 5` sample -- may miss issues in larger datasets
- Data grounding requires a live Snowflake connection; degrades gracefully with a DDL-only disclaimer
- Comment extraction depends on well-formatted `COMMENT =` clauses; minified DDL may lack them
- Column-level INFORMATION_SCHEMA comments require SELECT privilege on the schema

## License

[MIT](LICENSE)
