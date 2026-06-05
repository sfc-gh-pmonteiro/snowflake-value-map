# Insurance Vertical - Use Case Catalog

## Vertical Signals

**PRIMARY** (unique to this vertical, weight 3):
policy, premium, underwriting, actuarial, loss_ratio, reserve, reinsurance, catastrophe, deductible, endorsement, binder, insured, peril, subrogation, combined_ratio

**SECONDARY** (suggestive but shared, weight 1):
claim, agent, broker, risk, exposure, coverage, beneficiary, payout, renewal, lapse

**NEGATIVE** (contradicts this vertical, weight -2):
patient, encounter, diagnosis, sensor, production_order, viewership, shipment

## Canonical Use Cases

### 1. Claims Analytics & Fraud Detection
- **Required Domains**: Claim, Claimant, Policy, Loss Event, Investigation, Payment, Provider/Vendor
- **Required Patterns**: Anomaly detection, network/ring analysis, severity prediction, litigation propensity scoring
- **Snowflake Features**: Cortex ML (fraud scoring, severity prediction), Snowpark (network analysis), Cortex AI (claims narrative analysis), Dynamic Tables (real-time scoring)
- **Business Outcome**: Cost Reduction, Risk Mitigation
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 20-40% improvement in fraud detection rates, 10-15% reduction in claims leakage, 30-50% faster claims triage
- **Data Signals**: claims history, claimant profiles, provider/vendor networks, payment patterns, investigation notes, SIU referrals

### 2. Underwriting Automation & Risk Selection
- **Required Domains**: Application, Risk Factor, Exposure, Loss History, Credit, External Data, Underwriting Rules
- **Required Patterns**: Risk scoring, appetite matching, straight-through processing, referral routing, portfolio mix optimization
- **Snowflake Features**: Cortex ML (risk classification), Snowpark (feature engineering from external data), Dynamic Tables (real-time portfolio monitoring), Marketplace (property/hazard data)
- **Business Outcome**: Operational Efficiency, Risk Selection Quality, Revenue Growth
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 50-70% straight-through processing for standard risks, 15-25% improvement in loss ratio for auto-underwritten business, 30-40% reduction in underwriting cycle time
- **Data Signals**: application data, inspection reports, loss history (CLUE/A-PLUS), credit scores, property characteristics, hazard data

### 3. Pricing & Rate Adequacy
- **Required Domains**: Policy, Premium, Loss, Exposure, Territory, Class, Rate Factor, Competitor
- **Required Patterns**: GLM/ML rating models, territorial analysis, competitor benchmarking, elasticity modeling, loss cost trending
- **Snowflake Features**: Snowpark (actuarial modeling, GLMs), Cortex ML (demand elasticity), Dynamic Tables (rate monitoring), Marketplace (competitor/benchmark data)
- **Business Outcome**: Revenue Optimization, Profitability
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 3-8% improvement in loss ratio through better segmentation, optimized retention through price elasticity, faster rate-to-market cycles
- **Data Signals**: earned premium/exposure, incurred losses by class/territory, rate change history, competitor rate filings, policy retention by price change

### 4. Customer 360 & Retention
- **Required Domains**: Customer/Household, Policy, Billing, Claim, Interaction, Agent, Life Event
- **Required Patterns**: Multi-policy household linkage, retention risk scoring, cross-sell propensity, lifetime value estimation
- **Snowflake Features**: Dynamic Tables (customer profile refresh), Cortex ML (retention/propensity models), Cortex Search (interaction history), Cortex AI (personalized communications)
- **Business Outcome**: Revenue Growth, Customer Retention
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 10-20% improvement in multi-policy retention, 15-25% increase in cross-sell conversion, 5-10% reduction in lapse rates
- **Data Signals**: policy portfolio per customer, billing/payment history, claim experience, interaction logs, agent assignments, life event triggers

### 5. Catastrophe Modeling & Exposure Management
- **Required Domains**: Policy, Location, Peril, Aggregate Exposure, Reinsurance Treaty, Model Output, PML
- **Required Patterns**: Accumulation monitoring, scenario modeling, portfolio stress testing, reinsurance optimization
- **Snowflake Features**: Geospatial (location/accumulation analysis), Snowpark (catastrophe model integration), Dynamic Tables (real-time exposure tracking), Marketplace (weather/climate data)
- **Business Outcome**: Risk Mitigation, Capital Efficiency, Regulatory Compliance
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: Real-time portfolio accumulation visibility, improved reinsurance placement, 10-20% better capital efficiency through accurate PML estimation
- **Data Signals**: geocoded policy locations, TIV (total insured value), cat model outputs (AAL, PML), reinsurance treaty structures, historical event losses

### 6. Reserve Adequacy & Loss Development
- **Required Domains**: Claim, Reserve, Payment, Incurred, Triangle (development), Actuarial Assumption, LOB
- **Required Patterns**: Loss development triangles, chain-ladder methods, reserve variability, IBNR estimation, case reserve adequacy
- **Snowflake Features**: Snowpark (actuarial methods—CL, BF, Cape Cod), Dynamic Tables (monthly triangle refresh), Time Travel (point-in-time reserve snapshots)
- **Business Outcome**: Financial Accuracy, Regulatory Compliance, Capital Planning
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: Reduced reserve volatility, faster quarterly close, improved IBNR accuracy, fewer adverse reserve developments
- **Data Signals**: paid/incurred loss triangles, case reserve history, claim status transitions, actuarial selections, development factor tables

### 7. Agent/Broker Performance & Distribution
- **Required Domains**: Agent/Broker, Policy, Production, Commission, Retention, Quality (loss ratio), Territory
- **Required Patterns**: Production benchmarking, quality scoring (loss ratio by agent), compensation optimization, territory performance
- **Snowflake Features**: Dynamic Tables (producer scorecards), Cortex ML (production forecasting), Snowpark (compensation modeling), Data Sharing (broker portals)
- **Business Outcome**: Revenue Growth, Distribution Efficiency
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 10-15% improvement in producer productivity, better alignment of compensation with profitability, reduced appointment of unprofitable agents
- **Data Signals**: production volume by agent, retention rates, loss ratios by producer, commission schedules, new business vs. renewal mix

### 8. Regulatory Reporting & Compliance
- **Required Domains**: Policy, Financial Statement, Statutory Line, Schedule, Filing, Jurisdiction, Rate Filing
- **Required Patterns**: Statutory reporting (Annual/Quarterly statements), state filing automation, market conduct monitoring, complaint tracking
- **Snowflake Features**: Dynamic Tables (reporting refresh), Time Travel (period-end snapshots), Snowpark (statutory calculations), Alerts (filing deadline monitoring)
- **Business Outcome**: Regulatory Compliance, Operational Efficiency
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: 40-60% reduction in reporting preparation time, fewer regulatory findings, automated state filing compliance checks
- **Data Signals**: statutory accounting tables, schedule P/F data, rate filing history, market conduct exam results, complaint logs

### 9. Subrogation & Recovery Optimization
- **Required Domains**: Claim, At-Fault Party, Recovery, Demand, Arbitration, Salvage, Vendor
- **Required Patterns**: Recovery propensity scoring, demand optimization, aging/prioritization, vendor performance tracking
- **Snowflake Features**: Cortex ML (recovery likelihood prediction), Dynamic Tables (recovery pipeline), Cortex AI (demand letter generation), Alerts (statute of limitations)
- **Business Outcome**: Cost Recovery, Operational Efficiency
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: 15-25% improvement in recovery rates, 20-30% reduction in recovery cycle time, better prioritization of high-value opportunities
- **Data Signals**: subrogation referral data, demand/payment history, arbitration outcomes, statute of limitations, at-fault party information

### 10. Parametric & Usage-Based Insurance
- **Required Domains**: Telemetry/IoT, Trigger Event, Policy, Payout Criteria, Usage Metric, Behavior Score
- **Required Patterns**: Real-time trigger monitoring, usage scoring, behavior-based pricing, automatic payout execution
- **Snowflake Features**: Snowpipe Streaming (telematics/IoT data), Dynamic Tables (real-time scoring), Cortex ML (driving/behavior scoring), Alerts (trigger monitoring)
- **Business Outcome**: Innovation, Customer Acquisition, Risk Selection
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 10-20% loss ratio improvement for UBI programs, faster payouts (hours vs. weeks for parametric), improved customer engagement through feedback loops
- **Data Signals**: telematics data (speed, braking, mileage), IoT sensor data, weather trigger events, usage metrics, parametric payout thresholds

## Compliance Considerations
- State insurance regulations: Rate filing, form approval, market conduct requirements vary by jurisdiction
- NAIC: Model laws, statutory accounting (SAP), RBC requirements
- Solvency II (EU): Risk-based capital, ORSA, regulatory reporting
- IFRS 17: Insurance contract accounting standard (measurement models, CSM)
- HIPAA: Health insurance claims data handling
- Data residency: State-specific requirements for policyholder data
- Unfair trade practices: Anti-discrimination in underwriting, adverse action notices

## Marketplace Opportunities
- Catastrophe model data (RMS, AIR, CoreLogic event sets)
- Weather and climate data (historical and forecast)
- Property characteristics (building attributes, replacement cost, hazard proximity)
- Telematics benchmarks and driving behavior data
- Mortality/morbidity tables and population health data
- Economic indicators (inflation, interest rates for reserve discounting)
- Geocoding and address verification databases
