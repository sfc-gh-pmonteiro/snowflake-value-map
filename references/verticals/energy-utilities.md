# Energy & Utilities Vertical - Use Case Catalog

## Vertical Signals

**PRIMARY** (unique to this vertical, weight 3):
meter, grid, outage, generation, load_profile, renewable, demand_response, feeder, transformer, substation, kwh, mwh, ami, scada_grid, curtailment, interconnection

**SECONDARY** (suggestive but shared, weight 1):
consumption, asset, customer, billing, forecast, capacity, maintenance, sensor, iot, alert, tariff

**NEGATIVE** (contradicts this vertical, weight -2):
patient, policy, premium, viewership, episode, lot, batch, shipment

## Canonical Use Cases

### 1. Grid Reliability & Outage Management
- **Required Domains**: Grid Topology, Outage Event, SCADA, Customer, Feeder/Circuit, Crew/Dispatch
- **Required Patterns**: Real-time event correlation, root cause isolation, restoration prioritization, SAIDI/SAIFI calculation
- **Snowflake Features**: Snowpipe Streaming (SCADA events), Dynamic Tables (real-time grid state), Cortex ML (outage prediction), Alerts
- **Business Outcome**: Operational Reliability, Customer Satisfaction, Regulatory Compliance
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 20-40% reduction in outage duration (CAIDI), 15-30% improvement in restoration time, improved SAIDI/SAIFI scores
- **Data Signals**: SCADA alarms, outage management system events, crew dispatch records, customer calls, smart meter last-gasp signals

### 2. Demand Forecasting & Load Balancing
- **Required Domains**: Load Profile, Weather, Calendar, Customer Segment, Generation, Grid Constraint
- **Required Patterns**: Short/medium/long-term forecasting, peak prediction, load shape clustering, weather normalization
- **Snowflake Features**: Cortex ML (Forecasting), Snowpark (custom models), Dynamic Tables (rolling forecasts), Marketplace (weather)
- **Business Outcome**: Cost Reduction, Grid Stability, Capacity Planning
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 10-20% improvement in forecast accuracy, 5-15% reduction in peak procurement costs, reduced reserve margin requirements
- **Data Signals**: interval meter data, weather feeds, historical load curves, economic indicators, calendar/event data

### 3. Smart Meter Analytics & Revenue Protection
- **Required Domains**: AMI Meter, Interval Reading, Billing, Tamper Event, Customer, Account
- **Required Patterns**: Consumption anomaly detection, theft identification, meter health monitoring, unbilled revenue estimation
- **Snowflake Features**: Cortex ML (Anomaly Detection), Snowpipe Streaming (meter data), Dynamic Tables (near-real-time analytics)
- **Business Outcome**: Revenue Protection, Operational Efficiency, Loss Reduction
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 1-3% recovery of non-technical losses (often millions in revenue), 30-50% improvement in theft detection accuracy
- **Data Signals**: 15-minute interval reads, meter tamper alerts, billing discrepancies, consumption-to-weather correlation, neighbor comparison

### 4. Renewable Integration & Curtailment Optimization
- **Required Domains**: Generation Source, Curtailment Event, Grid Capacity, Weather/Irradiance, Storage, Interconnection
- **Required Patterns**: Generation forecasting, curtailment minimization, storage dispatch optimization, capacity factor analysis
- **Snowflake Features**: Cortex ML (generation forecasting), Dynamic Tables (dispatch optimization), Marketplace (solar irradiance, wind)
- **Business Outcome**: Revenue Maximization, Sustainability Goals, Grid Stability
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 10-25% reduction in curtailment, 5-15% improvement in renewable capacity factor, better PPA economics
- **Data Signals**: inverter/turbine telemetry, weather forecasts, grid congestion signals, storage state-of-charge, market pricing

### 5. Asset Health & Predictive Maintenance
- **Required Domains**: Transformer, Switch, Pole, Conductor, Inspection, DGA (dissolved gas), Load History, Age/Condition
- **Required Patterns**: Remaining useful life estimation, risk ranking, condition-based maintenance, failure probability scoring
- **Snowflake Features**: Cortex ML (classification, forecasting), Snowpark (risk models), Dynamic Tables (health scoring refresh)
- **Business Outcome**: Cost Reduction, Reliability Improvement, Capital Planning
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 20-35% reduction in unplanned failures, 10-20% extension of asset life, optimized capital replacement programs
- **Data Signals**: DGA test results, thermal imaging, load history, age/vintage, inspection scores, failure history

### 6. Customer Segmentation & Rate Optimization
- **Required Domains**: Customer, Load Profile, Rate/Tariff, Program Enrollment, Demographics, Billing History
- **Required Patterns**: Load shape clustering, rate migration analysis, time-of-use impact modeling, propensity scoring
- **Snowflake Features**: Snowpark (clustering, segmentation), Cortex ML (propensity), Dynamic Tables (segment refresh), Data Sharing
- **Business Outcome**: Revenue Optimization, Customer Satisfaction, Program Adoption
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 5-15% improvement in program enrollment, optimized rate design reducing cross-subsidization, improved customer satisfaction scores
- **Data Signals**: interval consumption, rate class, program participation, demographics, payment history, survey/NPS data

### 7. Distributed Energy Resource (DER) Management
- **Required Domains**: Solar PV, Battery, EV Charger, Smart Thermostat, Hosting Capacity, Interconnection Queue
- **Required Patterns**: DER visibility/forecasting, hosting capacity analysis, virtual power plant dispatch, grid impact assessment
- **Snowflake Features**: Snowpipe Streaming (DER telemetry), Dynamic Tables (aggregation), Cortex ML (generation/consumption forecasting)
- **Business Outcome**: Grid Stability, Customer Enablement, Regulatory Compliance
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: Improved DER visibility from 30% to 80%+, reduced interconnection study time by 40-60%, better hosting capacity utilization
- **Data Signals**: behind-the-meter generation, DER registry, inverter telemetry, hosting capacity maps, interconnection applications

### 8. Regulatory Compliance & Rate Case Analytics
- **Required Domains**: Cost, Revenue, Rate Base, Depreciation, Test Year, Regulatory Filing, Benchmark
- **Required Patterns**: Cost-of-service allocation, test year normalization, peer benchmarking, filing preparation
- **Snowflake Features**: Snowpark (regulatory calculations), Dynamic Tables (rolling test year), Data Sharing (regulatory submissions)
- **Business Outcome**: Regulatory Compliance, Revenue Recovery, Operational Transparency
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: 30-50% reduction in rate case preparation time, improved data accuracy in filings, faster regulatory response
- **Data Signals**: general ledger, plant-in-service, depreciation schedules, O&M costs, customer counts, load data, comparable utility benchmarks

### 9. Vegetation Management & Wildfire Risk
- **Required Domains**: Vegetation/Tree, Circuit/Span, Weather, Fire Risk Zone, LiDAR, Inspection, Work Order
- **Required Patterns**: Risk scoring (vegetation + weather + fire zone), prioritization, growth modeling, spend optimization
- **Snowflake Features**: Cortex ML (risk classification), Marketplace (satellite imagery, weather), Snowpark (geospatial analysis), Dynamic Tables
- **Business Outcome**: Safety, Regulatory Compliance, Cost Optimization, Wildfire Mitigation
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 30-50% reduction in vegetation-caused outages, risk-prioritized trimming improving spend efficiency by 20-30%, wildfire liability reduction
- **Data Signals**: LiDAR point clouds, satellite/aerial imagery, circuit-tree proximity, fire weather indices, historical trim cycles, outage cause codes

### 10. Electric Vehicle Load Impact Analysis
- **Required Domains**: EV Registration, Charging Session, Transformer Load, Grid Capacity, Customer, Rate
- **Required Patterns**: EV adoption forecasting, transformer loading analysis, managed charging optimization, infrastructure planning
- **Snowflake Features**: Cortex ML (forecasting), Marketplace (EV registration data), Dynamic Tables (load aggregation), Snowpark (scenario modeling)
- **Business Outcome**: Infrastructure Planning, Grid Reliability, Revenue Growth
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: 2-5 year advance planning for transformer upgrades, 15-30% peak load reduction through managed charging, new EV rate revenue streams
- **Data Signals**: EV registration by zip/feeder, charging session data, transformer nameplate/loading, time-of-use enrollment, grid capacity headroom

## Compliance Considerations
- NERC CIP: Critical infrastructure protection for bulk electric system
- FERC: Federal Energy Regulatory Commission reporting and market rules
- PUC/State Regulators: Rate cases, integrated resource plans, reliability standards
- EPA: Emissions reporting, coal ash, water discharge
- CPUC (California): Wildfire mitigation plans, PSPS reporting
- Smart Meter Privacy: Customer energy usage data protection (Green Button, state laws)

## Marketplace Opportunities
- Weather data (load forecasting, renewable prediction, storm preparation)
- Satellite imagery (vegetation management, infrastructure monitoring)
- EV registration data (load planning, infrastructure siting)
- Solar irradiance & wind speed (generation forecasting)
- Commodity pricing (natural gas, power markets)
- Demographic/building data (load growth, energy efficiency targeting)
