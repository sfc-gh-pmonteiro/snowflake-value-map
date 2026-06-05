# Snowflake Capabilities Reference

Map of Snowflake features to data patterns and use case enablement.

## Core Platform Features

### Dynamic Tables
- **Pattern**: Continuous transformation, materialized pipelines, real-time aggregation
- **Enables**: Real-time dashboards, feature stores, KPI monitoring, SLA tracking
- **When to recommend**: Entity needs fresh gold layer, streaming-to-batch bridge, or complex DAG of transformations
- **Gap it closes**: "We need real-time aggregates but only have batch ETL"

### Streams & Tasks
- **Pattern**: CDC (change data capture), event-driven processing, incremental loads
- **Enables**: Slowly changing dimensions, audit trails, event processing
- **When to recommend**: Entity has SCD2 patterns, needs incremental processing, event-driven triggers
- **Gap it closes**: "We need to track changes and process only new data"

### Snowpipe Streaming
- **Pattern**: Real-time/near-real-time ingestion, sub-second latency
- **Enables**: IoT ingestion, real-time fraud scoring, live dashboards, streaming analytics
- **When to recommend**: Entity has real-time data sources (sensors, clickstream, transactions)
- **Gap it closes**: "We need sub-minute latency for operational use cases"

### Time Travel & Cloning
- **Pattern**: Point-in-time recovery, historical snapshots, scenario testing
- **Enables**: Regulatory snapshots, A/B testing environments, disaster recovery, what-if analysis
- **When to recommend**: Entity needs audit compliance, development environments, or scenario modeling
- **Gap it closes**: "We need to reproduce state at any point in time"

## AI & ML Features

### Cortex ML - Forecasting
- **Pattern**: Time-series prediction, demand planning, capacity planning
- **Enables**: Demand forecasting, revenue forecasting, network capacity, resource planning
- **When to recommend**: Entity has time-series gold tables and needs forward-looking predictions
- **Gap it closes**: "We have historical data but no predictive capability"

### Cortex ML - Anomaly Detection
- **Pattern**: Outlier identification, unusual behavior detection, threshold-free alerting
- **Enables**: Fraud detection, network fault detection, quality alerts, revenue assurance
- **When to recommend**: Entity has event/transaction data and needs pattern-break detection
- **Gap it closes**: "We need to detect unusual patterns without manual thresholds"

### Cortex ML - Classification
- **Pattern**: Binary/multi-class prediction, scoring, segmentation
- **Enables**: Churn prediction, risk scoring, lead scoring, defect prediction
- **When to recommend**: Entity has labeled outcomes and wants predictive scoring
- **Gap it closes**: "We need to predict which customers/items will [outcome]"

### Cortex ML - Top Insights (Contribution Explorer)
- **Pattern**: Automated root cause analysis, dimension contribution ranking
- **Enables**: Metric movement explanation, KPI variance decomposition, automated drill-down
- **When to recommend**: Entity has metrics/KPIs and needs automated "why did X change?" analysis
- **Gap it closes**: "We can see metrics changed but can't quickly explain why"

### Cortex AI - LLM Functions (COMPLETE, SUMMARIZE, EXTRACT_ANSWER, SENTIMENT, TRANSLATE)
- **Pattern**: Text analysis, summarization, extraction, generation, translation, sentiment scoring
- **Enables**: Document processing, multilingual support, sentiment tracking, structured extraction from text
- **When to recommend**: Entity has unstructured text data (notes, complaints, reports, emails, tickets)
- **Gap it closes**: "We have text/document data we can't analyze at scale"

### Cortex AI - EMBED & Vector Similarity
- **Pattern**: Text/image embedding, vector search, semantic similarity, nearest-neighbor retrieval
- **Enables**: Semantic search, recommendation by similarity, duplicate detection, content clustering
- **When to recommend**: Entity needs meaning-based matching beyond keyword search
- **Gap it closes**: "Exact match search misses semantically similar records"

### Cortex AI - Fine-Tuning
- **Pattern**: Domain-adapted LLM, custom instruction following, enterprise-specific language
- **Enables**: Industry-specific text processing, custom classification, domain terminology handling
- **When to recommend**: Entity has domain-specific language (medical, legal, technical) where general LLMs underperform
- **Gap it closes**: "General AI doesn't understand our industry terminology/context"

### Cortex Agents
- **Pattern**: Multi-step autonomous AI workflows, tool-use orchestration, analyst-in-a-box
- **Enables**: Natural language data exploration, automated investigation, self-service analytics, complex multi-hop reasoning
- **When to recommend**: Entity wants end-users (non-technical) querying data conversationally, or needs automated multi-step analysis pipelines
- **Gap it closes**: "We need AI that can reason, plan, query data, and take actions autonomously"
- **Key capabilities**: Tool calling (SQL, search, APIs), multi-turn reasoning, guardrails, data grounding via semantic views

### Cortex Analyst
- **Pattern**: Natural language to SQL, self-service BI, governed analytical queries
- **Enables**: Business user SQL generation, governed self-service analytics, conversational BI
- **When to recommend**: Entity has gold-layer tables and non-technical users needing data access without writing SQL
- **Gap it closes**: "Business users can't get answers without waiting for analysts/engineers"
- **Key capabilities**: Semantic model grounding, verified queries, context retention, multi-turn conversation

### Cortex Search
- **Pattern**: Hybrid semantic + keyword search, RAG retrieval, entity matching
- **Enables**: Knowledge base search, patient/entity matching, document retrieval, chatbot grounding
- **When to recommend**: Entity needs fuzzy/semantic matching, RAG pipelines, or search over structured/semi-structured data
- **Gap it closes**: "We need to find similar/matching records across datasets" or "We need grounded AI answers from our documents"
- **Key capabilities**: Automatic embedding, hybrid ranking, filtering, incremental refresh

### Cortex Document AI (Document Intelligence)
- **Pattern**: Document parsing, structured extraction from PDFs/images, OCR + LLM
- **Enables**: Invoice processing, contract extraction, form digitization, medical record parsing
- **When to recommend**: Entity has document-based workflows (invoices, contracts, claims, forms) that need automation
- **Gap it closes**: "We manually process documents to extract structured data"

### Semantic Views
- **Pattern**: Business-friendly data catalog, governed semantic layer, natural language interface definition
- **Enables**: Self-service analytics grounding, Cortex Analyst/Agent data access, business metric definitions
- **When to recommend**: Entity has gold-layer tables and wants governed AI access or self-service analytics
- **Gap it closes**: "AI tools query wrong columns / misunderstand business logic" or "We need a governed semantic layer for AI"
- **Key capabilities**: Metric definitions (measures/dimensions), join relationships, synonyms, filters, verified queries
- **Critical for**: Cortex Analyst grounding, Cortex Agent data tool, Snowflake Intelligence

### Snowflake Intelligence
- **Pattern**: Conversational analytics assistant, enterprise data copilot
- **Enables**: Organization-wide self-service data exploration, cross-domain analysis, automated insights
- **When to recommend**: Entity wants an enterprise-grade AI analyst accessible to all business users
- **Gap it closes**: "We need a single AI interface for all our data across domains"
- **Key capabilities**: Multi-semantic-view routing, tool use, memory, enterprise deployment

### Snowpark ML & Model Registry
- **Pattern**: Custom ML model training, deployment, versioning, monitoring
- **Enables**: Complex ML use cases beyond built-in functions, custom algorithms, MLOps
- **When to recommend**: Entity has data science teams, needs custom models beyond Cortex ML built-ins
- **Gap it closes**: "We need custom models with full lifecycle management"

### Feature Store
- **Pattern**: Centralized feature computation, point-in-time correctness, feature reuse
- **Enables**: ML feature engineering, consistent features across training/serving
- **When to recommend**: Entity has multiple ML use cases sharing overlapping features
- **Gap it closes**: "We recompute features per model and have training/serving skew"

### Snowflake Notebooks
- **Pattern**: Interactive development, exploration, collaboration, mixed SQL/Python/Markdown
- **Enables**: Data science exploration, ETL prototyping, collaborative analysis, scheduled notebooks
- **When to recommend**: Entity has data science/analytics teams needing interactive development environment
- **Gap it closes**: "We need collaborative notebooks that run on our data without extract"

### Snowpark Container Services (SPCS)
- **Pattern**: Custom containerized workloads, GPU compute, model serving, custom apps
- **Enables**: Custom ML inference (PyTorch/TensorFlow), GPU-accelerated processing, full-stack apps alongside data
- **When to recommend**: Entity needs custom model serving, GPU workloads, or containerized applications with data locality
- **Gap it closes**: "We need to run custom containers/models next to our data without data movement"

### Cortex Guard (AI Guardrails)
- **Pattern**: Content safety, toxicity filtering, PII detection in AI outputs, policy enforcement
- **Enables**: Safe AI deployment, content moderation, regulatory compliance for AI outputs
- **When to recommend**: Entity deploying customer-facing AI and needs safety/compliance guarantees
- **Gap it closes**: "We need to ensure AI outputs are safe, compliant, and don't leak sensitive data"

## Data Collaboration

### Secure Data Sharing
- **Pattern**: Zero-copy data exchange, provider-consumer model, live data access
- **Enables**: Partner data exchange, customer portals, B2B data products
- **When to recommend**: Entity needs to share data with external parties without copying
- **Gap it closes**: "We need to share live data with partners/customers securely"

### Data Clean Rooms
- **Pattern**: Privacy-preserving analytics, multi-party computation, overlap analysis
- **Enables**: Media measurement, clinical trial collaboration, competitive benchmarking
- **When to recommend**: Entity needs to collaborate on sensitive data without exposing raw records
- **Gap it closes**: "We need to analyze combined datasets without revealing individual records"

### Snowflake Marketplace
- **Pattern**: Third-party data acquisition, external enrichment, reference data
- **Enables**: SDOH data, weather correlation, market data, ESG scores, demographic enrichment
- **When to recommend**: Entity has data gaps that external sources can fill
- **Gap it closes**: "We need external data sources we don't collect ourselves"

## Governance & Security

### Row-Level Security & Masking
- **Pattern**: Fine-grained access control, dynamic data masking, role-based visibility
- **Enables**: HIPAA compliance, multi-tenant access, PII protection, regulatory compliance
- **When to recommend**: Entity has compliance requirements (HIPAA, GDPR, PCI-DSS, SOX)
- **Gap it closes**: "We need different users to see different data based on their role/context"

### Data Lineage & Governance
- **Pattern**: Impact analysis, audit trail, data catalog, quality monitoring
- **Enables**: Regulatory compliance, change impact analysis, data quality tracking
- **When to recommend**: Entity has regulatory reporting or complex transformation chains
- **Gap it closes**: "We need to trace where data comes from and what depends on it"

### Object Tagging & Classification
- **Pattern**: Metadata management, sensitivity labeling, data classification
- **Enables**: PII discovery, data catalog enrichment, policy automation
- **When to recommend**: Entity needs automated data governance at scale
- **Gap it closes**: "We don't know where our sensitive data lives"

## Performance & Scale

### Materialized Views
- **Pattern**: Pre-computed query results, automatic refresh, query acceleration
- **Enables**: Dashboard performance, repeated query patterns, report acceleration
- **When to recommend**: Entity has repeated expensive queries on large gold tables
- **Gap it closes**: "Our dashboards/reports are too slow on large datasets"

### Search Optimization Service
- **Pattern**: Point lookups, selective filters on large tables
- **Enables**: Fast lookups on non-clustered columns, ad-hoc filtering
- **When to recommend**: Entity has large tables with varied access patterns
- **Gap it closes**: "Queries filtering on non-primary columns are slow"

### Clustering
- **Pattern**: Data organization, scan reduction, co-located storage
- **Enables**: Fast time-range queries, partition-like performance, large table optimization
- **When to recommend**: Entity has large tables primarily queried by specific columns (date, region)
- **Gap it closes**: "Full table scans on large fact tables are expensive"

## Semi-Structured & Specialized

### VARIANT & Semi-Structured
- **Pattern**: JSON/Avro/Parquet/XML handling, schema-on-read, nested data
- **Enables**: IoT telemetry, API responses, FHIR/HL7, event payloads
- **When to recommend**: Entity has variable-schema data or deeply nested structures
- **Gap it closes**: "Our data doesn't fit a fixed schema" or "We have JSON/XML sources"

### Geospatial Functions
- **Pattern**: Location analysis, distance calculation, polygon operations, spatial joins
- **Enables**: Store analysis, coverage mapping, proximity alerts, trade area analysis
- **When to recommend**: Entity has latitude/longitude, address, or boundary data
- **Gap it closes**: "We need location-aware analytics (distance, coverage, clustering)"

### Alerts & Notifications
- **Pattern**: Threshold monitoring, exception alerting, SLA breach detection
- **Enables**: Operational monitoring, SLA tracking, anomaly notification
- **When to recommend**: Entity needs automated exception detection and notification
- **Gap it closes**: "We need to be notified when metrics breach thresholds"

## Data Engineering & Apps

### Native Apps Framework
- **Pattern**: Packaged data applications, provider-consumer monetization, SaaS on Snowflake
- **Enables**: Data product distribution, monetized analytics, white-label solutions, ISV deployment
- **When to recommend**: Entity wants to productize their data/analytics for customers or internal org distribution
- **Gap it closes**: "We need to package and distribute our analytics/models as a product"

### Apache Iceberg Tables
- **Pattern**: Open table format, multi-engine access, interoperability
- **Enables**: Lakehouse architecture, Spark/Trino interop, vendor-neutral storage, external catalog integration
- **When to recommend**: Entity has multi-engine environments or needs open format guarantees
- **Gap it closes**: "We need data accessible from multiple engines without lock-in"

### Snowpark (Python/Java/Scala)
- **Pattern**: DataFrame API, server-side execution, pushdown computation
- **Enables**: Complex transformations, UDFs, stored procedures, data engineering in Python
- **When to recommend**: Entity has Python/Java teams, complex transformation logic beyond SQL
- **Gap it closes**: "Some transformations are too complex for SQL but we don't want to extract data"

### Streamlit in Snowflake
- **Pattern**: Interactive data applications, dashboards, internal tools
- **Enables**: Custom analytics apps, operational dashboards, data entry forms, ML model UIs
- **When to recommend**: Entity needs custom interactive applications on top of their data
- **Gap it closes**: "We need custom UIs for data exploration / operational workflows without external infra"

### External Functions & API Integrations
- **Pattern**: REST API callouts from SQL, external service integration
- **Enables**: Geocoding, CRM enrichment, payment processing, external ML model calls
- **When to recommend**: Entity needs to call external services as part of data pipelines
- **Gap it closes**: "We need to enrich/validate data using external APIs during processing"

## Architecture Patterns

### Medallion Architecture (Bronze/Silver/Gold)
- **Recognition**: Schemas named raw/bronze/staging -> silver/clean -> gold/marts/analytics
- **Snowflake Alignment**: Streams (bronze->silver), Dynamic Tables (silver->gold), Tasks (orchestration)
- **Best Practices**: Separate warehouses per layer, incremental processing, schema evolution handling

### Data Mesh
- **Recognition**: Domain-based schemas, data products, ownership boundaries
- **Snowflake Alignment**: Database-per-domain, Data Sharing (cross-domain), Object Tagging (ownership)
- **Best Practices**: Governed sharing, standardized interfaces, domain-specific warehouses

### Lambda / Kappa
- **Recognition**: Real-time + batch paths, speed layer, serving layer
- **Snowflake Alignment**: Snowpipe Streaming (speed), Dynamic Tables (serving), Tasks (batch)
- **Best Practices**: Unified with Dynamic Tables where possible, reduce complexity of dual paths

### AI-Native Data Platform
- **Recognition**: Semantic views defined, LLM functions in transforms, agent/analyst endpoints, vector columns
- **Snowflake Alignment**: Semantic Views (grounding) + Cortex Agents (interaction) + Cortex Search (retrieval) + Dynamic Tables (feature serving)
- **Best Practices**: Semantic view per gold domain, guardrails on all AI outputs, RAG over documents via Cortex Search, fine-tune for domain terminology
- **Key AI Stack**:
  - **Grounding**: Semantic Views define business logic for AI
  - **Retrieval**: Cortex Search provides RAG over structured/unstructured
  - **Reasoning**: Cortex Agents orchestrate multi-step analysis
  - **Generation**: LLM functions (COMPLETE/SUMMARIZE) produce outputs
  - **Safety**: Cortex Guard enforces content policies
  - **Custom ML**: Snowpark ML + SPCS for bespoke models

### RAG Architecture
- **Recognition**: Document ingestion, chunking, embedding columns, search services, LLM completion with context
- **Snowflake Alignment**: Cortex Search (indexing + retrieval) + COMPLETE (generation) + Cortex Guard (safety)
- **Best Practices**: Chunk documents into semantic units, use Cortex Search for hybrid retrieval, ground LLM calls with retrieved context, apply guardrails on output
- **When to recommend**: Entity has knowledge bases, documentation, policies, or unstructured content users need to query naturally
