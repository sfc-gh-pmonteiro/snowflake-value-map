# Retail & CPG Vertical - Use Case Catalog

## Vertical Signals

**PRIMARY** (unique to this vertical, weight 3):
sku, store, basket, cart, planogram, shelf, pos, loyalty, assortment, promotion, markdown, category_manager, upc, ean, gondola, endcap, facing

**SECONDARY** (suggestive but shared, weight 1):
product, order, inventory, price, customer, channel, return, margin, demand, forecast, supplier, warehouse, fulfillment, shipment

**NEGATIVE** (contradicts this vertical, weight -2):
patient, diagnosis, sensor, equipment, policy, premium, meter, grid, subscriber, msisdn

## Canonical Use Cases

### 1. Customer 360 & Omnichannel View
- **Required Domains**: Customer, Transaction, Loyalty, Digital Interaction, Store, Channel
- **Required Patterns**: Identity resolution (cross-channel), SCD2, event stream unification
- **Snowflake Features**: Dynamic Tables, Cortex Search (identity matching), Streams & Tasks
- **Business Outcome**: Revenue Growth, Customer Retention
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 15-30% improvement in customer lifetime value, 20-40% better personalization response
- **Data Signals**: `dim_customer`, `fact_transaction`, loyalty tables, web/app event tables, channel dimension

### 2. Demand Forecasting & Replenishment
- **Required Domains**: Product, Store, Sales History, Promotion, Seasonality, Weather, Event
- **Required Patterns**: Time-series forecasting, hierarchical aggregation (store/region/category), external signal enrichment
- **Snowflake Features**: Cortex ML (Forecasting), Snowpark (custom models), Marketplace (weather/event data), Dynamic Tables
- **Business Outcome**: Cost Reduction, Revenue Protection
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 20-40% reduction in stockouts, 15-25% reduction in overstock/waste, 2-5% margin improvement
- **Data Signals**: `fact_sales` (daily/weekly grain), `dim_product`, promotion calendar, store capacity

### 3. Price Optimization & Markdown Management
- **Required Domains**: Product, Price History, Competitor Price, Elasticity, Inventory Level, Margin
- **Required Patterns**: Price elasticity modeling, competitive intelligence, what-if simulation
- **Snowflake Features**: Snowpark ML, Marketplace (competitor pricing), Zero-copy Cloning (scenario testing)
- **Business Outcome**: Revenue Growth, Margin Improvement
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 2-5% revenue uplift, 1-3% margin improvement on optimized categories
- **Data Signals**: price change history, competitor price tables, margin calculations, elasticity coefficients

### 4. Personalized Recommendations & Next-Best-Offer
- **Required Domains**: Customer, Transaction, Product, Browsing Behavior, Preference, Segment
- **Required Patterns**: Collaborative filtering, content-based filtering, real-time feature serving
- **Snowflake Features**: Cortex ML, Snowpark (model training), Feature Store, Cortex AI (LLM for content)
- **Business Outcome**: Revenue Growth, Customer Engagement
- **Impact Weight**: HIGH
- **Industry Benchmark (not customer-specific)**: 10-25% increase in average order value, 5-15% conversion rate improvement
- **Data Signals**: purchase history, browse/click events, product attributes, customer segments

### 5. Supply Chain Visibility & Optimization
- **Required Domains**: Supplier, PO, Shipment, Inventory, Warehouse, Lead Time, Cost
- **Required Patterns**: Multi-tier visibility, lead time prediction, safety stock optimization, exception alerting
- **Snowflake Features**: Data Sharing (supplier collaboration), Dynamic Tables, Cortex ML (lead time prediction), Alerts
- **Business Outcome**: Cost Reduction, Operational Efficiency
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 10-20% reduction in safety stock, 15-30% improvement in supplier on-time delivery
- **Data Signals**: PO/shipment tracking, inventory snapshots, supplier scorecards, warehouse capacity

### 6. Promotion Effectiveness & Marketing Attribution
- **Required Domains**: Promotion, Campaign, Transaction, Customer, Channel, Spend
- **Required Patterns**: Lift analysis, multi-touch attribution, incrementality testing, ROI calculation
- **Snowflake Features**: Snowpark (attribution models), Data Clean Rooms (media partner data), Cortex ML
- **Business Outcome**: Revenue Growth, Cost Efficiency
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 15-30% improvement in marketing ROI, 10-20% reduction in promotion waste
- **Data Signals**: promotion master, campaign spend, transaction with promo flags, channel touchpoints

### 7. Store Performance & Location Intelligence
- **Required Domains**: Store, Transaction, Traffic, Staff, Geographic, Demographic
- **Required Patterns**: Benchmarking, clustering, geographic analysis, traffic correlation
- **Snowflake Features**: Geospatial functions, Marketplace (foot traffic, demographics), Cortex ML (clustering)
- **Business Outcome**: Revenue Growth, Operational Efficiency
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 5-10% same-store sales growth from optimized operations, better site selection
- **Data Signals**: store dimension with geo, daily/hourly sales, foot traffic, trade area demographics

### 8. Assortment Optimization
- **Required Domains**: Product, Store/Cluster, Sales, Space, Category, Customer Preference
- **Required Patterns**: Affinity analysis, space-to-sales optimization, local assortment tailoring
- **Snowflake Features**: Snowpark (optimization algorithms), Cortex ML (clustering stores), Dynamic Tables
- **Business Outcome**: Revenue Growth, Inventory Efficiency
- **Impact Weight**: MEDIUM
- **Industry Benchmark (not customer-specific)**: 3-8% sales uplift in optimized categories, reduced SKU proliferation
- **Data Signals**: product hierarchy, store clusters, space/shelf data, basket analysis tables

### 9. Returns & Fraud Analytics
- **Required Domains**: Return, Transaction, Customer, Product, Channel, Reason
- **Required Patterns**: Pattern detection, customer scoring, product defect identification, fraud rings
- **Snowflake Features**: Cortex ML (anomaly detection), Snowpark (pattern analysis), Cortex AI (reason text analysis)
- **Business Outcome**: Cost Reduction, Revenue Protection
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: 10-20% reduction in fraudulent returns, improved product quality feedback loops
- **Data Signals**: returns with reason codes, customer return history, product defect rates

### 10. Sustainability & Waste Reduction
- **Required Domains**: Product (perishable), Inventory, Waste/Shrink, Supply Chain, Carbon
- **Required Patterns**: Shelf-life tracking, waste prediction, circular economy metrics
- **Snowflake Features**: Cortex ML (waste prediction), Dynamic Tables (freshness tracking), Marketplace (sustainability benchmarks)
- **Business Outcome**: Cost Reduction, Brand/ESG
- **Impact Weight**: LOW
- **Industry Benchmark (not customer-specific)**: 20-40% reduction in food waste, 5-10% shrink reduction, ESG reporting capability
- **Data Signals**: expiration date tracking, shrink/waste tables, donation/markdown tables

## Compliance Considerations
- PCI-DSS: Payment card data handling
- GDPR/CCPA: Customer data, cookie consent, loyalty program data
- Food Safety (if grocery): Traceability requirements (FSMA 204)
- State-level privacy laws: Varies by jurisdiction

## Marketplace Opportunities
- Weather data (demand signals)
- Foot traffic / location data (SafeGraph, Placer)
- Demographic / psychographic data
- Competitor pricing intelligence
- Economic indicators (consumer confidence, inflation)
- Sustainability benchmarks
