# Logistics & Transportation Vertical - Use Case Catalog

## Vertical Signals

**PRIMARY** (unique to this vertical, weight 3):
shipment, route, carrier, tracking, fleet, dock, load, delivery, eta, bol, freight, lane, drayage, last_mile, waypoint, consignment, demurrage

**SECONDARY** (suggestive but shared, weight 1):
warehouse, inventory, order, customer, vehicle, driver, schedule, cost, sla, geolocation

**NEGATIVE** (contradicts this vertical, weight -2):
patient, policy, meter, grid, viewership, diagnosis, premium, actuarial

## Canonical Use Cases

### 1. Route Optimization & ETA Prediction
- **Required Domains**: Route, Waypoint, Shipment, Vehicle, Traffic, Weather, Delivery Window, Constraint
- **Required Patterns**: Multi-stop optimization, real-time ETA recalculation, constraint satisfaction (time windows, weight, hazmat), historical transit time modeling
- **Snowflake Features**: Snowpark (optimization algorithms), Cortex ML (transit time prediction), Dynamic Tables (live ETA refresh), Marketplace (traffic, weather)
- **Business Outcome**: Cost Reduction, Customer Satisfaction, On-Time Delivery
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 10-20% reduction in miles driven, 15-30% improvement in on-time delivery, 5-15% fuel cost savings
- **Data Signals**: GPS breadcrumbs, stop times, traffic feeds, weather data, delivery time windows, historical route performance

### 2. Fleet Utilization & Maintenance
- **Required Domains**: Vehicle, Telematics, Maintenance Event, Driver, Fuel, Inspection, Odometer, Fault Code
- **Required Patterns**: Utilization benchmarking, predictive maintenance, fuel efficiency analysis, driver behavior scoring, compliance monitoring
- **Snowflake Features**: Snowpipe Streaming (telematics), Cortex ML (failure prediction, anomaly detection), Dynamic Tables (fleet dashboards), Alerts
- **Business Outcome**: Cost Reduction, Asset Longevity, Safety, Compliance
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 15-25% reduction in maintenance costs, 10-20% improvement in fleet utilization, 20-30% reduction in roadside breakdowns
- **Data Signals**: telematics (speed, idle, fuel, location), engine fault codes, maintenance work orders, inspection records, fuel transactions

### 3. Shipment Visibility & Exception Management
- **Required Domains**: Shipment, Tracking Event, Milestone, Exception, Carrier, Customer, SLA
- **Required Patterns**: End-to-end tracking, exception detection (delays, damage, loss), proactive alerting, root cause categorization
- **Snowflake Features**: Snowpipe Streaming (tracking events), Dynamic Tables (real-time status), Cortex ML (delay prediction), Alerts, Data Sharing (customer portals)
- **Business Outcome**: Customer Satisfaction, Operational Efficiency, Loss Prevention
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 40-60% reduction in customer "where is my shipment" inquiries, 20-35% faster exception resolution, improved OTIF scores
- **Data Signals**: EDI 214/tracking messages, scan events, milestone timestamps, exception codes, carrier communications, customer SLAs

### 4. Demand-Capacity Matching
- **Required Domains**: Demand Forecast, Capacity (driver, vehicle, warehouse), Lane, Season, Customer Commitment, Spot Market
- **Required Patterns**: Demand forecasting by lane/mode, capacity planning, surge prediction, contract vs. spot allocation
- **Snowflake Features**: Cortex ML (Forecasting), Dynamic Tables (capacity dashboards), Snowpark (optimization), Marketplace (economic indicators)
- **Business Outcome**: Revenue Optimization, Service Reliability, Cost Management
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 10-20% reduction in deadhead miles, 5-15% improvement in asset utilization, better contract pricing through demand visibility
- **Data Signals**: historical shipment volumes by lane, seasonal patterns, customer forecasts, driver availability, vehicle capacity, spot market rates

### 5. Carrier Performance & Procurement
- **Required Domains**: Carrier, Lane, Rate, Performance (OTIF, damage, claims), Contract, Scorecard, Bid
- **Required Patterns**: Carrier scoring, rate benchmarking, bid optimization, compliance tracking, relationship management
- **Snowflake Features**: Snowpark (scoring models), Dynamic Tables (scorecards), Cortex ML (rate prediction), Data Sharing (carrier collaboration)
- **Business Outcome**: Cost Reduction, Service Quality, Risk Mitigation
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 5-10% reduction in freight spend through optimized procurement, 10-20% improvement in carrier OTIF, reduced carrier-related claims
- **Data Signals**: rate confirmations, invoice data, delivery performance, damage/claims history, carrier insurance/compliance, bid responses

### 6. Warehouse Operations Analytics
- **Required Domains**: Warehouse, Zone, SKU, Inventory, Pick/Pack, Labor, Dock Door, Inbound/Outbound
- **Required Patterns**: Slotting optimization, labor productivity, dock scheduling, inventory velocity, throughput analysis
- **Snowflake Features**: Dynamic Tables (real-time throughput), Snowpark (slotting algorithms), Cortex ML (demand-driven staffing), Alerts
- **Business Outcome**: Operational Efficiency, Cost Reduction, Throughput
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 15-25% improvement in picks per hour, 10-20% reduction in dock dwell time, 20-30% improvement in space utilization
- **Data Signals**: WMS transaction logs, labor clock-in/task, dock appointment schedules, inventory snapshots, order profiles, slotting assignments

### 7. Last-Mile Delivery Optimization
- **Required Domains**: Delivery, Stop, Customer, Time Window, Driver, Vehicle, Proof of Delivery, Return
- **Required Patterns**: Dynamic routing, delivery density optimization, customer communication, failed delivery reduction, capacity planning
- **Snowflake Features**: Snowpark (routing optimization), Cortex ML (delivery success prediction), Dynamic Tables (real-time dispatch), Marketplace (address validation)
- **Business Outcome**: Cost Reduction, Customer Experience, Delivery Success Rate
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 15-25% reduction in cost per delivery, 20-40% reduction in failed deliveries, 30-50% improvement in ETA accuracy to end customer
- **Data Signals**: delivery attempt records, customer availability patterns, address quality scores, driver GPS, proof-of-delivery photos/signatures, return rates

### 8. Carbon Footprint & Sustainability
- **Required Domains**: Shipment, Mode, Distance, Vehicle Type, Fuel, Emission Factor, Scope (1/2/3), Customer Allocation
- **Required Patterns**: Emissions calculation per shipment/customer, mode shift analysis, carbon accounting (GHG protocol), offset tracking
- **Snowflake Features**: Snowpark (emission calculations), Marketplace (emission factor databases), Dynamic Tables (carbon dashboards), Data Sharing (customer reporting)
- **Business Outcome**: ESG Compliance, Customer Retention, Brand Value
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: Scope 1/2/3 reporting capability, 5-15% emissions reduction through mode optimization, customer-level carbon allocation for reporting
- **Data Signals**: fuel consumption, shipment distance/mode, vehicle emission class, emission factors (GLEC framework), carbon offset purchases, customer sustainability requirements

### 9. Claims & Damage Analytics
- **Required Domains**: Claim, Shipment, Carrier, Damage Type, Root Cause, Cost, Resolution, Customer
- **Required Patterns**: Claims trending, root cause analysis, carrier liability determination, fraud detection, cost allocation
- **Snowflake Features**: Cortex ML (classification, anomaly detection), Cortex AI (document/image analysis), Dynamic Tables (claims dashboards), Snowpark
- **Business Outcome**: Cost Recovery, Loss Reduction, Process Improvement
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: 20-30% improvement in claims recovery rates, 15-25% reduction in claims through root cause elimination, faster resolution cycle times
- **Data Signals**: claims filings, damage photos, shipment handling history, carrier performance, packaging specifications, temperature/shock logs

### 10. Network Design & Lane Optimization
- **Required Domains**: Facility, Lane, Volume, Cost, Transit Time, Service Level, Mode, Hub, Cross-Dock
- **Required Patterns**: Network modeling, hub location optimization, mode selection, consolidation opportunity identification, scenario analysis
- **Snowflake Features**: Snowpark (optimization, simulation), Cortex ML (volume forecasting), Dynamic Tables (network metrics), Marketplace (geographic/demographic)
- **Business Outcome**: Cost Reduction, Service Improvement, Strategic Planning
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 5-15% reduction in total network cost, improved service levels through strategic hub placement, better resilience through multi-path routing
- **Data Signals**: origin-destination volumes, lane costs, transit times, facility capacities, customer locations, growth projections, fuel/labor cost differentials

## Compliance Considerations
- DOT/FMCSA: Hours of Service (HOS), driver qualification, vehicle safety
- Customs/CBP: Import/export documentation, advance manifest filing
- CTPAT: Customs-Trade Partnership Against Terrorism (supply chain security)
- Hazmat Regulations: DOT 49 CFR, IATA DGR (dangerous goods transport)
- EU Transport Directives: Tachograph regulations, driver rest requirements, mobility package
- Emissions Reporting: EPA SmartWay, EU ETS, GLEC framework compliance

## Marketplace Opportunities
- Weather data (route planning, delay prediction, seasonal capacity planning)
- Traffic/congestion feeds (real-time routing, ETA accuracy)
- Fuel pricing (cost forecasting, procurement optimization)
- Port congestion data (ocean/intermodal planning, drayage scheduling)
- Address validation (delivery success, geocoding accuracy)
- Geospatial routing (road network, restriction data, toll costs)
