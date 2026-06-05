# Technology / SaaS Vertical - Use Case Catalog

## Vertical Signals

**PRIMARY** (unique to this vertical, weight 3):
tenant, feature_usage, subscription, mrr, arr, deployment, api_call, sdk, workspace, seat, plan_tier, onboarding, product_event, feature_flag

**SECONDARY** (suggestive but shared, weight 1):
user, session, event, pipeline, incident, ticket, churn, retention, engagement, nps, trial

**NEGATIVE** (contradicts this vertical, weight -2):
patient, policy, sensor, shipment, meter, claim, viewership, lot, batch

## Canonical Use Cases

### 1. Product-Led Growth Analytics
- **Required Domains**: User, Product Event, Activation Milestone, Conversion Funnel, Feature, Cohort, Experiment
- **Required Patterns**: Funnel analysis, activation milestone tracking, viral/referral loop measurement, self-serve conversion paths, experiment attribution
- **Snowflake Features**: Dynamic Tables (real-time funnels), Snowpark (cohort analysis), Cortex ML (propensity scoring), Snowpipe Streaming (event ingestion)
- **Business Outcome**: Revenue Growth, User Acquisition Efficiency, Activation Rate
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 15-30% improvement in activation rates, 20-40% reduction in CAC through self-serve, 2-5x improvement in viral coefficient tracking
- **Data Signals**: product events (clicks, page views, feature usage), signup funnel stages, invite/referral actions, experiment assignments, conversion timestamps

### 2. Customer Health Scoring & Churn Prediction
- **Required Domains**: Account, Usage Metrics, Support Ticket, NPS/CSAT, Contract, Engagement, Champion Contact
- **Required Patterns**: Health score computation, churn risk modeling, engagement trending, champion tracking, intervention triggers
- **Snowflake Features**: Cortex ML (classification, forecasting), Dynamic Tables (real-time health scores), Alerts (risk thresholds), Snowpark (feature engineering)
- **Business Outcome**: Revenue Retention, Net Dollar Retention, Customer Lifetime Value
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 20-40% reduction in gross churn, 5-15 point improvement in net dollar retention, 30-50% earlier churn risk identification
- **Data Signals**: daily/weekly active usage, feature breadth, support ticket volume/sentiment, login frequency, contract renewal dates, NPS responses, executive sponsor changes

### 3. Usage-Based Billing & Metering
- **Required Domains**: Tenant, Meter Event, Plan/Tier, Usage Aggregate, Invoice, Overage, Commitment
- **Required Patterns**: Real-time metering, usage aggregation, rating/pricing application, commitment burn-down, overage alerting
- **Snowflake Features**: Snowpipe Streaming (meter events), Dynamic Tables (usage aggregation), Alerts (threshold notifications), Snowpark (rating engine)
- **Business Outcome**: Revenue Accuracy, Revenue Growth, Customer Transparency
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 99.9%+ billing accuracy, 10-20% revenue uplift through usage visibility, real-time cost transparency reducing disputes by 30-50%
- **Data Signals**: API call logs, compute/storage metering, seat counts, feature-level consumption, plan limits, billing cycle data, credit burn-down

### 4. Feature Adoption & Engagement
- **Required Domains**: Feature, User, Session, Event, Release, Segment, Feedback
- **Required Patterns**: Feature usage tracking, adoption curves, stickiness metrics, feature-to-outcome correlation, engagement scoring
- **Snowflake Features**: Dynamic Tables (adoption dashboards), Snowpark (engagement modeling), Cortex ML (clustering), Cortex AI (feedback analysis)
- **Business Outcome**: Product Improvement, Retention, Feature Investment ROI
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: Data-driven prioritization improving feature ROI by 20-40%, 10-20% improvement in feature adoption through targeted onboarding
- **Data Signals**: feature-level events, session duration per feature, adoption by cohort/segment, feature discovery paths, user feedback/surveys, release dates

### 5. Revenue Intelligence (ARR/MRR Analytics)
- **Required Domains**: Subscription, Contract, ARR Movement (new, expansion, contraction, churn), Cohort, Segment, Rep/Territory
- **Required Patterns**: ARR waterfall/bridge, cohort retention curves, expansion/contraction decomposition, forecasting, logo vs. dollar retention
- **Snowflake Features**: Dynamic Tables (live ARR tracking), Snowpark (cohort models), Cortex ML (revenue forecasting), Data Sharing (board reporting)
- **Business Outcome**: Revenue Predictability, Growth Strategy, Investor Confidence
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: Real-time ARR visibility (vs. monthly manual), 10-20% improvement in forecast accuracy, faster identification of contraction signals
- **Data Signals**: subscription records, contract amendments, invoice/payment data, CRM opportunity data, product usage (expansion signals), segment/cohort tags

### 6. Infrastructure Cost Attribution
- **Required Domains**: Cloud Resource, Tenant, Service, Cost Center, Usage Metric, Allocation Rule, Budget
- **Required Patterns**: Multi-tenant cost allocation, unit economics (cost per tenant/request), margin analysis, anomaly detection, optimization recommendations
- **Snowflake Features**: Snowpark (allocation algorithms), Dynamic Tables (cost dashboards), Cortex ML (anomaly detection, forecasting), Alerts (budget thresholds)
- **Business Outcome**: Margin Improvement, Cost Efficiency, Pricing Accuracy
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 15-30% improvement in cost attribution accuracy, identification of 10-20% cost optimization opportunities, per-customer margin visibility
- **Data Signals**: cloud billing data (AWS/GCP/Azure), resource tagging, tenant-to-resource mapping, request/compute logs, storage allocation, data transfer volumes

### 7. Support Ticket & Escalation Prediction
- **Required Domains**: Ticket, Customer, Product Area, Priority, SLA, Agent, Resolution, Escalation
- **Required Patterns**: Escalation risk prediction, auto-routing, SLA breach forecasting, deflection analysis, agent productivity
- **Snowflake Features**: Cortex ML (classification, time-to-resolution prediction), Cortex AI (ticket summarization, sentiment), Dynamic Tables (SLA monitoring), Alerts
- **Business Outcome**: Customer Satisfaction, Support Efficiency, Cost Reduction
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 20-35% reduction in escalations through early intervention, 15-25% improvement in first-response time, 10-20% increase in self-serve deflection
- **Data Signals**: ticket metadata (priority, category, product area), customer health score, historical escalation patterns, response/resolution timestamps, CSAT ratings, knowledge base usage

### 8. Trial-to-Paid Conversion Optimization
- **Required Domains**: Trial, User, Activation Event, Feature Usage, Conversion, Plan Selection, Experiment
- **Required Patterns**: Trial behavior segmentation, conversion probability modeling, optimal trial length analysis, intervention timing, paywall optimization
- **Snowflake Features**: Cortex ML (conversion prediction), Snowpark (behavioral segmentation), Dynamic Tables (trial dashboards), Cortex AI (personalized nudges)
- **Business Outcome**: Revenue Growth, Acquisition Efficiency, User Activation
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 15-30% improvement in trial-to-paid conversion, 2-3x faster identification of high-intent trial users, optimized trial duration based on data
- **Data Signals**: trial signup data, feature usage during trial, activation milestone completion, time-in-trial, plan selection patterns, credit card on file, team invite behavior

### 9. Multi-Tenant Performance Analytics
- **Required Domains**: Tenant, Service, Endpoint, Latency, Error, Throughput, Resource Consumption, SLA
- **Required Patterns**: Noisy neighbor detection, per-tenant performance tracking, capacity planning, SLA compliance, degradation alerting
- **Snowflake Features**: Snowpipe Streaming (metrics ingestion), Dynamic Tables (performance dashboards), Cortex ML (anomaly detection), Alerts (SLA breach)
- **Business Outcome**: Service Reliability, Customer Satisfaction, SLA Compliance
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: 99.9%+ SLA achievement, 30-50% faster identification of tenant-impacting issues, proactive capacity scaling reducing incidents by 20-30%
- **Data Signals**: request latency per tenant, error rates, resource consumption (CPU, memory, I/O), queue depths, concurrent user counts, deployment events

### 10. Partner & Marketplace Ecosystem Analytics
- **Required Domains**: Partner, Integration, App/Listing, Install, Revenue Share, Co-Sell, Referral, API Usage
- **Required Patterns**: Partner contribution analysis, marketplace listing performance, integration health, co-sell pipeline, ecosystem network effects
- **Snowflake Features**: Data Sharing (partner portals), Dynamic Tables (marketplace dashboards), Snowpark (attribution modeling), Cortex ML (partner scoring)
- **Business Outcome**: Ecosystem Growth, Revenue Diversification, Platform Stickiness
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: 10-25% of revenue attributed to ecosystem, 15-30% lower churn for customers using 2+ integrations, data-driven partner tier management
- **Data Signals**: partner referrals, integration install/uninstall, API call volumes per integration, co-sell pipeline, marketplace listing views/installs, revenue share calculations

## Compliance Considerations
- SOC 2: Service organization controls (Type I/II) for security, availability, confidentiality
- ISO 27001: Information security management system certification
- GDPR: Data processing agreements, right to erasure, data portability (EU customers)
- CCPA: California consumer privacy rights, data deletion requests
- Data Residency/Sovereignty: Customer data location requirements by region/country
- FedRAMP: Federal Risk and Authorization Management Program (government customers)

## Marketplace Opportunities
- Firmographic data (company size, industry, technographic enrichment for ICP targeting)
- IP-to-company enrichment (anonymous visitor identification, account-based analytics)
- Technology install base data (competitive intelligence, integration opportunity identification)
- Benchmark metrics (SaaS benchmarks from OpenView, Bessemer, KeyBanc for board/investor reporting)
