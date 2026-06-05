# Study Output Template

Use this structure for the final deliverable. Replace bracketed items with actual content.

---

# [Entity Name] - Snowflake Value Map Study

**Vertical:** [Detected Vertical]
**Assessment Date:** [Date]
**Deployment Scope:** [# Silver tables] silver, [# Gold tables] gold

---

## Executive Summary

[2-3 sentences: Overall fit score (X of Y use cases addressable), top 3 opportunities, key recommendation]

**Fit Score:** [X.X] / 10 ([Y]% strategic value deployable now, [Z]% near-term) | [N] gaps identified

| Category | Count | Weighted Value % | Priority Use Cases |
|----------|-------|-----------------|---------------------|
| READY (deploy now) | [n] | [%] | [list] |
| NEAR (minor gaps) | [n] | [%] | [list] |
| GAP (significant) | [n] | [%] | [list] |
| N/A | [n] | — | [list] |

---

## 1. Entity Strategic Goals (Inferred)

Based on data investment patterns observed in the deployment, this entity likely pursues:

| # | Strategic Goal | Evidence from Deployment | Confidence |
|---|---------------|-------------------------|------------|
| 1 | [Goal] | [Tables/patterns that indicate this] | High/Medium/Low |
| 2 | [Goal] | [Evidence] | [Confidence] |

---

## 2. Current Deployment Assessment

### 2.1 Silver Layer Inventory

| Object | Domain | Table Type | Grain | Key Columns | Data Pattern | Rows | Freshness | Health | Notes |
|--------|--------|-----------|-------|-------------|--------------|------|-----------|--------|-------|
| [table_name] | [domain] | [FACT/DIM/AGG/REF] | [grain] | [cols] | [SCD2/Append/Snapshot] | [count or N/A] | [date or N/A] | [HEALTHY/STALE/SPARSE/HOLLOW/DEGRADED/MISLEADING or N/A] | [notes] |

### 2.2 Gold Layer Inventory

| Object | Domain | Table Type | Grain | Key Columns | Aggregation Type | Rows | Freshness | Health | Notes |
|--------|--------|-----------|-------|-------------|-----------------|------|-----------|--------|-------|
| [table_name] | [domain] | [FACT/DIM/AGG/REF] | [grain] | [cols] | [Sum/Count/Avg/Complex] | [count or N/A] | [date or N/A] | [HEALTHY/STALE/SPARSE/HOLLOW/DEGRADED/MISLEADING or N/A] | [notes] |

> If Step 1.5 (Data Grounding) was not performed, omit Rows/Freshness/Health columns and display:
> ⚠ DDL-ONLY ASSESSMENT: Data volumes, freshness, and quality were not validated against a live environment.

### 2.3 Data Domain Coverage

| Domain | Silver Objects | Gold Objects | Completeness | Gaps |
|--------|--------------|-------------|--------------|------|
| [domain] | [count] | [count] | High/Medium/Low | [missing elements] |

---

## 3. Use Case Fit Matrix

### 3.1 Summary Matrix

| # | Use Case | Impact Weight | Classification | Data Readiness | Feature Readiness | Effort to Deploy | Impact |
|---|----------|--------------|----------------|----------------|-------------------|-----------------|--------|
| 1 | [Use Case] | HIGH/MED/LOW | READY/NEAR/GAP/N/A | [%] | [%] | Low/Med/High | High/Med/Low |

### 3.2 READY Use Cases (Deploy Now)

For each:
```
#### [Use Case Name]
- **Supporting Objects:** [silver/gold tables that enable this]
- **Why Ready:** [explanation]
- **Recommended Implementation:** [approach]
- **Snowflake Features:** [features to leverage]
- **Expected Outcome:** [quantified impact]
```

### 3.3 NEAR Use Cases (Minor Gaps)

For each:
```
#### [Use Case Name]
- **Supporting Objects:** [existing tables]
- **Gaps Identified:**
  - [ ] [Gap 1: description + resolution]
  - [ ] [Gap 2: description + resolution]
- **Effort to Close:** Low/Medium
- **Snowflake Features:** [features that help close gaps]
- **Expected Outcome:** [quantified impact after gaps closed]
```

### 3.4 GAP Use Cases (Significant Work Required)

For each:
```
#### [Use Case Name]
- **Missing Data Domains:** [what's not present]
- **Missing Capabilities:** [architectural gaps]
- **Path to Deployment:**
  1. [Step 1]
  2. [Step 2]
- **Effort:** High
- **Marketplace Opportunities:** [data that could be acquired]
- **Strategic Value If Deployed:** [why this matters]
```

---

## 4. Gap Analysis

### 4.1 Data Gaps

| Gap ID | Description | Impact (Use Cases Blocked) | Resolution Path | Effort |
|--------|-------------|---------------------------|-----------------|--------|
| DG-1 | [Missing data domain/source] | [UC-1, UC-3] | [How to resolve] | [Effort] |

### 4.2 Capability Gaps

| Gap ID | Description | Impact (Use Cases Blocked) | Snowflake Solution | Effort |
|--------|-------------|---------------------------|-------------------|--------|
| CG-1 | [Missing capability] | [UC-2, UC-5] | [Feature/approach] | [Effort] |

### 4.3 Architecture Gaps

| Gap ID | Description | Impact | Resolution | Effort |
|--------|-------------|--------|------------|--------|
| AG-1 | [Architectural limitation] | [Impact] | [Solution] | [Effort] |

---

## 5. Snowflake Value Proposition

### 5.1 Feature-to-Gap Mapping

| Snowflake Feature | Gaps Addressed | Use Cases Enabled | Implementation Notes |
|-------------------|---------------|-------------------|---------------------|
| [Feature] | [DG-1, CG-2] | [UC-1, UC-3] | [How to apply] |

### 5.2 Differentiated Capabilities

For each major Snowflake feature applicable:
```
#### [Feature Name]
- **What it does:** [brief]
- **How it applies here:** [specific to this deployment]
- **Gaps it closes:** [references]
- **Unique advantage:** [why Snowflake vs. alternatives]
```

---

## 6. Business Impact Assessment

> ⚠ **Impact estimates below use published industry benchmarks from analyst reports and vendor case studies. They are NOT calibrated to this entity's revenue, cost structure, or operational maturity. Treat as directional indicators only.**

### 6.1 Impact Summary

| Use Case | Impact Category | Industry Benchmark Range | Calibration Data Needed | Timeline to Value |
|----------|----------------|------------------------:|------------------------|-------------------|
| [UC-1] | Revenue/Cost/Risk/Efficiency | [X-Y% or $X-$Y range] | [What entity data would make this specific] | [months] |

### 6.2 Aggregate Impact (Directional)

| Category | Industry Benchmark Range | Use Cases Contributing | To Calibrate, Need |
|----------|------------------------:|----------------------|-------------------|
| Revenue Growth | [range] | [UC list] | Entity revenue figures, baseline conversion rates |
| Cost Reduction | [range] | [UC list] | Current spend in relevant categories |
| Risk Mitigation | [range avoided] | [UC list] | Historical incident frequency and cost |
| Operational Efficiency | [% range] | [UC list] | Current throughput/utilization metrics |

---

## 7. Recommended Roadmap

### Phase 1: Quick Wins (READY)
| # | Use Case | Key Actions | Dependencies | Expected Impact |
|---|----------|-------------|--------------|-----------------|
| 1 | [UC] | [Actions] | None | [Impact] |

### Phase 2: Near-Term (NEAR - close gaps)
| # | Use Case | Gaps to Close | Key Actions | Expected Impact |
|---|----------|---------------|-------------|-----------------|
| 1 | [UC] | [Gap refs] | [Actions] | [Impact] |

### Phase 3: Strategic (GAP - build capability)
| # | Use Case | Major Investments | Key Actions | Expected Impact |
|---|----------|-------------------|-------------|-----------------|
| 1 | [UC] | [Data sources, architecture] | [Actions] | [Impact] |

---

## 8. Appendix

### A. Full Data Inventory
[Complete table listing from Step 1]

### B. Snowflake Feature Capability Matrix
[Features used vs. available]

### C. Marketplace Opportunities
| Data Product | Provider | Use Cases Enabled | Estimated Cost |
|--------------|----------|-------------------|---------------|
| [Product] | [Provider] | [UCs] | [Cost tier] |

### D. Methodology Notes
- Vertical detection method: [signals used]
- Classification criteria: [how READY/NEAR/GAP determined]
- Impact estimation basis: [industry benchmarks, assumptions]
- Limitations: [what this assessment cannot determine without more context]

---

*Generated by Snowflake Value Map skill | Cortex Code*
