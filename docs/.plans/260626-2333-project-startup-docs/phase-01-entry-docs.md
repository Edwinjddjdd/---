# Phase 01: 项目入口文档

## Objective

- Create root and docs-level entry points so users and future agents can understand the project without rereading all research notes.

## Scope

- Files/modules this phase may touch:
  - `README.md`
  - `docs/SUMMARY.md`
- Files/modules this phase must not touch:
  - Existing files under `docs/research/`
  - Simulation code or model files

## Preconditions

- Existing research docs remain readable.
- Brainstorm summary exists at `docs/.brainstorms/260626-2333-project-startup/SUMMARY.md`.

## Tasks

1. Context: use `AGENTS.md`, `docs/research/modeling-basis.md`, `docs/research/literature-map.md` and `docs/research/deep-reading/deep-reading-index.md`.
2. Implement: add `README.md` with project purpose, current status, working constraints and next entry points.
3. Implement: add `docs/SUMMARY.md` with project orientation, source map, model target, current risks and next actions.
4. Verify: run file listing and targeted search over added docs.
5. Confirm: docs exist and link to the relevant research sources.

## Acceptance Criteria

- User-visible or system-observable result:
  - A reader can start from `README.md` or `docs/SUMMARY.md` and understand the project state.
- Required changed files:
  - `README.md`
  - `docs/SUMMARY.md`
- Required unchanged behavior:
  - Existing research docs are not modified.

## Verification

- Commands:
  - `rg --files`
  - `rg -n "阶段二|VRS|中俄轴系|LaTeX|docs/research" README.md docs/SUMMARY.md`
- Expected results:
  - Both new files appear.
  - Search returns project orientation, constraints and source links.
- Evidence to record in `SUMMARY.md`:
  - File paths created and command result summary.

## Idempotence and Recovery

- Safe to re-run:
  - Yes, as long as only the two phase files are overwritten/refined.
- Recovery if interrupted:
  - Re-run phase after checking whether either file exists.
- Rollback notes:
  - Delete `README.md` and `docs/SUMMARY.md` if this phase is rejected.

## Exit Criteria

- [x] `README.md` exists.
- [x] `docs/SUMMARY.md` exists.
- [x] Both files use LaTeX for mathematical expressions.
- [x] Existing research docs remain unchanged.
