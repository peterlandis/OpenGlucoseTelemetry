# Open Glucose Telemetry (OGT)

OGT is an open, vendor-neutral telemetry and collection framework for ingesting, validating, normalizing, and streaming glucose-related data across devices, applications, and clinical systems.

## Mission

Glucose data today is fragmented across proprietary vendor APIs, inconsistent schemas, and siloed applications. Every new product must rebuild integrations from scratch.

OGT solves this by providing a unified telemetry layer that enables:

- standardized ingestion of glucose data
- real-time and historical data streaming
- consistent data pipelines across vendors
- seamless integration for apps, AI, and clinical systems

> Integrate once. Stream everywhere.

---

## What OGT Is

OGT is the **runtime and transport layer** for glucose data.

It provides:

- adapters for ingesting data from devices and vendor systems  
- a collector for validation, normalization, and routing  
- a canonical event pipeline for glucose telemetry  
- real-time and historical APIs  
- exporters for downstream systems  
- SDKs and tooling for developers  

OGT makes glucose data operational.

---

## Relationship to OGIS

OGT works together with the Open Glucose Interoperability Standard (OGIS).

- **OGIS** defines the data model, semantics, and interoperability contract  
- **OGT** implements the runtime system that ingests, transports, and delivers that data  

In simple terms:

> OGIS defines what glucose data means, and OGT defines how glucose data moves.

---

## High-Level Architecture

```text
Devices / Vendor APIs / Apps
        ↓
     Adapters
        ↓
   OGT Collector
        ↓
 Canonical Event Bus
        ↓
+-------------------+-------------------+-------------------+
| Query APIs        | Realtime APIs     | Exporters         |
| REST / gRPC       | WebSocket / MQTT  | FHIR / Webhooks   |
+-------------------+-------------------+-------------------+
        ↓
Apps • AI • Analytics • Clinical Systems • Research
