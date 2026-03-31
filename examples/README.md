# Examples

- `ingestion/` — OGT ingestion envelopes (positive and negative).
- `canonical/` — Expected OGIS `glucose.reading` v0.1 output for golden tests. See [`canonical/README.md`](./canonical/README.md) for **cross-runtime golden** (TS vs Swift) workflow and `pnpm parity:check`.

Golden ingestion fixtures include `healthkit-sample.json`, `dexcom-sample.json`, and `manual-sample.json`.

Reference OGIS event examples live in the [OpenGlucoseInteroperabilityStandard](https://github.com/openglucose/OpenGlucoseInteroperabilityStandard) repository under `examples/`.
