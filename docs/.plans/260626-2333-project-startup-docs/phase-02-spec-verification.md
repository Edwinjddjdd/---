# Phase 02: 阶段二草案与验证路线

## Objective

- Convert the research conclusions into a stage-two model specification draft and a verification roadmap without implementing code.

## Scope

- Files/modules this phase may touch:
  - `docs/stage-2-model-spec-draft.md`
  - `docs/verification-roadmap.md`
  - Plan progress and execution report files under `docs/.plans/260626-2333-project-startup-docs/`
- Files/modules this phase must not touch:
  - Existing files under `docs/research/`
  - MATLAB, Simulink, Python or generated model files

## Preconditions

- Phase 01 is complete.
- Project entry docs exist.

## Tasks

1. Context: use `docs/research/modeling-basis.md`, `docs/research/data-sources.md`, `docs/research/paper-notes/wayne-johnson-vrs-model.md` and `docs/research/paper-notes/dynamic-inflow-models.md`.
2. Implement: add a stage-two draft with model scope, state vector, module boundaries, VRS detection/correction interface and open items.
3. Implement: add a verification roadmap with source-backed scenarios, acceptance signals and data gaps.
4. Verify: run targeted search for LaTeX syntax, VRS interfaces and pending items.
5. Confirm: no simulation implementation files were introduced.

## Acceptance Criteria

- User-visible or system-observable result:
  - A future implementation plan can use the draft as a starting model specification.
- Required changed files:
  - `docs/stage-2-model-spec-draft.md`
  - `docs/verification-roadmap.md`
  - `docs/.plans/260626-2333-project-startup-docs/EXECUTION-REPORT.md`
- Required unchanged behavior:
  - Existing research docs remain unchanged.
  - No code or model files are created.

## Verification

- Commands:
  - `rg -n "x =|\\\\dot|VRS_Detection|VRS_Correction|验证|待冻结|待补充" docs/stage-2-model-spec-draft.md docs/verification-roadmap.md`
  - `git diff -- README.md docs/SUMMARY.md docs/stage-2-model-spec-draft.md docs/verification-roadmap.md`
- Expected results:
  - Draft docs contain model structure, VRS interfaces, verification scenarios and pending items.
  - Diff only includes planned added documentation files.
- Evidence to record in `SUMMARY.md`:
  - Created file paths and verification command summaries.

## Idempotence and Recovery

- Safe to re-run:
  - Yes, as long as only files in this phase are overwritten/refined.
- Recovery if interrupted:
  - Check which draft file exists, then complete missing sections.
- Rollback notes:
  - Delete the two draft docs and execution report if this phase is rejected.

## Exit Criteria

- [x] `docs/stage-2-model-spec-draft.md` exists.
- [x] `docs/verification-roadmap.md` exists.
- [x] New mathematical notation uses LaTeX.
- [x] VRS detection/correction is specified as an interface, not implemented as code.
- [x] Verification roadmap includes hover, normal descent, VRS entry, recovery and parameter sweep.
