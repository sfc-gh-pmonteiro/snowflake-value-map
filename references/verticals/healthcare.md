# Healthcare Vertical - Use Case Catalog

## Vertical Signals

**PRIMARY** (unique to this vertical, weight 3):
patient, encounter, claim, diagnosis, procedure, provider, npi, icd, cpt, drg, medication, lab_result, vital, ehr, fhir, hl7, clinical, pharmacy, readmission, los

**SECONDARY** (suggestive but shared, weight 1):
member, beneficiary, prescription, referral, authorization, coverage, facility, discharge, admission

**NEGATIVE** (contradicts this vertical, weight -2):
compound, trial_site, investigator, randomization, nda, ind, formulation, pharmacovigilance, adverse_event_report

## Canonical Use Cases

### 1. Patient 360 / Unified Patient Record
- **Required Domains**: Patient, Encounter, Diagnosis, Medication, Lab, Provider
- **Required Patterns**: SCD2 (patient demographics), event timeline, semi-structured (FHIR/HL7)
- **Snowflake Features**: VARIANT columns, Dynamic Tables, Streams & Tasks, Cortex Search
- **Business Outcome**: Operational Efficiency, Care Quality
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 15-25% reduction in duplicate tests, 10-20% improvement in care coordination
- **Data Signals**: `dim_patient`, `fact_encounter`, `bridge_patient_provider`, medication history tables

### 2. Claims Analytics & Fraud Detection
- **Required Domains**: Claim, Member, Provider, Procedure, Diagnosis
- **Required Patterns**: Time-series (claim history), anomaly detection, network/graph (provider rings)
- **Snowflake Features**: Cortex ML (Anomaly Detection), Snowpark, Cortex AI (LLM for narrative analysis)
- **Business Outcome**: Cost Reduction, Risk Mitigation
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 3-5% reduction in fraudulent claims, $2-10M annual recovery per 1M members
- **Data Signals**: `fact_claim`, `dim_procedure`, `dim_provider`, `agg_claim_by_provider`

### 3. Readmission Risk Prediction
- **Required Domains**: Patient, Encounter, Diagnosis, Medication, Social Determinants
- **Required Patterns**: ML feature store, time-windowed aggregations, outcome labeling
- **Snowflake Features**: Snowpark ML, Feature Store, Cortex ML, Dynamic Tables (feature refresh)
- **Business Outcome**: Cost Reduction, Care Quality
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 10-15% reduction in 30-day readmissions, $10K-25K saved per avoided readmission
- **Data Signals**: `fact_admission`, `fact_discharge`, diagnosis history, medication adherence

### 4. Population Health Management
- **Required Domains**: Member, Diagnosis (chronic conditions), Utilization, Demographics, SDOH
- **Required Patterns**: Cohort segmentation, risk stratification, longitudinal tracking
- **Snowflake Features**: Snowpark (cohort analysis), Cortex ML (classification), Secure Data Sharing (SDOH data)
- **Business Outcome**: Revenue (value-based care), Cost Reduction
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 8-12% reduction in total cost of care for managed populations
- **Data Signals**: `dim_member`, chronic condition flags, HCC scores, utilization metrics

### 5. Clinical Trial Analytics
- **Required Domains**: Patient, Lab, Medication, Diagnosis, Site, Protocol
- **Required Patterns**: Longitudinal patient data, eligibility matching, real-world evidence
- **Snowflake Features**: Cortex Search (patient matching), Data Clean Rooms (multi-site), Marketplace (real-world data)
- **Business Outcome**: Revenue (accelerated trials), Operational Efficiency
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 20-30% faster enrollment, $1M+ savings per month of accelerated timeline
- **Data Signals**: eligibility criteria tables, lab panels, protocol adherence tracking

### 6. Revenue Cycle Optimization
- **Required Domains**: Claim, Encounter, Charge, Payment, Denial, Payer
- **Required Patterns**: Funnel/workflow tracking, SLA monitoring, denial pattern analysis
- **Snowflake Features**: Dynamic Tables (real-time denial tracking), Cortex ML (denial prediction), Alerts
- **Business Outcome**: Revenue Protection, Operational Efficiency
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 5-10% reduction in claim denials, 15-20 day reduction in A/R days
- **Data Signals**: `fact_charge`, `fact_payment`, `fact_denial`, `dim_payer`, revenue cycle staging

### 7. Medication Adherence & Pharmacy Analytics
- **Required Domains**: Patient, Medication, Prescription, Fill, Refill, Outcome
- **Required Patterns**: Time-series (fill patterns), gap analysis, intervention tracking
- **Snowflake Features**: Snowpark (PDC/MPR calculations), Cortex ML (non-adherence prediction)
- **Business Outcome**: Care Quality, Cost Reduction
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 5-15% improvement in adherence rates, $3K-8K annual savings per adherent patient
- **Data Signals**: prescription/fill tables, medication history, refill intervals

### 8. Provider Performance & Network Adequacy
- **Required Domains**: Provider, Claim, Encounter, Quality Measure, Geographic
- **Required Patterns**: Benchmarking, peer comparison, geographic analysis, network coverage
- **Snowflake Features**: Geospatial functions, Cortex ML (outlier detection), Marketplace (geo data)
- **Business Outcome**: Quality, Network Optimization
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 5-10% improvement in network adequacy scores, reduced out-of-network leakage
- **Data Signals**: `dim_provider`, quality scores, specialty mapping, geographic coverage

### 9. Social Determinants of Health (SDOH) Integration
- **Required Domains**: Patient, Demographics, Geographic, Social Risk Factors, Community
- **Required Patterns**: Data enrichment, external data integration, index scoring
- **Snowflake Features**: Marketplace (Census, ADI, food access data), Secure Sharing, Cortex Search
- **Business Outcome**: Care Quality, Health Equity
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: 10-20% improvement in care gap closure for at-risk populations
- **Data Signals**: zip/census tract columns, social risk indicators, community health metrics

### 10. Real-Time Clinical Decision Support
- **Required Domains**: Patient (current state), Lab, Vital, Medication, Alert Rules
- **Required Patterns**: Streaming/near-real-time, rule engine, ML inference at point-of-care
- **Snowflake Features**: Snowpipe Streaming, Dynamic Tables, Cortex AI (LLM for clinical summaries)
- **Business Outcome**: Care Quality, Patient Safety
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 15-30% reduction in adverse drug events, 10-15% improvement in protocol adherence
- **Data Signals**: real-time feeds, vitals tables, alert/notification tables, order entry

## Compliance Considerations
- HIPAA: PHI must be de-identified or access-controlled (row-level security, masking policies)
- HITRUST: Data governance framework alignment
- 42 CFR Part 2: Substance use disorder records require extra consent tracking
- State-specific: Varies (e.g., California CCPA for health data)

## Marketplace Opportunities
- Social determinants datasets (Census, ACS, ADI)
- Drug reference databases (NDC, RxNorm)
- Provider directories (NPI, NPPES)
- ICD/CPT code reference files
- Geographic/demographic enrichment
