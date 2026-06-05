# Manufacturing Vertical - Use Case Catalog

## Vertical Signals

**PRIMARY** (unique to this vertical, weight 3):
equipment, bom, work_order, production_order, oee, downtime, plc, scada, mes, erp, yield, throughput, cycle_time, spc, first_pass, changeover, tooling

**SECONDARY** (suggestive but shared, weight 1):
machine, sensor, lot, batch, quality, defect, inspection, maintenance, asset, supplier, material, warehouse, shipment, iot, telemetry

**NEGATIVE** (contradicts this vertical, weight -2):
patient, diagnosis, subscriber, msisdn, policy, premium, meter, grid, viewership, sku, store, basket

## Canonical Use Cases

### 1. Predictive Maintenance & Asset Health
- **Required Domains**: Equipment/Asset, Sensor/Telemetry, Maintenance History, Failure, Spare Parts
- **Required Patterns**: Time-series (sensor data), anomaly detection, remaining useful life prediction, alerting
- **Snowflake Features**: Snowpipe Streaming, Cortex ML (Anomaly Detection, Forecasting), Dynamic Tables, Alerts
- **Business Outcome**: Cost Reduction, Operational Efficiency
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 25-40% reduction in unplanned downtime, 15-25% reduction in maintenance costs, 5-10% asset life extension
- **Data Signals**: sensor readings (vibration, temperature, pressure), maintenance work orders, failure logs, asset registry

### 2. Quality Analytics & Defect Prediction
- **Required Domains**: Inspection, Lot/Batch, Process Parameter, Material, Defect, Test Result
- **Required Patterns**: SPC (statistical process control), root cause analysis, correlation (process params -> defects)
- **Snowflake Features**: Snowpark (statistical analysis), Cortex ML (classification), Dynamic Tables (real-time SPC)
- **Business Outcome**: Cost Reduction, Quality Improvement
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 20-40% reduction in scrap/rework, 10-25% improvement in first-pass yield
- **Data Signals**: inspection results, process parameter logs, defect classification, material lot tracking

### 3. Overall Equipment Effectiveness (OEE) Optimization
- **Required Domains**: Machine, Production Run, Downtime Event, Speed/Rate, Quality Output
- **Required Patterns**: Availability + Performance + Quality decomposition, loss categorization, benchmarking
- **Snowflake Features**: Dynamic Tables (real-time OEE), Snowpark (OEE calculations), Cortex ML (loss prediction)
- **Business Outcome**: Operational Efficiency, Revenue Growth (capacity)
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 5-15% OEE improvement (often worth millions in unlocked capacity)
- **Data Signals**: machine state tables, production count, downtime/stop reason codes, reject/rework counts

### 4. Supply Chain & Procurement Optimization
- **Required Domains**: Supplier, Material, PO, Delivery, Inventory, BOM, Lead Time, Cost
- **Required Patterns**: Lead time prediction, supplier scoring, safety stock optimization, BOM explosion
- **Snowflake Features**: Cortex ML (lead time forecasting), Data Sharing (supplier collaboration), Dynamic Tables, Marketplace
- **Business Outcome**: Cost Reduction, Operational Resilience
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 10-20% reduction in material costs, 20-30% improvement in on-time delivery, reduced stockout risk
- **Data Signals**: PO history, supplier performance, material master, BOM structure, inventory levels

### 5. Production Planning & Scheduling
- **Required Domains**: Work Order, Machine/Resource, BOM, Demand, Capacity, Constraint
- **Required Patterns**: Constraint-based scheduling, demand-capacity balancing, sequence optimization
- **Snowflake Features**: Snowpark (optimization algorithms), Dynamic Tables (plan refresh), Cortex ML (demand forecasting)
- **Business Outcome**: Operational Efficiency, Customer Satisfaction (on-time delivery)
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 10-20% improvement in schedule adherence, 5-15% reduction in changeover time
- **Data Signals**: work order/production order tables, machine calendar, demand forecast, capacity constraints

### 6. Energy Management & Sustainability
- **Required Domains**: Energy Meter, Machine, Production Run, Carbon Factor, Cost Rate, Target
- **Required Patterns**: Energy per unit tracking, anomaly detection (waste), peak shaving, carbon accounting
- **Snowflake Features**: Cortex ML (energy forecasting), Dynamic Tables (real-time monitoring), Marketplace (carbon factors)
- **Business Outcome**: Cost Reduction, ESG Compliance
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 10-20% reduction in energy costs, carbon reporting capability, regulatory compliance
- **Data Signals**: energy meter readings, production-energy correlation, utility rate tables, carbon emission factors

### 7. Digital Twin & Process Optimization
- **Required Domains**: Machine, Sensor (high-frequency), Process Parameter, Product Spec, Outcome
- **Required Patterns**: High-volume time-series, parameter correlation, optimization, simulation
- **Snowflake Features**: Snowpipe Streaming, Snowpark (ML models), VARIANT (complex telemetry), Dynamic Tables
- **Business Outcome**: Quality, Yield Improvement, Innovation
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 5-15% yield improvement, accelerated new product introduction, reduced trial-and-error
- **Data Signals**: high-frequency sensor data, recipe/setpoint tables, product spec, outcome measurements

### 8. Traceability & Genealogy
- **Required Domains**: Lot/Batch, Material, Process Step, Equipment, Operator, Quality Result, Customer/Shipment
- **Required Patterns**: Forward/backward traceability, lot genealogy tree, containment scope analysis
- **Snowflake Features**: Graph-like queries (recursive CTEs), Dynamic Tables, Data Sharing (customer traceability)
- **Business Outcome**: Compliance, Risk Mitigation, Customer Trust
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 80-90% reduction in recall scope, regulatory compliance (FDA, IATF), reduced liability exposure
- **Data Signals**: lot genealogy links, material consumption logs, process step records, quality certificates

### 9. Workforce Productivity & Safety
- **Required Domains**: Operator, Shift, Machine, Production Output, Incident, Training, Certification
- **Required Patterns**: Productivity benchmarking, safety incident correlation, skills gap analysis, schedule optimization
- **Snowflake Features**: Snowpark (productivity models), Cortex ML (incident prediction), Cortex AI (report analysis)
- **Business Outcome**: Operational Efficiency, Safety, Compliance
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: 10-15% improvement in labor productivity, 20-40% reduction in safety incidents
- **Data Signals**: shift/operator assignment, production output per operator, incident reports, training records

### 10. Connected Product & After-Sales Analytics
- **Required Domains**: Product (in-field), Telemetry, Warranty, Service Request, Failure Mode, Customer
- **Required Patterns**: Product usage monitoring, failure prediction, warranty cost analysis, service optimization
- **Snowflake Features**: Snowpipe Streaming (product telemetry), Cortex ML (failure prediction), Data Sharing (customer portal)
- **Business Outcome**: Revenue (service contracts), Customer Satisfaction, Product Improvement
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: 20-30% reduction in warranty costs, new service revenue streams, faster product improvement cycles
- **Data Signals**: in-field telemetry, warranty claims, service tickets, failure mode classification

## Compliance Considerations
- ISO 9001/IATF 16949: Quality management traceability requirements
- FDA 21 CFR Part 11: Electronic records (pharma/food manufacturing)
- OSHA: Safety data retention
- Environmental (EPA/EU): Emissions reporting, waste tracking
- Export Control (ITAR/EAR): Restricted product data handling
- Industry 4.0 standards: OPC-UA, ISA-95 data model alignment

## Marketplace Opportunities
- Weather data (production impact, energy planning)
- Commodity pricing (material cost forecasting)
- Logistics/transportation data
- Equipment reference databases (failure modes, MTBF benchmarks)
- Sustainability/carbon factor databases
- Economic indicators (demand signals)
