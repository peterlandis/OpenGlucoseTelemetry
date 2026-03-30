# Version compatibility (OGT ↔ OGIS ↔ GlucoseAITracker)

| Artifact | Version / pin |
|----------|----------------|
| OGT MVP package | `0.1.0` (`runtimes/typescript/package.json`; workspace root `package.json` orchestrates scripts) |
| OGIS `glucose.reading` schema | v0.1 — file `spec/pinned/glucose.reading.v0_1.json`; SHA-256 in `spec/pinned/PIN.md` |
| GlucoseAITracker | Consume when **GLUCOSE-009** integration is merged; minimum app version TBD per release notes |

When updating the pinned OGIS schema, bump the SHA in `spec/pinned/PIN.md`, re-run `pnpm verify` (from the repository root), and update GlucoseAITracker release notes.
