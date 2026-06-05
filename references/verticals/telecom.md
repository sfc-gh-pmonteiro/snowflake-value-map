# Telecom Vertical - Use Case Catalog

## Vertical Signals

**PRIMARY** (unique to this vertical, weight 3):
subscriber, msisdn, imsi, cell_tower, cdr, data_session, tariff, spectrum, roaming, handset, sim, porting, provisioning, oss, bss, mno, mvno, arpu

**SECONDARY** (suggestive but shared, weight 1):
usage, plan, network, node, alarm, ticket, churn, nps, bandwidth, latency, device, customer

**NEGATIVE** (contradicts this vertical, weight -2):
patient, diagnosis, sku, store, basket, policy, premium, meter, grid, production_order

## Canonical Use Cases

### 1. Customer 360 & Lifecycle Management
- **Required Domains**: Subscriber, Account, Usage, Billing, Interaction, Device, Plan
- **Required Patterns**: SCD2 (subscriber state), event timeline, household/account hierarchy
- **Snowflake Features**: Dynamic Tables, Cortex Search, Streams & Tasks, Cortex AI (interaction summarization)
- **Business Outcome**: Revenue Growth, Customer Retention
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 10-20% improvement in ARPU, 15-25% reduction in voluntary churn
- **Data Signals**: `dim_subscriber`, `fact_usage`, `fact_billing`, interaction/contact logs, device inventory

### 2. Churn Prediction & Retention
- **Required Domains**: Subscriber, Usage Patterns, Billing, Complaint, NPS, Competitor, Network Quality
- **Required Patterns**: ML classification, feature engineering (behavioral signals), propensity scoring, trigger-based actions
- **Snowflake Features**: Cortex ML (Classification), Snowpark (feature engineering), Feature Store, Dynamic Tables
- **Business Outcome**: Revenue Protection, Customer Retention
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 20-35% reduction in churn rate, $50-200 saved per retained subscriber (acquisition cost avoidance)
- **Data Signals**: usage trend tables, complaint history, NPS scores, plan change history, network quality per subscriber

### 3. Network Performance & Capacity Planning
- **Required Domains**: Cell Tower, Traffic Volume, Latency, Throughput, Alarm, Geography
- **Required Patterns**: Time-series (network KPIs), anomaly detection, geospatial analysis, capacity forecasting
- **Snowflake Features**: Cortex ML (Forecasting, Anomaly Detection), Geospatial functions, Dynamic Tables, Snowpipe Streaming
- **Business Outcome**: Operational Efficiency, Customer Experience
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 15-25% improvement in network utilization, 30-50% faster fault resolution
- **Data Signals**: cell/site performance tables, traffic volume time-series, alarm/fault tables, geographic topology

### 4. Revenue Assurance & Fraud Detection
- **Required Domains**: CDR, Billing, Rating, Subscriber, Roaming, Interconnect
- **Required Patterns**: Reconciliation (rated vs billed), anomaly detection, pattern matching, real-time scoring
- **Snowflake Features**: Snowpipe Streaming, Cortex ML (Anomaly Detection), Dynamic Tables, Alerts
- **Business Outcome**: Revenue Protection, Cost Reduction
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 1-3% revenue leakage recovery, 30-50% reduction in subscription fraud losses
- **Data Signals**: CDR/billing reconciliation, rating engine outputs, roaming records, SIM swap events

### 5. Next-Best-Action & Personalized Offers
- **Required Domains**: Subscriber, Usage, Billing, Plan, Campaign, Interaction, Propensity
- **Required Patterns**: Recommendation engine, uplift modeling, real-time decisioning, A/B testing
- **Snowflake Features**: Cortex ML, Snowpark, Cortex AI (offer content generation), Feature Store
- **Business Outcome**: Revenue Growth, Customer Satisfaction
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 15-30% improvement in offer acceptance, 5-10% ARPU uplift
- **Data Signals**: offer/campaign history, acceptance/rejection tracking, usage propensity scores

### 6. IoT & Connected Device Analytics
- **Required Domains**: Device, SIM, Data Session, Location, Alert, Service Level
- **Required Patterns**: High-volume streaming, device state management, threshold alerting, fleet analytics
- **Snowflake Features**: Snowpipe Streaming, Dynamic Tables, Cortex ML (device anomaly), VARIANT (device telemetry)
- **Business Outcome**: Revenue Growth (IoT segment), Operational Efficiency
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: New revenue streams from IoT services, 20-40% reduction in device management costs
- **Data Signals**: IoT device registry, session/connectivity tables, telemetry (semi-structured), SLA monitoring

### 7. Customer Experience & NPS Analytics
- **Required Domains**: Subscriber, NPS/CSAT, Interaction, Complaint, Network Quality (per-user), Resolution
- **Required Patterns**: Text analytics (complaint mining), root cause analysis, journey mapping, sentiment tracking
- **Snowflake Features**: Cortex AI (sentiment analysis, text summarization), Cortex ML (NPS prediction), Dynamic Tables
- **Business Outcome**: Customer Satisfaction, Retention
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 10-15 point NPS improvement, 20-30% reduction in repeat contacts
- **Data Signals**: survey responses, contact center logs, resolution tracking, sentiment scores

### 8. 5G Monetization & Network Slicing
- **Required Domains**: Slice, SLA, Enterprise Customer, Usage, QoS Metrics, Pricing
- **Required Patterns**: SLA monitoring, usage-based billing, capacity reservation, multi-tenant metrics
- **Snowflake Features**: Snowpipe Streaming (real-time SLA), Dynamic Tables, Data Sharing (enterprise portals)
- **Business Outcome**: Revenue Growth, Service Differentiation
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: New enterprise revenue streams, premium pricing for guaranteed SLA tiers
- **Data Signals**: network slice definitions, SLA thresholds, enterprise usage, QoS measurements

### 9. Partner & Wholesale Settlement
- **Required Domains**: Interconnect, Roaming, CDR, Partner, Rate, Settlement, Dispute
- **Required Patterns**: Bilateral reconciliation, rate application, dispute tracking, margin analysis
- **Snowflake Features**: Data Clean Rooms (partner settlement), Dynamic Tables, Snowpark (rating engines)
- **Business Outcome**: Revenue Protection, Operational Efficiency
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: 2-5% improvement in settlement accuracy, 50% reduction in dispute resolution time
- **Data Signals**: interconnect CDRs, roaming TAP files, partner rate cards, settlement reports

### 10. Predictive Maintenance (Network Infrastructure)
- **Required Domains**: Equipment, Alarm, Maintenance History, Environmental, Performance Degradation
- **Required Patterns**: Time-series degradation, failure prediction, maintenance scheduling, spare parts optimization
- **Snowflake Features**: Cortex ML (time-series forecasting), Snowpipe Streaming, Alerts, Dynamic Tables
- **Business Outcome**: Cost Reduction, Network Reliability
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: 20-30% reduction in unplanned downtime, 15-25% reduction in maintenance costs
- **Data Signals**: equipment registry, alarm/fault history, maintenance work orders, performance degradation metrics

## Compliance Considerations
- GDPR/ePrivacy: CDR retention limits, location data consent, lawful intercept
- Data Retention Regulations: CDR storage mandated periods (varies by country)
- Net Neutrality: Traffic management transparency
- Lawful Intercept: Regulated access to communications data
- Roaming Regulations (EU): BEREC fair use, wholesale caps

## Marketplace Opportunities
- Geographic/demographic enrichment
- Weather data (network impact correlation)
- Device reference databases
- Competitive intelligence (coverage maps)
- Economic indicators (spending propensity)
- IoT industry benchmarks
