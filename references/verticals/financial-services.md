# Financial Services Vertical - Use Case Catalog

## Vertical Signals

**PRIMARY** (unique to this vertical, weight 3):
ledger, loan, mortgage, portfolio, position, trade, settlement, kyc, aml, credit_score, counterparty, instrument, cusip, isin, ticker, fx, interest_rate, regulatory_capital, liquidity, exposure, sar, var

**SECONDARY** (suggestive but shared, weight 1):
account, transaction, balance, customer, risk, payment, compliance, audit, scoring

**NEGATIVE** (contradicts this vertical, weight -2):
patient, diagnosis, sensor, production_order, shipment, meter, grid, subscriber, viewership

## Canonical Use Cases

### 1. Customer 360 & Relationship Management
- **Required Domains**: Customer, Account, Transaction, Product, Interaction, Household
- **Required Patterns**: SCD2 (customer/account), event sourcing, household linkage, cross-sell scoring
- **Snowflake Features**: Dynamic Tables, Cortex ML (propensity models), Cortex Search, Streams
- **Business Outcome**: Revenue Growth, Customer Retention
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 15-25% increase in cross-sell conversion, 10-15% reduction in attrition
- **Data Signals**: `dim_customer`, `dim_account`, `fact_transaction`, `bridge_household`, product holding

### 2. Fraud Detection & Prevention
- **Required Domains**: Transaction, Account, Customer, Device, Geolocation, Alert
- **Required Patterns**: Real-time/near-real-time scoring, anomaly detection, network analysis, behavioral profiling
- **Snowflake Features**: Snowpipe Streaming, Cortex ML (Anomaly Detection), Snowpark (feature engineering), Dynamic Tables
- **Business Outcome**: Risk Mitigation, Cost Reduction
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 30-50% reduction in false positives, 20-40% improvement in fraud detection rate
- **Data Signals**: transaction velocity, device fingerprints, geo coordinates, alert/case tables

### 3. Anti-Money Laundering (AML) & KYC
- **Required Domains**: Customer, Transaction, Beneficial Owner, Sanctions List, Country Risk, SAR
- **Required Patterns**: Network/graph analysis, entity resolution, threshold monitoring, case management
- **Snowflake Features**: Cortex Search (entity matching), Graph functions, Data Clean Rooms (inter-bank), Cortex AI (narrative generation)
- **Business Outcome**: Regulatory Compliance, Risk Mitigation
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 40-60% reduction in false positive alerts, 50%+ reduction in SAR filing time
- **Data Signals**: `dim_customer` with beneficial owner, watchlist tables, transaction monitoring thresholds

### 4. Credit Risk Modeling
- **Required Domains**: Customer, Application, Credit Bureau, Account Performance, Collateral, Macro-economic
- **Required Patterns**: ML model training/scoring, feature store, model monitoring, backtesting
- **Snowflake Features**: Snowpark ML, Feature Store, Model Registry, Dynamic Tables (feature refresh)
- **Business Outcome**: Risk Mitigation, Revenue Optimization
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 10-20% improvement in risk discrimination (Gini), 5-15% reduction in credit losses
- **Data Signals**: `fact_application`, credit scores, PD/LGD/EAD tables, vintage analysis

### 5. Market Risk & Portfolio Analytics
- **Required Domains**: Position, Instrument, Market Data, Scenario, VaR, Greeks
- **Required Patterns**: Time-series (market data), Monte Carlo simulation, what-if analysis, intraday snapshots
- **Snowflake Features**: Snowpark (simulation workloads), Time Travel, Zero-copy Cloning (scenario analysis)
- **Business Outcome**: Risk Mitigation, Regulatory Compliance
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: Faster VaR computation, improved stress testing coverage, reduced capital buffer requirements
- **Data Signals**: position/holding tables, pricing tables, scenario definitions, risk factor curves

### 6. Regulatory Reporting (Basel/IFRS/CECL)
- **Required Domains**: Account, Exposure, Provision, Capital, Regulatory Taxonomy
- **Required Patterns**: Point-in-time snapshots, audit trail, reconciliation, multi-jurisdiction
- **Snowflake Features**: Time Travel, Zero-copy Cloning (period-end), Dynamic Tables (continuous calc), Data Lineage
- **Business Outcome**: Regulatory Compliance, Operational Efficiency
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 50-70% reduction in reporting cycle time, significant reduction in regulatory findings
- **Data Signals**: regulatory staging tables, provision calculations, capital adequacy ratios

### 7. Real-Time Payments & Settlement
- **Required Domains**: Payment, Account, Counterparty, Settlement, Liquidity
- **Required Patterns**: Streaming/real-time, idempotency, reconciliation, liquidity monitoring
- **Snowflake Features**: Snowpipe Streaming, Dynamic Tables, Tasks & Streams, Alerts
- **Business Outcome**: Operational Efficiency, Customer Experience
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 90%+ real-time processing, reduced settlement failures, improved liquidity management
- **Data Signals**: payment instruction tables, settlement status, nostro/vostro reconciliation

### 8. Personalized Financial Advice / Next-Best-Action
- **Required Domains**: Customer, Transaction, Product, Goal, Life Event, Interaction
- **Required Patterns**: ML recommendation engine, behavioral segmentation, event-driven triggers
- **Snowflake Features**: Cortex ML, Cortex AI (personalized content), Snowpark (feature engineering)
- **Business Outcome**: Revenue Growth, Customer Satisfaction
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 20-35% improvement in campaign response rates, 10-20% AUM growth
- **Data Signals**: product holding history, transaction patterns, interaction/engagement logs

### 9. Operational Risk & Loss Event Analysis
- **Required Domains**: Loss Event, Control, Process, Risk Category, Business Line
- **Required Patterns**: Event classification, root cause analysis, scenario modeling, KRI monitoring
- **Snowflake Features**: Cortex AI (event classification from text), Cortex ML (prediction), Alerts
- **Business Outcome**: Risk Mitigation, Regulatory Compliance
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: Improved OpRisk capital modeling, earlier detection of control failures
- **Data Signals**: loss event tables, control assessment, KRI thresholds, incident logs

### 10. ESG / Sustainable Finance Analytics
- **Required Domains**: Company, ESG Score, Carbon Emission, Portfolio, Regulatory Taxonomy (SFDR/TCFD)
- **Required Patterns**: Data enrichment (external ESG providers), scoring, portfolio alignment, reporting
- **Snowflake Features**: Marketplace (ESG data providers), Cortex AI (ESG report extraction), Data Sharing
- **Business Outcome**: Regulatory Compliance, Brand/Reputation
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: Compliance with SFDR/TCFD mandates, reduced greenwashing risk, investor confidence
- **Data Signals**: ESG scoring tables, carbon metrics, taxonomy alignment flags, fund/portfolio composition

## Compliance Considerations
- SOX: Audit trails, data lineage, access controls mandatory
- PCI-DSS: Card data tokenization/masking
- GDPR/CCPA: Customer data privacy, right to erasure
- Basel III/IV: Model governance, data quality standards
- MiFID II / Dodd-Frank: Transaction reporting, best execution
- DORA: Digital operational resilience (EU)

## Marketplace Opportunities
- Market data feeds (pricing, reference data)
- Credit bureau / alternative credit data
- ESG data providers (MSCI, Sustainalytics)
- Sanctions and watchlist data
- Macro-economic indicators
- Geospatial / foot traffic data for alternative lending signals
