# Life Sciences & Pharma Vertical - Use Case Catalog

## Vertical Signals

**PRIMARY** (unique to this vertical, weight 3):
compound, trial, site, adverse_event, batch_record, stability, regulatory_submission, formulation, protocol, investigator, randomization, endpoint, nda, ind, gmp, cmc, pharmacovigilance

**SECONDARY** (suggestive but shared, weight 1):
patient, lot, lab, medication, compliance, quality, inspection, supplier, manufacturing

**NEGATIVE** (contradicts this vertical, weight -2):
claim, premium, policy, viewership, shipment, grid, meter, subscriber, oee

## Canonical Use Cases

### 1. Clinical Trial Optimization & Site Selection
- **Required Domains**: Trial, Site, Investigator, Protocol, Patient Pool, Enrollment, Milestone
- **Required Patterns**: Site performance scoring, enrollment prediction, protocol feasibility, competitive landscape analysis
- **Snowflake Features**: Cortex ML (enrollment forecasting), Marketplace (clinical trial registries, claims data), Snowpark (site scoring models), Dynamic Tables
- **Business Outcome**: Operational Efficiency, Time-to-Market
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 20-30% faster enrollment timelines, 15-25% reduction in site activation time, fewer protocol amendments
- **Data Signals**: site performance history, investigator experience, patient population estimates, competing trial data, enrollment milestones

### 2. Pharmacovigilance & Adverse Event Detection
- **Required Domains**: Adverse Event, Case, Patient, Drug, Reporter, MedDRA Coding, Signal
- **Required Patterns**: Signal detection (disproportionality analysis), case processing automation, narrative generation, periodic reporting
- **Snowflake Features**: Cortex AI (narrative generation, case triage), Cortex ML (signal detection), Snowpipe Streaming (real-time intake), Dynamic Tables
- **Business Outcome**: Patient Safety, Regulatory Compliance
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 40-60% reduction in case processing time, earlier signal detection by 2-4 weeks, automated periodic report generation
- **Data Signals**: ICSR (individual case safety reports), MedDRA coded events, drug-event combinations, spontaneous reports, literature mentions

### 3. Drug Supply Chain & Cold Chain Management
- **Required Domains**: Material, Lot, Shipment, Temperature Log, Warehouse, Demand, Expiry
- **Required Patterns**: Cold chain monitoring, expiry management, demand-supply balancing, serialization/track-and-trace
- **Snowflake Features**: Snowpipe Streaming (IoT/temperature data), Dynamic Tables (inventory visibility), Cortex ML (demand forecasting), Alerts
- **Business Outcome**: Operational Efficiency, Compliance, Cost Reduction
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 30-50% reduction in product waste/expiry, real-time cold chain visibility, DSCSA compliance readiness
- **Data Signals**: temperature/humidity sensor logs, lot/batch tracking, shipment status, warehouse inventory, serialization data

### 4. Real-World Evidence (RWE) Analytics
- **Required Domains**: Patient (de-identified), Claims, EHR, Lab, Prescription, Diagnosis, Outcome
- **Required Patterns**: Cohort identification, treatment pathway analysis, comparative effectiveness, outcomes research
- **Snowflake Features**: Data Clean Rooms (multi-source RWE), Marketplace (claims/Rx data), Snowpark (statistical analysis), Cortex Search (cohort matching)
- **Business Outcome**: Revenue Growth (label expansion), Regulatory Strategy, Market Access
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: Support for regulatory submissions (FDA/EMA), 30-50% faster evidence generation, expanded label opportunities
- **Data Signals**: longitudinal claims data, EHR extracts, prescription fills, lab results, patient outcomes, diagnosis codes

### 5. Commercial Analytics & Territory Optimization
- **Required Domains**: HCP, Territory, Sales Rep, Prescription (TRx/NRx), Market, Segment, Call Activity
- **Required Patterns**: Territory alignment, call planning optimization, KOL identification, market share tracking, launch analytics
- **Snowflake Features**: Cortex ML (prescriber targeting), Geospatial functions (territory mapping), Marketplace (Rx data), Dynamic Tables (share tracking)
- **Business Outcome**: Revenue Growth, Sales Effectiveness
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 10-20% improvement in rep productivity, 5-15% increase in NRx share, optimized territory alignment
- **Data Signals**: Rx data (TRx, NRx, NBRx), HCP profiles, call activity logs, territory definitions, market share by geography

### 6. Manufacturing Batch Quality & Deviation Management
- **Required Domains**: Batch Record, Process Parameter, Deviation, CAPA, Material, Equipment, Quality Result
- **Required Patterns**: Batch genealogy, process parameter correlation, deviation trending, right-first-time analysis
- **Snowflake Features**: Snowpark (multivariate batch analysis), Cortex ML (deviation prediction), Dynamic Tables (real-time quality), Cortex AI (deviation narrative)
- **Business Outcome**: Quality Improvement, Compliance, Cost Reduction
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 20-35% reduction in batch failures, 30-50% faster deviation investigation, improved right-first-time rate
- **Data Signals**: electronic batch records, in-process control data, deviation logs, CAPA records, environmental monitoring

### 7. Regulatory Submission Analytics
- **Required Domains**: Submission, Document, Study, Module (CTD), Regulatory Agency, Timeline, Correspondence
- **Required Patterns**: Submission timeline tracking, document gap analysis, cross-reference validation, agency correspondence analysis
- **Snowflake Features**: Cortex AI (document analysis, gap detection), Dynamic Tables (submission tracking), Cortex Search (cross-reference), Snowpark
- **Business Outcome**: Time-to-Market, Regulatory Compliance
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 20-30% reduction in submission preparation time, fewer deficiency letters, faster agency response turnaround
- **Data Signals**: eCTD module status, study report inventory, agency correspondence, submission timelines, regulatory commitment tracking

### 8. Patient Recruitment & Enrollment Prediction
- **Required Domains**: Protocol Criteria, Patient Pool, Site Capacity, Screening, Consent, Randomization
- **Required Patterns**: Eligibility matching against real-world data, enrollment velocity forecasting, diversity analytics, dropout prediction
- **Snowflake Features**: Cortex Search (patient matching), Marketplace (de-identified patient data), Cortex ML (enrollment prediction), Data Clean Rooms (provider collaboration)
- **Business Outcome**: Time-to-Market, Cost Reduction
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 25-40% improvement in screen-to-enroll ratio, more representative trial populations, $500K-$1M saved per month of accelerated enrollment
- **Data Signals**: protocol eligibility criteria, de-identified patient data, screening logs, site enrollment rates, diversity metrics

### 9. Medical Affairs & Scientific Insights
- **Required Domains**: Publication, KOL, Congress, Medical Inquiry, Scientific Evidence, Treatment Guideline
- **Required Patterns**: KOL mapping and engagement, literature surveillance, medical inquiry trending, evidence gap analysis
- **Snowflake Features**: Cortex AI (literature analysis, insight extraction), Cortex Search (publication search), Marketplace (publication data), Snowpark
- **Business Outcome**: Scientific Strategy, Thought Leadership
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: Comprehensive KOL engagement tracking, faster evidence gap identification, automated literature surveillance
- **Data Signals**: publication databases, congress abstracts, medical inquiry logs, KOL profiles, scientific platform engagement

### 10. Pricing & Market Access Analytics
- **Required Domains**: Payer, Formulary, Contract, Rebate, Market, Competitor, Patient Access
- **Required Patterns**: Gross-to-net modeling, formulary coverage tracking, contract performance analysis, patient affordability simulation
- **Snowflake Features**: Snowpark (GTN modeling), Dynamic Tables (contract monitoring), Marketplace (formulary/payer data), Cortex ML (access prediction)
- **Business Outcome**: Revenue Optimization, Market Access
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 5-10% improvement in net revenue through optimized contracting, faster formulary win tracking, proactive payer engagement
- **Data Signals**: payer contracts, rebate calculations, formulary status, patient out-of-pocket data, competitor pricing, market access outcomes

## Compliance Considerations
- FDA 21 CFR Part 11: Electronic records and signatures for GxP systems
- GxP (GMP/GLP/GCP): Good practice requirements across development and manufacturing
- ICH E6 (R2): Good Clinical Practice guidelines for trial data integrity
- EMA regulations: EU-specific submission and pharmacovigilance requirements
- HIPAA: De-identification requirements for US patient data (RWE)
- GDPR: EU clinical trial data, patient consent, right to erasure
- Annex 11: EU computerized system validation for regulated environments
- DSCSA: Drug Supply Chain Security Act serialization and tracing

## Marketplace Opportunities
- Claims and prescription data (de-identified Rx/Dx data)
- Real-world data (EHR extracts, longitudinal patient data)
- Clinical trial registries and competitive intelligence
- Drug reference databases (NDC, ATC classification)
- Genomic and biomarker data
- Physician/KOL databases and publication data
- Epidemiology and disease prevalence data
- Regulatory intelligence and approval history
