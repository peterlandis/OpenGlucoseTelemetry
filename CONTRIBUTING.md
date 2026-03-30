# Contributing to OGIS / OGT

Thank you for your interest in contributing!

## Philosophy

OGIS and OGT are open standards intended to be:

- vendor-neutral
- developer-friendly
- widely adoptable
- clinically alignable

We aim to build these standards in the open with community input.

---

## How to Contribute

You can contribute by:

- proposing changes via RFCs
- improving documentation
- adding schemas or examples
- implementing adapters or exporters (OGT)
- reporting issues or inconsistencies

---

## RFC Process

Major changes should go through an RFC (Request for Comments).

### Steps:

1. Create a new RFC file under `/rfcs`
2. Use the RFC template
3. Open a Pull Request
4. Discuss with the community
5. Iterate and refine
6. Once approved, merge into the main spec

---

## Contribution Guidelines

- Follow existing naming and structure conventions
- Keep changes focused and minimal
- Include examples when possible
- Maintain backward compatibility where feasible
- Document any breaking changes clearly

---

## Code Contributions (OGT)

- Write clear, modular code
- Include tests where appropriate
- Avoid vendor-specific assumptions in core components
- Keep adapters isolated from core logic
- **Runtime layout:** shared contracts live at the repo root (`spec/`, `examples/`). Language-specific implementations live under **`runtimes/<language>/`** (for example `runtimes/typescript/` for Node, `runtimes/swift/` for Swift Package Manager). Each runtime must include **`collectors/`** and **`adapters/`** as described in [`runtimes/RUNTIME-TEMPLATE.md`](./runtimes/RUNTIME-TEMPLATE.md). Add new platforms by introducing another `runtimes/<name>/` tree rather than mixing runtimes at the top level.

---

## License

By contributing, you agree that your contributions will be licensed
under the Apache License 2.0.