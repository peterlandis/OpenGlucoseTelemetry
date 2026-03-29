# Pinned OGIS artifacts (v0.1)

**Strategy:** Copy the canonical JSON Schema from the OGIS repository into this folder so OGT CI runs without a git submodule or npm dependency on OGIS.

| Artifact | OGIS source path (reference) | SHA-256 (pinned file) |
|----------|------------------------------|------------------------|
| `glucose.reading.v0_1.json` | `OpenGlucoseInteroperabilityStandard/schemas/jsonschema/glucose.reading.v0_1.json` | `ed8d099e349e453844aeec17ceffda6ebd0b6bf9e9751a4c6fdae6478817fb3a` |

**Update procedure:** Replace `glucose.reading.v0_1.json`, recompute SHA-256, bump this table and `specifications/handoff/VERSION-COMPATIBILITY.md`, and re-run `pnpm verify`.
