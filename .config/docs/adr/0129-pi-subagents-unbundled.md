# ADR-0129: Keep pi-subagents unbundled after 0.26.1 added a skill-path hazard

Status: Accepted
Date: 2026-11-23

## Context

The bundler screen refused `@tintinweb/pi-subagents` 0.26.1 because its `reviewedKinds` no longer matched the verdict recorded under ADR-0067. The old verdict approved one `new Worker` hazard: the worker source is an inlined template literal, so relocating it is fine. The release added a second hazard — `workflow/tool-description.ts` resolves the shipped `skills/workflow-authoring/SKILL.md` through `import.meta.url` and reads it at startup to inline the workflow authoring reference into the tool description. The bundler writes to `<pkg>/.pi-bundler/bundle.mjs`, one directory deeper than `src/`, so the relative `../../skills/...` would point outside the package. That would degrade the model-facing description to a broken pointer while still importing successfully — a silent failure, not a crash. No supported external keeps just that module at source: the bundler's externals are per-package, and the package's declared entry is one source tree.

## Decision

Change the verdict from `bundle` to `skip` with both hazard kinds recorded, rather than extending the old approval. No bundle is currently applied (`bundle.mjs --revert` reported every package at source), so the change affects only future postinstall runs.

## Consequences

The bundler screen is clean again and a future pi install cannot silently bundle a broken workflow description. Source import measures 149 ms in this configuration, so the safe choice costs real startup time — accepted in exchange for a working tool description. If upstream makes the skill path robust to relocation, revisit the verdict and re-measure before bundling.
