# Features

Planned and future work for **OpenGlucoseTelemetry** (OGT).

---

## Future: npm package ecosystem (`@openglucose/*`)

Today the TypeScript reference ships as **`@openglucose/telemetry-runtime`** (OGT core: envelope validation, built-in adapters, normalization, semantic rules, OGIS-shaped canonical output). A natural evolution is to split optional and heavier concerns into sibling packages under the same scope so installs stay small and boundaries stay clear.

| Planned package | Role |
|-----------------|------|
| **`@openglucose/telemetry-runtime`** | **OGT core** (current package): pipeline + bundled MVP schemas needed for `submit()`. |
| **`@openglucose/ogis-schemas`** | **OGIS JSON Schemas** as a versioned artifact package (publish, resolve, optional codegen) so runtimes and services do not each vendor copies. |
| **`@openglucose/adapters-dexcom`** | Optional **Dexcom**-specific mapping, validators, or fixtures beyond the MVP core. |
| **`@openglucose/adapters-healthkit`** | Optional **HealthKit**-shaped helpers beyond the MVP core. |
| **`@openglucose/collector`** | **Full server / collector runtime** later: HTTP ingress, persistence, auth, queues, operations—everything outside the pure in-process pipeline. |

**Principles:** keep **core** dependency-light; add packages when mapping surface, schema delivery, or deployment glue warrants a separate release cadence and optional install.

---

## How to extend this file

Add dated or numbered feature bullets here, or link to **`specifications/plans/`** for detailed design before implementation.
